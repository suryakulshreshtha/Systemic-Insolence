# How to update your site

Everything on the site is a plain file in this repository. To change the site you
change a file and save ("commit") it. A few minutes later the new version is live.
You never log in to an admin screen and nothing runs on a server.

**Contents**

1. [The short version](#1-the-short-version)
2. [Two ways to edit: in the browser, or on your computer](#2-two-ways-to-edit)
3. [Write a post](#3-write-a-post)
4. [Change pages and site settings](#4-change-pages-and-site-settings)
5. [Add photos and other media](#5-add-photos-and-other-media)
6. [Pull photos from a Google Drive folder](#6-pull-photos-from-a-google-drive-folder)
7. [Books and Goodreads](#7-books-and-goodreads)
8. [Add a project page](#8-add-a-project-page)
9. [Preview on your own computer](#9-preview-on-your-own-computer)
10. [When something goes wrong](#10-when-something-goes-wrong)
11. [Where everything lives](#11-where-everything-lives)

---

## 1. The short version

| I want to...                    | Do this                                                                              |
| ------------------------------- | ------------------------------------------------------------------------------------ |
| Publish a post                  | Add a `.md` file to `content/posts/`                                                 |
| Add a photo                     | Add the image to `public/media/photos/`                                              |
| Add a book                      | Add a few lines to `content/books.yml`                                               |
| Change my name, tagline, links  | Edit `config/site.yml`                                                               |
| Change the About page           | Edit `content/pages/about.md`                                                        |
| Add a project                   | Add a `.yml` file to `content/projects/`                                             |

After any change: **commit to the `main` branch**. Open the **Actions** tab of the
repository and watch "Publish site". A green tick means it is live (usually within
two or three minutes). A red cross means something needs fixing: see
[section 10](#10-when-something-goes-wrong).

The site is also rebuilt automatically about every 6 hours. That is how a post dated
for the future appears on its day, and how new Goodreads books or Drive photos show
up without you doing anything. Two limits from GitHub: scheduled runs can be delayed
when GitHub is busy, and **in a public repository they are switched off after 60 days
with no activity** ([GitHub docs](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)).
If the site has been quiet that long, any commit (or **Actions → Publish site → Run
workflow**) wakes it up again.

---

## 2. Two ways to edit

### A. In the browser (no software needed)

1. Open the repository on github.com.
2. To change a file: click it, click the pencil icon, edit, then **Commit changes**.
3. To add a file: go to the folder, choose **Add file → Create new file** (for text)
   or **Add file → Upload files** (for photos and images), then **Commit changes**.

Files added through the browser can be at most **25 MiB** each
([GitHub's limit](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)).
For photos, resize them first (see section 5).

### B. On your computer

```bash
git clone https://github.com/suryakulshreshtha/Systemic-Insolence.git
cd Systemic-Insolence
# ...add or edit files...
git add -A
git commit -m "Add a post about misty mornings"
git push
```

Use the Git name and email you normally use. This project never changes your Git
identity.

---

## 3. Write a post

Create a file in `content/posts/`. The name is the date, then a short address,
for example `2026-11-02-first-snow.md`:

```markdown
---
title: First snow
date: 2026-11-02
description: One sentence shown in lists and link previews.
tags:
  - weather
---

Write the post here in Markdown. A blank line starts a new paragraph.

## A heading

- a list
- of things

[A link](https://example.org) and an image:

![A description for people who cannot see the picture](/media/posts/first-snow.jpg)
```

Rules:

* **The page address** comes from the file name (`first-snow`), so the post lives at
  `/blog/first-snow/`. To choose another, add `slug: my-address` to the top block.
  Slugs are lowercase letters, numbers and hyphens only.
* **Draft:** add `draft: true` to keep a post unpublished. Remove the line (or set
  `draft: false`) to publish.
* **Schedule:** set `date:` to a future day. It appears on that day, at the next
  automatic rebuild (about every 6 hours) or the next time you push.
* **Images in a post:** put the file in `public/media/posts/` and refer to it as
  `/media/posts/<file name>`.
* **Allowed top-block keys:** `title`, `date`, `slug`, `description`, `og_image`,
  `tags`, `draft`. Anything else stops the build with a clear message (this catches typos).
* Raw HTML inside a post is shown as text, not run. That is deliberate.

Shortcut on your computer: `bin/rails "content:post[First snow]"` creates the file
for you, as a draft.

---

## 4. Change pages and site settings

### Pages

| Page            | File                                  |
| --------------- | ------------------------------------- |
| About           | `content/pages/about.md`              |
| About this site | `content/pages/about-this-site.md`    |
| Now             | `content/pages/now.md.sample` (see below) |

The About page's **first paragraph** is also the short introduction on the home page.

**Turning on the "Now" page:** rename `content/pages/now.md.sample` to
`content/pages/now.md` and replace the text. A "Now" link then appears in the menu
by itself. The same idea applies everywhere: **a section appears only when it has
content**, so nobody ever sees an empty page.

### Site settings: `config/site.yml`

Open it. Every line has a comment. The ones you will change first:

* `name`, `tagline`, `description`: **check these**, they are placeholders.
* `avatar`: put a square image in `public/images/` (about 480 px) and set
  `avatar: "/images/yourfile.jpg"`.
* `social_image`: a 1200 × 630 PNG or JPEG in `public/images/`, used for link
  previews (when you share the site in chat or social posts).
* `elsewhere`: your links on the home page.
* `email`: shows an "Email" link in the footer (leave blank for none).

Leave `host`, `protocol` and `base_path` alone: the publish step fills them in.

---

## 5. Add photos and other media

### The simple way (no accounts)

1. Put the image in **`public/media/photos/`**.
2. Commit. It appears on the Photography section of the home page and on `/photos/`.

That is all. Details:

* **Allowed types:** JPG, PNG, WebP, GIF. (HEIC from an iPhone: export or convert to
  JPG first. SVG is not published, because SVG files can carry scripts.)
* **Date:** start the file name with the date, `2026-10-09-morning-light.jpg`.
  Otherwise the file is ordered by name.
* **Caption:** taken from the rest of the name (`Morning light`). Camera names such
  as `IMG_1234.jpg` give no caption.
* **Numbering:** photos are labelled `FRAME 01`, `02`, ... oldest first, so an old
  photo keeps its number as you add new ones.
* **Size:** the build shrinks every photo to at most 2400 px on the long side and
  makes an 800 px thumbnail for the grid. Your original in the repository is not
  touched. Still, git keeps every version forever, so **resize large photos to
  about 2400 px and under 2 MB before adding them**. The build warns above 8 MB and
  refuses above 25 MB.
* **Privacy:** camera information such as **GPS location** is removed from every
  published photo, in the built site (your original file in the repository still
  has it, so keep the repository public only if you are comfortable with that, or
  strip metadata before uploading).

### Captions, alt text and links: `content/photos.yml`

```yaml
- file: 2026-10-09-morning-light.jpg     # the file name only
  caption: "Morning light on the balcony"
  alt: "Sunlight across a wooden floor"  # for screen readers
  date: 2026-10-09
  link: "https://example.org/where-it-was-taken"   # optional
```

An entry is optional. `bin/rails media:check` (or the automatic check) reports an
entry whose file is missing.

### Removing a photo

Delete the file (and its entry in `photos.yml`). It is gone from the site after the
next publish. (It stays in the repository's history.)

### Other media

| What                  | Where                         | Use it as                       |
| --------------------- | ----------------------------- | ------------------------------- |
| Pictures inside posts | `public/media/posts/`         | `/media/posts/<file>`           |
| Book covers           | `public/media/books/`         | `/media/books/<file>`           |
| Project screenshots   | `public/media/projects/`      | `/media/projects/<file>`        |
| Avatar, share image   | `public/images/`              | `/images/<file>`                |

### A photo feed (optional)

If your photos live on a service with a public RSS/Atom feed, put its address in
`config/site.yml`:

```yaml
photo_feed_url: "https://example.com/yourname/feed.xml"
```

The latest 60 photos are merged into the journal. They are linked from the original
site, not copied.

---

## 6. Pull photos from a Google Drive folder

This lets you drop photos into a Drive folder and have them appear on the site.
It is optional and needs a one-time setup. **I could not test it against Google
from where this was written**, so try it with `STRICT=1` (below) before relying on it.

**1. Share the folder.** In Google Drive, right-click the folder → **Share** →
*General access* → **Anyone with the link**, role **Viewer**. (Viewer is enough.
Never give "Editor": anyone with the link could then change your folder.)

**2. Copy the folder id.** Open the folder. The address looks like
`https://drive.google.com/drive/folders/1AbCdEfGhIjKlMnOpQrStUvWxYz`. The id is the
last part: `1AbCdEfGhIjKlMnOpQrStUvWxYz`.

**3. Create a free API key.** In the [Google Cloud console](https://console.cloud.google.com/):
create (or pick) a project → **APIs & Services → Library** → search **Google Drive API** →
**Enable** → **APIs & Services → Credentials → Create credentials → API key**. Then
edit the key and, under **API restrictions**, choose **Restrict key → Google Drive API**.
Copy the key.

**4. Store the key as a GitHub secret.** In your repository: **Settings → Secrets and
variables → Actions → Secrets tab → New repository secret.** Name it exactly
`GOOGLE_API_KEY`, paste the key, **Add secret**. (The key is never written into the
site or the repository.)

**5. Add the folder id** to `config/site.yml`:

```yaml
drive_photo_folders:
  - "1AbCdEfGhIjKlMnOpQrStUvWxYz"
```

**6. Commit.** On the next publish (or press **Actions → Publish site → Run workflow**)
the photos are downloaded, cleaned and added to the journal.

How it behaves:

* JPG, PNG, WebP and GIF images up to **15 MB** each (and 300 per folder) are taken.
  The file's contents are checked, not just its name.
* Photos are **copied into the site**, so removing the sharing later does not break
  published pages. Photos you delete from the folder disappear from the site on the
  next build.
* The photo's Drive *description* becomes its caption; otherwise the file name does.
  The date comes from the photo's own timestamp, else from upload time.
* If Google is unreachable or the key stops working, the **previous photos stay**.
  The build does not fail.
* To see problems instead of skipping them, run it on your computer with
  `STRICT=1 GOOGLE_API_KEY=... bin/rails sync:drive`.
* Files shared by link only can need an extra "resource key" in some cases
  ([Google's note](https://developers.google.com/drive/api/v3/resource-keys)).
  If an old file does not show up, re-upload it or copy it into the folder.

---

## 7. Books and Goodreads

### By hand: `content/books.yml`

```yaml
currently_reading:
  - title: "Dune"
    author: "Frank Herbert"
    cover: "/media/books/dune.jpg"          # a file in public/media/books/, or https://...
    url: "https://www.goodreads.com/book/show/234225"

read:
  - title: "Another Book"
    author: "Someone Else"
    rating: 4              # 1 to 5
    finished: 2026-09-30   # used for ordering
```

Only `title` is required. The Bookshelf page and home-page cover row appear as soon as
there is at least one book.

### From Goodreads

1. Find your numeric id: open your Goodreads profile; the address is
   `goodreads.com/user/show/12345678-your-name`. The id is `12345678`.
2. Set it in `config/site.yml`: `goodreads_user_id: "12345678"`.
3. Your shelves must be readable without logging in (check your Goodreads privacy settings).

I could not test Goodreads from where this was written, and Goodreads can change or
withdraw its public feeds. If the shelf does not appear, check the **Pull in books and
photos** step in the Actions log, or just use `books.yml`.

Books from Goodreads are added to the ones in `books.yml`; if the same title is in
both, **`books.yml` wins**. If Goodreads is down, the previous list is kept.

---

## 8. Add a project page

Copy `content/projects/example-app.yml.sample` to a name ending in `.yml`, for
example `content/projects/my-app.yml`. Edit it. The page exists at
`/projects/my-app/` and a card appears on the home page. If the file has a
`privacy:` block, a privacy page is created at `/projects/my-app/privacy/`.

Put screenshots in `public/media/projects/` and list them as
`/media/projects/<file>`. Only `http`, `https`, `mailto` and site links are accepted
in project files.

---

## 9. Preview on your own computer

You need Ruby (the version in `.ruby-version`; `rbenv` or `asdf` install it) and
ImageMagick (`brew install imagemagick`).

```bash
bin/setup                      # once: installs the gems
bin/dev                        # live preview at http://localhost:3000 (a draft opens at its own address)
```

To see exactly what will be published:

```bash
RAILS_ENV=production bin/rails static:build    # writes the site into _site/
bin/rails static:serve                          # http://localhost:8080
```

Checks you can run any time:

```bash
bin/rails content:lint     # posts, pages, projects, books, photos
bin/rails media:check      # image types, sizes, missing files
bin/rails test             # automated tests
```

---

## 10. When something goes wrong

Open the repository's **Actions** tab, click the red run, click the failed step.
The message is written to be read by a person. Common ones:

| Message contains                          | Meaning and fix                                                        |
| ----------------------------------------- | ---------------------------------------------------------------------- |
| `frontmatter ... unknown keys`            | A typo in the top block of a post. Allowed keys are in section 3.      |
| `slug ... must be lowercase`              | Use only a-z, 0-9 and hyphens in the slug.                             |
| `duplicate post slug`                     | Two posts have the same address. Change one.                           |
| `broken link(s) or missing file(s)`       | A page points at a file that is not in the repository. The list names the page and the address. |
| `not valid YAML`                          | A space or colon is wrong in a `.yml` file. Compare with the examples. |
| `ImageMagick ... required`                | Only in CI; re-run the job. (It installs ImageMagick itself.)          |
| Pages: `Get Pages site failed`            | Pages is not switched on. See `DOMAIN.md` step 1.                      |

A failed publish **never replaces the live site**: the previous version stays up
until a later build succeeds.

To undo a change, open the file's **History** on GitHub, or run
`git revert <commit>` on your computer, then push.

---

## 11. Where everything lives

```
content/
  posts/*.md              blog posts
  pages/about.md          standing pages
  projects/*.yml          project pages
  books.yml               books
  photos.yml              photo captions/dates (optional)
config/site.yml           your name, tagline, links, data sources
public/
  media/photos/           photographs
  media/posts/            pictures used in posts
  media/books/            book covers
  media/projects/         project screenshots
  images/                 avatar, share image
  css/site.css            the look
  fonts/                  self-hosted fonts (open licence)
.github/workflows/        publishing and checks (you rarely touch these)
```

Do not edit `_site/`, `tmp/` or `public/media/synced/`: they are rebuilt.
