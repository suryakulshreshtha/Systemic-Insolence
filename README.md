# Systemic Insolence: a personal site

A small personal site (writing, photographs, books, projects) built with **Ruby on
Rails 8 used as a static-site generator** and published on **GitHub Pages**.
Content is plain files in this repository; publishing is a `git push`.

* **How do I add a post, photo or book?** → [`UPDATING.md`](UPDATING.md)
* **How do I publish it and point my own domain at it?** → [`DOMAIN.md`](DOMAIN.md)
* **What protects it?** → [`SECURITY.md`](SECURITY.md)

## How it works

```
content/ + config/site.yml + public/media/   →   bin/rails static:build   →   _site/   →   GitHub Pages
 (your files)                                     (renders every page)        (plain HTML)   (served to visitors)
```

* `bin/rails static:build` renders each page through the real Rails app and writes it as
  a plain HTML file; images are shrunk and stripped of metadata.
* `.github/workflows/pages.yml` runs that on every push to `main`, and about every 6 hours.
* `.github/workflows/ci.yml` runs tests, a security scan, style checks and a trial build
  on every pull request.

Pages use relative links, so the same build works at
`https://<user>.github.io/<repo>/` and at a custom domain.

## Common commands

```bash
bin/setup                                       # install gems (once)
bin/dev                                         # live preview, http://localhost:3000
RAILS_ENV=production bin/rails static:build     # build the real site into _site/
bin/rails static:serve                          # view _site/ at http://localhost:8080
bin/rails content:lint media:check              # check your files for mistakes
bin/rails sync:all                              # pull Goodreads / photo feed / Drive now
bin/rails test                                  # tests
```

## Requirements

Ruby 3.4 (see `.ruby-version`), Bundler, and ImageMagick (`brew install imagemagick`) for
photo processing. CI installs both itself.

## Licence

The code is yours to license as you wish; no licence file is included yet. Fonts in
`public/fonts/` are under the SIL Open Font Licence 1.1 (texts included).
