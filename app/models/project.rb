# A side-project landing page, described entirely by a YAML file in
# content/projects. Adding a new project is one file, no code.
#
# Files whose name starts with "_" or that do not end in .yml are ignored, so
# content/projects/example-app.yml.sample is a safe template to copy.
class Project
  SLUG = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  attr_reader :slug, :data

  def self.find(slug)
    return nil unless slug.to_s.match?(SLUG)

    path = dir.join("#{slug}.yml")
    return nil unless File.exist?(path)

    new(slug, path)
  end

  def self.all
    Dir.glob(dir.join("*.yml")).sort.filter_map do |path|
      slug = File.basename(path, ".yml")
      new(slug, path) if slug.match?(SLUG)
    end.sort_by { |project| [ project.order, project.name.to_s.downcase ] }
  end

  def self.dir = Rails.application.config.x.content_path.join("projects")

  def initialize(slug, path)
    @slug = slug
    @data = YAML.safe_load(File.read(path, encoding: "UTF-8")) || {}
    raise ArgumentError, "#{path} must be a YAML mapping" unless @data.is_a?(Hash)
  end

  def name        = data["name"].to_s
  def headline    = data["headline"].presence || name
  def subhead     = data["subhead"].to_s
  def description = data["description"].presence || subhead
  def blurb       = data["blurb"].presence || subhead
  def order       = data["order"].to_i
  def features    = Array(data["features"])
  def footer_note = data["footer_note"]

  # Only http(s) links, mailto: and site paths survive; javascript: and friends
  # are dropped.
  def links
    Array(data["links"]).filter_map do |link|
      url = StaticSite::SafeUrl.clean(link["url"], allow_mail: true)
      { "label" => link["label"].to_s, "url" => url } if url && link["label"].present?
    end
  end

  def screenshots
    Array(data["screenshots"]).filter_map do |shot|
      src = StaticSite::SafeUrl.clean(shot["src"])
      { "src" => src, "alt" => shot["alt"].to_s } if src
    end
  end

  def og_image = screenshots.first&.dig("src")

  def privacy_markdown = data["privacy"]

  def privacy_html
    return nil if privacy_markdown.blank?

    MarkdownRenderer.render(privacy_markdown)
  end
end
