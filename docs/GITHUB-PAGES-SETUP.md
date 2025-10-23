# GitHub Pages Custom Domain Setup

This guide shows you how to configure your GitHub Pages site to use the custom domain `polarisaistudio.com`.

## Overview

After deploying the Terraform configuration, your DNS will be configured with:
- **A records** (IPv4) pointing `polarisaistudio.com` → GitHub Pages
- **AAAA records** (IPv6) pointing `polarisaistudio.com` → GitHub Pages
- **CNAME record** pointing `www.polarisaistudio.com` → `polarisaistudio.github.io`

You just need to configure GitHub Pages to recognize your custom domain.

## DNS Records Created by Terraform

The following records will be automatically created in Route 53:

### Apex Domain (polarisaistudio.com)
```
Type: A
Name: polarisaistudio.com
Values:
  185.199.108.153
  185.199.109.153
  185.199.110.153
  185.199.111.153
```

### Apex Domain IPv6 (polarisaistudio.com)
```
Type: AAAA
Name: polarisaistudio.com
Values:
  2606:50c0:8000::153
  2606:50c0:8001::153
  2606:50c0:8002::153
  2606:50c0:8003::153
```

### WWW Subdomain
```
Type: CNAME
Name: www.polarisaistudio.com
Value: polarisaistudio.github.io
```

## GitHub Pages Repository Setup

### Step 1: Configure Custom Domain in GitHub Pages

1. Go to your GitHub Pages repository: `https://github.com/polarisaistudio/polarisaistudio.github.io`
2. Click **Settings** (top menu)
3. In the left sidebar, click **Pages**
4. Under **Custom domain**, enter: `polarisaistudio.com`
5. Click **Save**

GitHub will automatically:
- Create a `CNAME` file in your repository
- Check DNS configuration
- Issue an SSL certificate (may take a few minutes)

### Step 2: Enable HTTPS

1. Still on the Pages settings page
2. Wait for DNS check to complete (green checkmark)
3. Check the box: **Enforce HTTPS**
4. Click **Save**

This ensures all traffic uses HTTPS for security.

### Step 3: Verify DNS Configuration

GitHub will perform DNS checks. You should see:

✅ **DNS check successful**
✅ **Domain is properly configured**
✅ **HTTPS certificate issued**

If you see warnings, wait 15-30 minutes for DNS propagation.

## Testing Your Setup

### Test Apex Domain
```bash
# Should return GitHub Pages IPs
dig polarisaistudio.com

# Expected output includes:
# polarisaistudio.com.  300  IN  A  185.199.108.153
# polarisaistudio.com.  300  IN  A  185.199.109.153
# polarisaistudio.com.  300  IN  A  185.199.110.153
# polarisaistudio.com.  300  IN  A  185.199.111.153
```

### Test WWW Subdomain
```bash
# Should return CNAME to GitHub Pages
dig www.polarisaistudio.com

# Expected output includes:
# www.polarisaistudio.com.  300  IN  CNAME  polarisaistudio.github.io
```

### Test in Browser
1. Visit `https://polarisaistudio.com` - should show your GitHub Pages site
2. Visit `https://www.polarisaistudio.com` - should redirect to apex domain
3. Check that HTTPS (padlock icon) is enabled

## Common Issues and Solutions

### "Domain's DNS record could not be retrieved"

**Cause**: DNS records haven't propagated yet

**Solution**:
1. Wait 15-30 minutes for DNS propagation
2. Verify records exist in Route 53 console
3. Try again in GitHub Pages settings

### "HTTPS not available"

**Cause**: GitHub is still issuing the SSL certificate

**Solution**:
1. Wait up to 24 hours for certificate issuance
2. Ensure DNS is properly configured
3. Try removing and re-adding the custom domain

### "Site not loading"

**Cause**: DNS not propagated or GitHub Pages not configured

**Solution**:
1. Check DNS with `dig polarisaistudio.com`
2. Verify CNAME file exists in your repository
3. Check GitHub Pages is enabled in repository settings
4. Clear browser cache

### "Mixed content warnings"

**Cause**: Site has HTTP resources loaded on HTTPS page

**Solution**:
1. Update all resources to use HTTPS
2. Use protocol-relative URLs (`//example.com/image.jpg`)
3. Check browser console for specific resources

## Repository CNAME File

After configuring the custom domain, GitHub creates a `CNAME` file in your repository root:

```
polarisaistudio.com
```

**Important**: Do NOT delete this file. It tells GitHub Pages which domain to serve.

## Advanced Configuration

### Redirect www to Apex (or vice versa)

GitHub Pages automatically handles redirects:
- `www.polarisaistudio.com` → `polarisaistudio.com` (if apex is configured)
- `polarisaistudio.com` → `www.polarisaistudio.com` (if www is configured)

Our setup uses the **apex domain** as primary.

### Email and Web on Same Domain

Your domain now serves both:
- **Web traffic**: GitHub Pages site at `https://polarisaistudio.com`
- **Email**: Forwarding via SES (info@, contact@, support@, admin@)

This works because:
- A/AAAA records handle web traffic (HTTP/HTTPS on port 80/443)
- MX records handle email traffic (SMTP on port 25)

They don't conflict!

## Verification Checklist

After setup, verify:

- [ ] `https://polarisaistudio.com` loads your site
- [ ] `https://www.polarisaistudio.com` redirects to apex
- [ ] HTTPS is enabled (padlock icon in browser)
- [ ] SSL certificate is valid
- [ ] CNAME file exists in repository
- [ ] DNS records visible in Route 53
- [ ] Email forwarding still works (send test email)

## DNS Propagation Time

- **Route 53 to GitHub**: ~5-15 minutes
- **Global DNS propagation**: Up to 48 hours (usually much faster)
- **SSL certificate issuance**: Up to 24 hours

Check propagation status:
```bash
# Check from different DNS servers
dig @8.8.8.8 polarisaistudio.com
dig @1.1.1.1 polarisaistudio.com
```

## Updating GitHub Pages Content

To update your site:

1. Make changes to your repository
2. Commit and push to the branch GitHub Pages uses (usually `main` or `gh-pages`)
3. GitHub automatically rebuilds and deploys
4. Changes appear within 1-2 minutes

## Security Best Practices

✅ **Always use HTTPS** - Enable "Enforce HTTPS" in settings
✅ **Keep CNAME file** - Don't delete it from repository
✅ **Monitor certificate** - GitHub auto-renews, but check periodically
✅ **Use proper CSP headers** - Content Security Policy for added security

## Additional Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Pages Custom Domain Guide](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)
- [GitHub Pages IP Addresses](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#configuring-an-apex-domain)

## Summary

Your configuration:
- **Domain**: polarisaistudio.com
- **GitHub Repo**: polarisaistudio/polarisaistudio.github.io
- **DNS**: Managed by Route 53 via Terraform
- **SSL**: Automatic via GitHub Pages
- **Email**: Separate forwarding via SES

Both web and email work on the same domain without conflicts! 🎉
