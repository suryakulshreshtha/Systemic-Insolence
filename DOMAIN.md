# Publishing, and pointing a GoDaddy domain at the site

The site is published by GitHub Pages from this repository. Nothing about it needs a
paid server. A custom domain is optional and can be added at any time without
changing any file in the repository.

## Part 1: switch publishing on (once)

1. **Get the files into the repository** (the repository must be public for free
   Pages hosting on a personal account).
2. In the repository open **Settings → Pages**. Under **Build and deployment → Source**,
   choose **GitHub Actions**. (Without this the publish job stops with
   `Get Pages site failed`.)
3. *(Recommended, once)* Pin the gem versions. Open the **Actions** tab → **Make
   Gemfile.lock** → **Run workflow**. When it finishes, open the run, download the
   **Gemfile.lock** file from *Artifacts*, and commit it to the repository root
   (**Add file → Upload files**). This makes every build use exactly the same gem
   versions, and lets Dependabot propose safe updates.
4. Push to `main`. Open **Actions → Publish site**. A green tick means the site is
   live at:

   **https://suryakulshreshtha.github.io/Systemic-Insolence/**

   (The page address uses your GitHub user name and the repository name.)

The first run is also the first time the Rails build is executed anywhere, so if it
fails, the message in the Actions log says exactly what to fix.

## Part 2: use your own domain (GoDaddy)

Replace `example.com` below with your domain. You can do the GitHub part and the
GoDaddy part in either order, but the site may show an error until both are done.

### Which address do you want?

* **`www.example.com`** is the simplest and most robust: one CNAME record.
* **`example.com`** (no www) needs four A records (and optionally four AAAA).
* You can set up both; GitHub redirects between them.

### A. Tell GitHub the domain

1. **Settings → Pages → Custom domain**: type the domain (`www.example.com` or
   `example.com`) and **Save**. GitHub checks the DNS records (step B) and may say
   "DNS check in progress" until they are right.
2. When the check passes, tick **Enforce HTTPS** (it can take a while to become
   available while GitHub creates the certificate).
3. Do **not** add a `CNAME` file to the repository. With publishing from GitHub
   Actions, the domain is set in this settings page only.
4. *(Recommended)* **Verify the domain** so nobody else can claim it:
   your profile photo → **Settings → Pages** (account level) → **Add a domain**, and
   add the TXT record GitHub shows you at GoDaddy in the same way as below.

### B. DNS records at GoDaddy

In GoDaddy: **My Products → your domain → DNS** (or **Manage DNS**) → **DNS Records**.
Remove any default "Parked" A record for `@` and any `www` record that points
somewhere else, and make sure **domain forwarding** is switched off for this domain.

For **`www`**:

| Type  | Name  | Value                          |
| ----- | ----- | ------------------------------ |
| CNAME | `www` | `suryakulshreshtha.github.io`  |

For the **bare domain** (`example.com`):

| Type | Name | Value             |
| ---- | ---- | ----------------- |
| A    | `@`  | `185.199.108.153` |
| A    | `@`  | `185.199.109.153` |
| A    | `@`  | `185.199.110.153` |
| A    | `@`  | `185.199.111.153` |

Optional IPv6 (four `AAAA` records, name `@`):
`2606:50c0:8000::153`, `2606:50c0:8001::153`, `2606:50c0:8002::153`, `2606:50c0:8003::153`.

Do **not** use wildcard records (`*`), which GitHub warns can let others take over
subdomains.

These values come from GitHub's own
[custom domain documentation](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site);
check that page if anything fails, since GitHub is the one who can change them.

### C. Wait, then check

DNS changes can take from minutes up to about 24 hours. Check with
`dig www.example.com +short` or an online DNS checker. When the Pages settings page
shows a green "DNS check successful" and the HTTPS box can be ticked, tick it.

### D. Afterwards

You do not need to edit anything in this repository. The next publish picks up the new
address automatically (it asks GitHub Pages where the site is served from) and uses it
for the sitemap, the feed and link previews.

## Troubleshooting

| Symptom                                   | Likely cause                                                               |
| ----------------------------------------- | -------------------------------------------------------------------------- |
| Pages settings: "DNS check unsuccessful"  | Records not saved yet, still propagating, or an old parked record remains. |
| Browser: certificate warning              | GitHub has not issued the certificate yet; wait and retry, then enforce HTTPS. |
| Site shows without styling                | An old build; re-run **Actions → Publish site → Run workflow**.            |
| `example.com` works but `www` does not    | The `www` CNAME is missing, or points somewhere other than `suryakulshreshtha.github.io`. |
| 404 from GitHub on the custom domain      | The domain is not saved in **Settings → Pages**, or the publish has not finished. |
