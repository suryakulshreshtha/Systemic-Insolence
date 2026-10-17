module ApplicationHelper
  # Delivered as a <meta> tag because GitHub Pages cannot set response headers.
  # Nothing on the site uses inline styles or scripts, so none are allowed.
  CONTENT_SECURITY_POLICY = [
    "default-src 'self'",
    "img-src 'self' data: https:",
    "style-src 'self'",
    "script-src 'self'",
    "font-src 'self'",
    "connect-src 'self'",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'none'"
  ].join("; ").freeze

  def site = Rails.application.config.x.site

  # --- URLs -----------------------------------------------------------------

  # https://host[/base_path], no trailing slash.
  def site_url = "#{site.protocol}://#{site.host}#{site.base_path}"

  # Canonical, social-card, feed and sitemap URLs must be absolute.
  def absolute_url(path)
    path = path.to_s
    return site_url + "/" if path.empty? || path == "/"

    site_url + (path.start_with?("/") ? path : "/#{path}")
  end

  # Turns /media/x.jpg inside feed content into a full address.
  def absolutize_html(html) = StaticSite::UrlRewriter.prefix_html(html.to_s, site_url)

  # "/css/site.css" -> "/css/site.css?v=ab12cd34", so a changed stylesheet is
  # never served stale from a cache.
  def asset_path(path)
    file = Rails.root.join("public", path.delete_prefix("/"))
    return path unless File.file?(file)

    "#{path}?v=#{Digest::SHA256.file(file).hexdigest[0, 8]}"
  end

  # A link taken from a YAML file: javascript: and similar are dropped, web links
  # open safely. Returns nil when the address is not allowed, so callers can skip.
  def external_link_to(label, url, **options)
    clean = StaticSite::SafeUrl.clean(url, allow_mail: true)
    return nil if clean.nil?

    options[:rel] = "noopener noreferrer" if StaticSite::SafeUrl.web?(clean)
    link_to(label, clean, **options)
  end

  def safe_url(url, **options) = StaticSite::SafeUrl.clean(url, **options)

  # An <img> for a URL from content or a sync. Only allowed addresses render, and
  # lazy loading keeps long photo pages light.
  def image_tag_for(url, alt:, **options)
    clean = StaticSite::SafeUrl.clean(url)
    return nil if clean.nil?

    tag.img(src: clean, alt: alt.to_s, loading: "lazy", decoding: "async", **options)
  end

  # --- Text and dates ---------------------------------------------------------

  def long_date(date) = date.to_date.strftime("%-d %B %Y")

  def short_date(date) = date.to_date.strftime("%d %b %Y").upcase

  def iso_date(date) = date.to_date.iso8601

  def reading_time(post) = "#{post.reading_minutes} min read"

  def stars(rating)
    rating = rating.to_i
    return nil unless rating.between?(1, 5)

    ("★" * rating) + ("☆" * (5 - rating))
  end

  # The tagline with an optional highlighted phrase. Everything is escaped.
  def tagline_html
    text = site.tagline.to_s
    phrase = site.tagline_highlight.to_s
    return h(text) if phrase.empty? || !text.include?(phrase)

    before, after = text.split(phrase, 2)
    safe_join([ before, content_tag(:span, phrase, class: "hl"), after ])
  end

  # First paragraph of a Markdown page, rendered. Used for the home page intro.
  def first_paragraph_html(markdown)
    paragraph = markdown.to_s.split(/\n{2,}/).map(&:strip).find { |chunk| chunk.present? && !chunk.start_with?("#") }
    paragraph ? raw(MarkdownRenderer.render(paragraph)) : nil
  end

  # --- Navigation ---------------------------------------------------------------

  def nav_items
    items = SiteSections.available.map { |section| [ section.label, section.path ] }
    items << [ "About", about_path ] if Page.find("about")
    items
  end

  def nav_link(label, path)
    current = current_page?(path)
    link_to(label, path, class: ("is-current" if current), aria: { current: ("page" if current) })
  end

  # --- Structured data ------------------------------------------------------------

  # JSON-LD inside a <script>: escape the characters that could close the tag.
  def json_ld(data) = raw(ERB::Util.json_escape(data.to_json))

  def show_email?
    StaticSite::SafeUrl.clean("mailto:#{site.email}", allow_mail: true).present? && site.email.to_s.include?("@")
  end
end
