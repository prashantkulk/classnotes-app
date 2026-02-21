# How to Host Your Privacy Policy

Both Apple and Google require a **publicly accessible URL** for your privacy policy.

## Option 1: GitHub Pages (Recommended - Free)

1. The privacy policy HTML is at: `store-listing/privacy-policy.html`

2. Copy it to the root of your repo as `docs/privacy-policy.html`:
   ```bash
   mkdir -p docs
   cp store-listing/privacy-policy.html docs/index.html
   ```

3. Push to GitHub:
   ```bash
   git add docs/
   git commit -m "Add privacy policy for app stores"
   git push
   ```

4. Enable GitHub Pages:
   - Go to: https://github.com/prashantkulk/classnotes-app/settings/pages
   - Source: "Deploy from a branch"
   - Branch: `main`, folder: `/docs`
   - Save

5. Your privacy policy will be at:
   **https://prashantkulk.github.io/classnotes-app/**

6. Use this URL in both App Store Connect and Google Play Console.

## Option 2: Firebase Hosting (Alternative)

```bash
# If you prefer Firebase Hosting:
firebase init hosting  # Set public dir to "store-listing"
firebase deploy --only hosting
# URL: https://classnotes-afe61.web.app/privacy-policy.html
```

## Option 3: Google Sites / Notion / Any web page

Just paste the content of privacy-policy.html into any publicly accessible web page.
