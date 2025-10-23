.PHONY: build clean

build:
	GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o bootstrap main.go
	zip -j lambda.zip bootstrap

clean:
	rm -f bootstrap lambda.zip
