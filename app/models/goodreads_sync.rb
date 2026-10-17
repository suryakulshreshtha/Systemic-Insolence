require "nokogiri"

# Reads a public Goodreads shelf RSS feed into tmp/sync/bookshelf.json.
# Run by `rake sync:goodreads` at build time. Needs only your numeric Goodreads
# user id (config/site.yml: goodreads_user_id). No login, no API key.
class GoodreadsSync
  FEED = "https://www.goodreads.com/review/list_rss/%<id>s".freeze
  USER_ID = /\A\d{1,12}\z/
  SHELF = /\A[a-z0-9\-]{1,40}\z/
  LIMIT = 200

  Result = Struct.new(:status, :message, keyword_init: true)

  def self.call = new.call

  def call
    site = Rails.application.config.x.site
    id = site.goodreads_user_id.to_s.strip
    return Result.new(status: :skipped, message: "goodreads_user_id is not set") if id.empty?
    return Result.new(status: :failed, message: "goodreads_user_id must be digits only") unless id.match?(USER_ID)

    shelves = (site.goodreads_shelves || {}).to_h.transform_keys(&:to_s)
    data = { "profile_url" => "https://www.goodreads.com/user/show/#{id}" }
    shelves.each do |key, shelf|
      next unless %w[currently_reading read].include?(key) && shelf.to_s.match?(SHELF)

      data[key] = fetch_shelf(id, shelf.to_s)
    end

    SyncStore.write("bookshelf", data)
    Result.new(status: :ok, message: "#{data.slice('currently_reading', 'read').values.sum(&:size)} books")
  rescue FeedClient::FetchError => e
    Result.new(status: :failed, message: "#{e.message} (kept the previous data)")
  end

  private

  def fetch_shelf(id, shelf)
    body = FeedClient.get(format(FEED, id: id), params: { shelf: shelf, per_page: LIMIT })
    # Default Nokogiri options: no network access, no entity expansion.
    doc = Nokogiri::XML(body)
    doc.xpath("//item").first(LIMIT).filter_map { |item| book(item) }
  end

  def book(item)
    title = text(item, "title")
    return nil if title.empty?

    book_id = text(item, "book_id")
    {
      "title"    => title,
      "author"   => text(item, "author_name"),
      "url"      => (book_id.match?(/\A\d+\z/) ? "https://www.goodreads.com/book/show/#{book_id}" : nil),
      "cover"    => cover(item),
      "rating"   => text(item, "user_rating").to_i,
      "finished" => finished(item)
    }
  end

  def cover(item)
    url = text(item, "book_large_image_url").presence || text(item, "book_image_url")
    # Goodreads serves a grey "no cover" image for books without one.
    url.include?("nophoto") ? nil : StaticSite::SafeUrl.clean(url, allow_site_path: false)
  end

  def finished(item)
    value = text(item, "user_read_at")
    value.empty? ? nil : Time.zone.parse(value)&.to_date&.iso8601
  rescue ArgumentError
    nil
  end

  def text(item, name) = item.at_xpath(name)&.text.to_s.strip
end
