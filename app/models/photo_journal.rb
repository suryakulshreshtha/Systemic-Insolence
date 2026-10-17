# The photo journal: every photo on the site, from three places, newest first.
#
#   1. Files you add to the repository: public/media/photos/ (+ content/photos.yml
#      for captions, dates and links). This is the main, no-accounts-needed way.
#   2. A photo RSS/Atom feed          (rake sync:feed_photos, run at build time)
#   3. A public Google Drive folder   (rake sync:drive,       run at build time)
#
# Frames are numbered oldest first, so Frame 01 stays Frame 01 as you add more.
class PhotoJournal
  MEDIA_PATH = "/media/photos".freeze
  EXTENSIONS = %w[.jpg .jpeg .png .webp .gif].freeze
  DATE_PREFIX = /\A(?<date>\d{4}-\d{2}-\d{2})[-_ ]*/

  class << self
    def all
      entries = repo_entries + synced_entries
      ordered = entries.sort_by { |entry| [ entry["taken_on"].to_s, entry["sort_name"].to_s ] }.reverse
      total = ordered.size
      ordered.each_with_index.map { |entry, index| entry.merge("frame" => format("%02d", total - index)) }
    end

    def recent(limit) = all.first(limit.to_i)

    def any? = all.any?

    # Entries described in content/photos.yml that point at a missing file.
    def missing_files
      metadata.keys.reject { |file| File.file?(media_dir.join(file)) }
    end

    def media_dir = Rails.root.join("public/media/photos")

    private

    def repo_entries
      meta = metadata
      Dir.glob(media_dir.join("*")).sort.filter_map do |path|
        next unless File.file?(path)
        next unless EXTENSIONS.include?(File.extname(path).downcase)

        file = File.basename(path)
        info = meta.fetch(file, {})
        date = parse_date(info["date"]) || date_from_filename(file)
        caption = info["caption"].presence || caption_from_filename(file)
        url_path = "#{MEDIA_PATH}/#{ERB::Util.url_encode(file)}"

        {
          "image_url" => url_path,
          "thumb_url" => thumb_for(url_path),
          "url"       => StaticSite::SafeUrl.clean(info["link"]) || url_path,
          "caption"   => caption.to_s,
          "alt"       => info["alt"].presence || caption.presence || "Photograph",
          "taken_on"  => date&.iso8601,
          "sort_name" => file
        }
      end
    end

    # Photos pulled in by `rake sync:*`. Entries are re-validated here because
    # they come from outside the repository.
    def synced_entries
      %w[photos_feed photos_drive].flat_map do |name|
        Array(SyncStore.read(name)).filter_map do |entry|
          next unless entry.is_a?(Hash)

          image = StaticSite::SafeUrl.clean(entry["image_url"])
          next if image.nil?

          {
            "image_url" => image,
            "thumb_url" => thumb_for(image),
            "url"       => StaticSite::SafeUrl.clean(entry["url"]) || image,
            "caption"   => entry["caption"].to_s,
            "alt"       => entry["alt"].presence || entry["caption"].presence || "Photograph",
            "taken_on"  => entry["taken_on"].presence,
            "sort_name" => entry["sort_name"].to_s
          }
        end
      end
    end

    def metadata
      file = Rails.application.config.x.content_path.join("photos.yml")
      return {} unless File.exist?(file)

      rows = YAML.safe_load(File.read(file, encoding: "UTF-8"), permitted_classes: [ Date ]) || []
      Array(rows).each_with_object({}) do |row, memo|
        next unless row.is_a?(Hash) && row["file"].present?

        # A bare file name only: no folders, no "..", so it can never leave
        # public/media/photos.
        name = File.basename(row["file"].to_s)
        memo[name] = row
      end
    end

    # A small thumbnail exists only in the built site, and only for files the
    # image processor handles. Elsewhere (the preview server, remote photos) the
    # full image is used.
    def thumb_for(url_path)
      return nil unless Rails.application.config.x.thumbnails == true
      return nil unless url_path.start_with?("/media/")
      return nil unless StaticSite::ImageProcessor::PROCESSABLE.include?(File.extname(url_path).downcase)

      url_path.sub(%r{\A/media/}, "/media/thumbs/")
    end

    def parse_date(value)
      return nil if value.blank?

      value.respond_to?(:iso8601) ? value.to_date : Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def date_from_filename(file)
      match = DATE_PREFIX.match(file)
      match && parse_date(match[:date])
    end

    # 2026-10-09-morning-light.jpg -> "Morning light". Camera names (IMG_1234)
    # carry no meaning, so they give an empty caption.
    def caption_from_filename(file)
      stem = File.basename(file, ".*").sub(DATE_PREFIX, "")
      return "" if stem.match?(/\A(?:img|dsc|dscf|pxl|mvimg|photo|image|screenshot)[-_ ]?\d*\z/i) || stem.match?(/\A\d+\z/)

      words = stem.tr("-_", "  ").squish
      words.empty? ? "" : words.sub(/\A./, &:upcase)
    end
  end
end
