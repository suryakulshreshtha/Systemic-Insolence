# A standing page (/now, /about, /about-this-site) backed by a Markdown file in
# content/pages. Same idea as Post, minus dates and ordering.
class Page
  FRONTMATTER = /\A---\s*\n(?<yaml>.*?)\n---\s*\n(?<body>.*)\z/m
  SLUG = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  attr_reader :slug, :title, :description, :updated_on, :body_markdown

  def self.find(slug)
    return nil unless slug.to_s.match?(SLUG)

    path = Rails.application.config.x.content_path.join("pages", "#{slug}.md")
    return nil unless File.exist?(path)

    new(path)
  end

  def initialize(path)
    raw = File.read(path, encoding: "UTF-8")
    match = FRONTMATTER.match(raw)
    front = match ? (YAML.safe_load(match[:yaml], permitted_classes: [ Date ]) || {}) : {}

    @slug          = File.basename(path, ".md")
    @title         = front["title"].presence || @slug.titleize
    @description   = front["description"].to_s
    @updated_on    = front["updated_on"].presence
    @body_markdown = match ? match[:body] : raw
  end

  def body_html
    @body_html ||= MarkdownRenderer.render(body_markdown)
  end
end
