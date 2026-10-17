require "commonmarker"
require "uri"

# Markdown to HTML, run at build time and never per visitor.
module MarkdownRenderer
  PARSE_OPTIONS = {
    smart: true              # straight quotes become curly, -- becomes an en dash
  }.freeze

  RENDER_OPTIONS = {
    hardbreaks: false,
    unsafe: false,           # raw HTML in Markdown is escaped, javascript: links dropped
    github_pre_lang: true
  }.freeze

  EXTENSIONS = {
    strikethrough: true,
    table: true,
    autolink: true,
    footnotes: true,
    description_lists: true,
    header_ids: "",          # h2 gets id="the-heading" for deep links
    tasklist: true
  }.freeze

  # The highlighter writes inline style="" colours, which the site's Content
  # Security Policy (style-src 'self') would block. Code blocks are styled by
  # the stylesheet instead.
  PLUGINS = {
    syntax_highlighter: nil
  }.freeze

  def self.render(markdown)
    html = Commonmarker.to_html(
      markdown.to_s,
      options: { parse: PARSE_OPTIONS, render: RENDER_OPTIONS, extension: EXTENSIONS },
      plugins: PLUGINS
    )

    post_process(html).html_safe
  end

  # Two small touches that are easier here than in the Markdown source:
  # external links open in a new tab with rel="noopener noreferrer", and images
  # get lazy loading and async decoding.
  def self.post_process(html)
    fragment = Nokogiri::HTML::DocumentFragment.parse(html)
    own_host = Rails.application.config.x.site.host.to_s.downcase

    fragment.css("a[href^='http']").each do |link|
      next if host_of(link["href"]) == own_host

      link["target"] = "_blank"
      link["rel"] = "noopener noreferrer"
    end

    fragment.css("img").each do |image|
      image["loading"] = "lazy"
      image["decoding"] = "async"
    end

    fragment.to_html
  end
  private_class_method :post_process

  def self.host_of(href)
    URI.parse(href).host.to_s.downcase
  rescue URI::InvalidURIError
    ""
  end
  private_class_method :host_of
end
