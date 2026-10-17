# A Post is a Markdown file on disk, not a database row.
#
# Git is the version history, the backup and the audit log. Publishing is a
# commit. There is deliberately no admin UI to build, secure or maintain.
class Post
  FRONTMATTER = /\A---\s*\n(?<yaml>.*?)\n---\s*\n(?<body>.*)\z/m
  PERMITTED_KEYS = %w[title slug date description og_image tags draft].freeze
  SLUG = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  class InvalidPost < StandardError; end

  attr_reader :slug, :title, :date, :description, :og_image, :tags, :body_markdown

  def self.from_file(path)
    # Explicit encoding: a container with no locale set defaults to US-ASCII,
    # and a single em dash in a post would then raise on read.
    raw = File.read(path, encoding: "UTF-8")
    match = FRONTMATTER.match(raw)
    raise InvalidPost, "#{path} is missing YAML frontmatter" if match.nil?

    front = YAML.safe_load(match[:yaml], permitted_classes: [ Date, Time ]) || {}
    raise InvalidPost, "#{path} frontmatter must be a list of key: value pairs" unless front.is_a?(Hash)

    unknown = front.keys - PERMITTED_KEYS
    raise InvalidPost, "#{path} has unknown frontmatter keys: #{unknown.join(', ')}" if unknown.any?

    new(front: front, body: match[:body], path: path)
  end

  def initialize(front:, body:, path:)
    @path          = path
    @title         = front.fetch("title") { raise InvalidPost, "#{path} needs a title" }.to_s
    @date          = coerce_date(front.fetch("date") { raise InvalidPost, "#{path} needs a date" })
    @slug          = (front["slug"].presence || slug_from_filename(path)).to_s
    @description   = front["description"].to_s.strip
    @og_image      = StaticSite::SafeUrl.clean(front["og_image"])
    @tags          = Array(front["tags"]).map(&:to_s)
    @draft         = front.fetch("draft", false)
    @body_markdown = body

    unless @slug.match?(SLUG)
      raise InvalidPost, "#{path}: slug #{@slug.inspect} must be lowercase letters, numbers and hyphens only"
    end
  end

  def draft? = !!@draft

  def published? = !draft? && date <= Date.current

  # Rendered once per build, then held in memory.
  def body_html
    @body_html ||= MarkdownRenderer.render(body_markdown)
  end

  def summary
    description.presence || plain_text.truncate(160, separator: " ")
  end

  def plain_text
    @plain_text ||= ActionView::Base.full_sanitizer.sanitize(body_html).squish
  end

  def word_count = plain_text.split.size

  def reading_minutes = [ (word_count / 220.0).ceil, 1 ].max

  def to_param = slug

  private

  def coerce_date(value)
    case value
    when Date then value
    when Time then value.to_date
    else Date.parse(value.to_s)
    end
  rescue ArgumentError
    raise InvalidPost, "#{@path} has an unparseable date: #{value.inspect}"
  end

  # 2026-06-11-misty.md -> "misty"
  def slug_from_filename(path)
    File.basename(path, ".md").sub(/\A\d{4}-\d{2}-\d{2}-/, "")
  end
end
