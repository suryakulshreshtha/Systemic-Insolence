# Security notes

This is what protects the site and what you still need to do yourself.

## Why the attack surface is small

The published site is **plain HTML, CSS, a tiny script and images** on GitHub Pages.
There is no server code, database, login, form, cookie or user input. The Rails
application runs only inside the build, on GitHub's machines, and is never exposed to
visitors. A whole class of web attacks (SQL injection, session theft, CSRF, server
takeover) has nothing to attack.

## What the build enforces

* **Content Security Policy** on every page (a `<meta>` tag, since GitHub Pages cannot
  set headers): scripts and styles only from the site itself, no inline scripts or
  styles, no plugins, no form submissions, images from the site or HTTPS.
* **Only one script**, `js/theme.js` (remembers dark/light). No analytics, no
  third-party fonts, scripts or trackers. Fonts are self-hosted (SIL Open Font
  Licence texts are in `public/fonts/`).
* **Markdown cannot run code:** raw HTML in posts is shown as text and `javascript:`
  links are dropped.
* **Links from data files** (`books.yml`, `photos.yml`, projects, feeds) are accepted
  only if they are `http(s)`, `mailto` (projects) or site paths.
* **Images are verified by content**, not file name; SVG is never accepted from
  outside sources. Photos have **EXIF metadata, including GPS location, removed**
  in the published copy.
* **Path safety:** slugs and file names cannot contain `..` or `/`.
* **External data (Goodreads, Drive, feeds):** short timeouts, size limits, nothing
  is executed, secrets are never printed (URLs are logged without query strings), and a
  failure keeps the previous data.
* **Workflow permissions** are the minimum: read the code, publish Pages. The Google key is
  a repository secret, restricted to the Drive API, and never part of the site.
* **Dependabot** proposes updates for gems and GitHub Actions weekly; CI runs
  Brakeman (Rails security scanner) and the tests on every change.

## What you should do

1. **Turn on two-factor authentication** for your GitHub account. This is the single most
   important protection: whoever can push to `main` controls the site.
2. In **Settings → Branches**, consider a rule for `main` (require pull requests, or
   at least block force-pushes).
3. Keep the repository **public only with content you are happy to publish**: even
   unlisted draft posts and original photo files (with their location data) are
   visible in a public repository. Strip location from photos before adding them if
   that matters; the *published* copies are stripped, the repository copies are not.
4. Merge Dependabot pull requests (after CI is green).
5. Never put keys or passwords in any file. Use **Settings → Secrets and variables → Actions**.
6. Optional hardening: pin third-party Actions to a full commit hash. The workflows use
   GitHub's own and Ruby's official actions by major version, which is the normal trade-off
   between convenience and strictness.

## Known limits

* A `<meta>` CSP cannot set `frame-ancestors` (clickjacking protection) and GitHub Pages
  sends no custom headers. Putting the domain behind a CDN such as Cloudflare would let
  you add real headers; it is not needed for a static personal site.
* GitHub Pages is a public service: anything in the published site is public.

## Reporting a problem

If you find a security problem in this project, contact the owner directly.
