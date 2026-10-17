require "nokogiri"

# Reads any public photo RSS/Atom feed (Flickr, Pixelfed, Glass, a blog's photo
# tag, ...) into tmp/sync/photos_feed.json. Images stay on the other site and are
# hot-linked; nothing is downloaded. Set photo_feed_url in config/site.yml.
class FeedPhotoSync
  LIMIT = 60

  Result = Struct.new(:status, :message, keyword_init: true)

  def self.call = new.call

  def call
    url = StaticSite::SafeUrl.clean(Rails.application.config.x.site.photo_feed_url, allow_site_path: false)
    return Result.new(status: :skipped, message: "photo_feed_url is not set") if url.nil?

    doc = Nokogiri::XML(FeedClient.get(url))
    doc.remove_namespaces!
    entries = doc.xpath("//item | //entry").first(LIMIT).filter_map { |node| photo(node) }

    SyncStore.write("photos_feed", entries)
    Result.new(status: :ok, message: "#{entries.size} photos")
  rescue FeedClient::FetchError => e
    Result.new(status: :failed, message: "#{e.message} (kept the previous data)")
  end

  private

  def photo(node)
    image = StaticSite::SafeUrl.clean(image_url(node), allow_site_path: false)
    return nil if image.nil?

    title = text(node, "title")
    {
      "image_url" => image,
      "url"       => StaticSite::SafeUrl.clean(link(node), allow_site_path: false) || image,
      "caption"   => title,
      "alt"       => title.presence || "Photograph",
      "taken_on"  => date(node),
      "sort_name" => image
    }
  end

  # media:content, media:thumbnail, an image enclosure, or the first <img> in the body.
  def image_url(node)
    node.at_xpath("content[starts-with(@type,'image') or @medium='image'][@url]")&.[]("url") ||
      node.at_xpath("enclosure[starts-with(@type,'image')]")&.[]("url") ||
      node.at_xpath("thumbnail[@url]")&.[]("url") ||
      first_image_in(text(node, "description").presence || text(node, "content").presence || text(node, "summary"))
  end

  def first_image_in(html)
    return nil if html.empty?

    Nokogiri::HTML.fragment(html).at_css("img[src]")&.[]("src")
  end

  def link(node)
    node.at_xpath("link[@href]")&.[]("href") || text(node, "link")
  end

  def date(node)
    value = %w[pubDate published updated date].map { |name| text(node, name) }.find(&:present?)
    value && Time.zone.parse(value)&.to_date&.iso8601
  rescue ArgumentError
    nil
  end

  def text(node, name) = node.at_xpath(name)&.text.to_s.strip
end
