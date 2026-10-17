# Books, from two places, merged:
#
#   1. content/books.yml          (edit by hand: no accounts needed)
#   2. a Goodreads shelf          (rake sync:goodreads, run at build time)
#
# Entries in books.yml win; a synced book is only added when its title is not
# already listed.
class Bookshelf
  class << self
    def currently_reading = merged("currently_reading")

    def read
      merged("read").sort_by.with_index { |book, index| [ book["finished"].to_s, -index ] }.reverse
    end

    def any? = currently_reading.any? || read.any?

    # The cover row on the home page: what you are reading, then what you read last.
    def for_home(limit) = (currently_reading + read).first(limit.to_i)

    def profile_url = StaticSite::SafeUrl.clean(synced["profile_url"], allow_site_path: false)

    private

    def merged(shelf)
      own = Array(file_data[shelf]).filter_map { |row| normalise(row) }
      known = own.map { |book| book["title"].downcase }
      from_feed = Array(synced[shelf]).filter_map { |row| normalise(row) }
                                      .reject { |book| known.include?(book["title"].downcase) }
      own + from_feed
    end

    def normalise(row)
      return nil unless row.is_a?(Hash)

      title = row["title"].to_s.strip
      return nil if title.empty?

      rating = row["rating"].to_i
      {
        "title"    => title,
        "author"   => row["author"].to_s.strip,
        "url"      => StaticSite::SafeUrl.clean(row["url"], allow_site_path: false),
        "cover"    => StaticSite::SafeUrl.clean(row["cover"]),
        "rating"   => rating.between?(1, 5) ? rating : 0,
        "finished" => (row["finished"] || row["read_on"]).to_s.presence
      }
    end

    def file_data
      file = Rails.application.config.x.content_path.join("books.yml")
      return {} unless File.exist?(file)

      data = YAML.safe_load(File.read(file, encoding: "UTF-8"), permitted_classes: [ Date ]) || {}
      data.is_a?(Hash) ? data : {}
    end

    def synced = SyncStore.read("bookshelf") || {}
  end
end
