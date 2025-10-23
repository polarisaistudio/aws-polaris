package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/mail"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/sesv2"
	sestypes "github.com/aws/aws-sdk-go-v2/service/sesv2/types"
)

type Config struct {
	ForwardMapping  map[string]string
	CatchAllForward string
	FromEmail       string
	DomainName      string
	S3Bucket        string
	S3Prefix        string
	PreserveReplyTo bool
}

var (
	s3Client  *s3.Client
	sesClient *sesv2.Client
	appConfig Config
)

func init() {
	ctx := context.Background()
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Fatalf("unable to load SDK config: %v", err)
	}

	s3Client = s3.NewFromConfig(cfg)
	sesClient = sesv2.NewFromConfig(cfg)

	forwardMappingJSON := os.Getenv("FORWARD_MAPPING")
	if forwardMappingJSON == "" {
		log.Fatal("FORWARD_MAPPING environment variable is required")
	}

	if err := json.Unmarshal([]byte(forwardMappingJSON), &appConfig.ForwardMapping); err != nil {
		log.Fatalf("failed to parse FORWARD_MAPPING: %v", err)
	}

	appConfig.CatchAllForward = os.Getenv("CATCH_ALL_FORWARD")
	appConfig.FromEmail = os.Getenv("FROM_EMAIL")
	appConfig.DomainName = os.Getenv("DOMAIN_NAME")
	appConfig.S3Bucket = os.Getenv("S3_BUCKET")
	appConfig.S3Prefix = os.Getenv("S3_PREFIX")

	preserveReplyTo := os.Getenv("PRESERVE_REPLY_TO")
	appConfig.PreserveReplyTo = preserveReplyTo == "true"

	if appConfig.FromEmail == "" {
		appConfig.FromEmail = fmt.Sprintf("noreply@%s", appConfig.DomainName)
	}

	if appConfig.S3Prefix == "" {
		appConfig.S3Prefix = "emails/"
	}

	if appConfig.S3Bucket == "" {
		log.Fatal("S3_BUCKET environment variable is required")
	}

	log.Printf("Configuration loaded - PreserveReplyTo: %v", appConfig.PreserveReplyTo)
}

func handler(ctx context.Context, event events.SimpleEmailEvent) error {
	for _, record := range event.Records {
		if err := processRecord(ctx, record); err != nil {
			log.Printf("Error processing record: %v", err)
			return err
		}
	}
	return nil
}

func processRecord(ctx context.Context, record events.SimpleEmailRecord) error {
	sesNotification := record.SES

	log.Printf("Processing email - MessageID: %s", sesNotification.Mail.MessageID)
	log.Printf("From: %s", sesNotification.Mail.Source)
	log.Printf("To: %v", sesNotification.Mail.Destination)

	bucket := appConfig.S3Bucket
	key := appConfig.S3Prefix + sesNotification.Mail.MessageID

	log.Printf("Downloading email from s3://%s/%s", bucket, key)

	emailContent, err := downloadEmail(ctx, bucket, key)
	if err != nil {
		return fmt.Errorf("failed to download email: %w", err)
	}

	recipients := determineRecipients(sesNotification.Mail.Destination)
	if len(recipients) == 0 {
		log.Printf("No matching recipients found, skipping email")
		return nil
	}

	for _, recipient := range recipients {
		if err := forwardEmail(ctx, sesNotification, emailContent, recipient); err != nil {
			log.Printf("Failed to forward to %s: %v", recipient, err)
		} else {
			log.Printf("Successfully forwarded email to %s", recipient)
		}
	}

	return nil
}

func downloadEmail(ctx context.Context, bucket, key string) ([]byte, error) {
	result, err := s3Client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: &bucket,
		Key:    &key,
	})
	if err != nil {
		return nil, err
	}
	defer result.Body.Close()

	return io.ReadAll(result.Body)
}

func determineRecipients(destinations []string) []string {
	var recipients []string
	seenRecipients := make(map[string]bool)

	for _, dest := range destinations {
		dest = strings.ToLower(dest)
		localPart := extractLocalPart(dest)

		if forwardTo, ok := appConfig.ForwardMapping[localPart]; ok {
			if !seenRecipients[forwardTo] {
				recipients = append(recipients, forwardTo)
				seenRecipients[forwardTo] = true
			}
		} else if appConfig.CatchAllForward != "" {
			if !seenRecipients[appConfig.CatchAllForward] {
				recipients = append(recipients, appConfig.CatchAllForward)
				seenRecipients[appConfig.CatchAllForward] = true
			}
		}
	}

	return recipients
}

func extractLocalPart(email string) string {
	parts := strings.Split(email, "@")
	if len(parts) > 0 {
		return parts[0]
	}
	return email
}

func forwardEmail(ctx context.Context, sesNotification events.SimpleEmailService, emailContent []byte, recipient string) error {
	rawEmail := prepareForwardedEmail(sesNotification, emailContent, recipient)

	_, err := sesClient.SendEmail(ctx, &sesv2.SendEmailInput{
		Content: &sestypes.EmailContent{
			Raw: &sestypes.RawMessage{
				Data: rawEmail,
			},
		},
	})

	return err
}

func prepareForwardedEmail(sesNotification events.SimpleEmailService, emailContent []byte, recipient string) []byte {
	originalFrom := sesNotification.Mail.Source
	originalTo := strings.Join(sesNotification.Mail.Destination, ", ")

	msg, err := mail.ReadMessage(bytes.NewReader(emailContent))
	if err != nil {
		log.Printf("Warning: Failed to parse email: %v, forwarding as-is", err)
		return emailContent
	}

	log.Printf("Successfully parsed email")

	bodyBytes, err := io.ReadAll(msg.Body)
	if err != nil {
		log.Printf("Warning: Failed to read body: %v", err)
		return emailContent
	}

	body := string(bodyBytes)
	log.Printf("Original body length: %d bytes", len(body))

	senderFooter := fmt.Sprintf("\n\n---\nForwarded from: %s\nOriginal to: %s", originalFrom, originalTo)

	modifiedBody := body

	lastClosingBoundary := strings.LastIndex(body, "\n--")
	if lastClosingBoundary != -1 {
		afterNewline := lastClosingBoundary + 1
		nextNewline := strings.Index(body[afterNewline:], "\n")
		var boundaryEnd int
		if nextNewline == -1 {
			boundaryEnd = len(body)
		} else {
			boundaryEnd = afterNewline + nextNewline
		}

		boundaryLine := body[afterNewline:boundaryEnd]
		if strings.HasSuffix(strings.TrimSpace(boundaryLine), "--") {
			log.Printf("Found closing MIME boundary at position %d: %s", lastClosingBoundary, boundaryLine)
			modifiedBody = body[:lastClosingBoundary] + senderFooter + "\n" + body[lastClosingBoundary:]
		}
	}

	if !strings.Contains(modifiedBody, senderFooter) {
		lastClosingBoundary := strings.LastIndex(body, "\r\n--")
		if lastClosingBoundary != -1 {
			afterCRLF := lastClosingBoundary + 2
			nextCRLF := strings.Index(body[afterCRLF:], "\r\n")
			var boundaryEnd int
			if nextCRLF == -1 {
				boundaryEnd = len(body)
			} else {
				boundaryEnd = afterCRLF + nextCRLF
			}

			boundaryLine := body[afterCRLF:boundaryEnd]
			if strings.HasSuffix(strings.TrimSpace(boundaryLine), "--") {
				log.Printf("Found closing MIME boundary (CRLF) at position %d: %s", lastClosingBoundary, boundaryLine)
				modifiedBody = body[:lastClosingBoundary] + "\r\n" + senderFooter + body[lastClosingBoundary:]
			}
		}
	}

	if !strings.Contains(modifiedBody, senderFooter) {
		log.Printf("No closing MIME boundary found, appending footer to end")
		modifiedBody = body + senderFooter
	}

	log.Printf("Modified body length: %d bytes", len(modifiedBody))

	var headers bytes.Buffer

	headersToSkip := map[string]bool{
		"return-path":            true,
		"dkim-signature":         true,
		"received":               true,
		"date":                   true,
		"authentication-results": true,
		"reply-to":               true,
		"from":                   true,
		"to":                     true,
		"content-length":         true,
	}

	for k, vals := range msg.Header {
		lowerK := strings.ToLower(k)
		if headersToSkip[lowerK] {
			log.Printf("Skipping header: %s", k)
			continue
		}
		for _, v := range vals {
			headers.WriteString(fmt.Sprintf("%s: %s\r\n", k, v))
		}
	}

	headers.WriteString(fmt.Sprintf("From: %s\r\n", appConfig.FromEmail))
	headers.WriteString(fmt.Sprintf("To: %s\r\n", recipient))
	headers.WriteString(fmt.Sprintf("X-Original-From: %s\r\n", originalFrom))
	headers.WriteString(fmt.Sprintf("X-Original-To: %s\r\n", originalTo))
	headers.WriteString(fmt.Sprintf("X-Forwarded-By: AWS-SES-Forwarder\r\n"))
	headers.WriteString(fmt.Sprintf("X-Forwarded-For: %s\r\n", originalTo))

	if appConfig.PreserveReplyTo {
		headers.WriteString(fmt.Sprintf("Reply-To: %s\r\n", originalFrom))
		log.Printf("Added Reply-To: %s", originalFrom)
	} else {
		log.Printf("Skipping Reply-To (SES sandbox mode)")
	}

	var result bytes.Buffer
	result.Write(headers.Bytes())
	result.WriteString("\r\n")
	result.WriteString(modifiedBody)

	log.Printf("Email prepared - total: %d bytes", result.Len())
	return result.Bytes()
}

func main() {
	lambda.Start(handler)
}
