require "fileutils"
require "json"

# Pulls photos from PUBLIC ("anyone with the link") Google Drive folders into
# public/media/synced/drive/, listed in tmp/sync/photos_drive.json.
#
# Run by `rake sync:drive` at build time. Needs a free Google API key stored as
# the GitHub secret GOOGLE_API_KEY (see UPDATING.md, section 6). The key is only
# ever sent to googleapis.com and is never written to disk or logs.
#
# Safety:
#   * folder ids come from config/site.yml and must look like Drive ids
#   * only image mime types are listed, and the downloaded bytes must match the
#     image signature for that type (SVG is never accepted)
#   * 15 MB cap per file, 300 files per folder
#   * if any listing fails, nothing is deleted and the old data is kept
class DriveSync
  API = "https://www.googleapis.com/drive/v3/files".freeze
  ID = /\A[A-Za-z0-9_-]{10,100}\z/
  MAX_BYTES = 15 * 1024 * 1024
  MAX_FILES = 300
  FIELDS = "nextPageToken,files(id,name,mimeType,size,description,createdTime,md5Checksum,imageMediaMetadata/time)".freeze

  Result = Struct.new(:status, :message, keyword_init: true)

  def self.call = new.call

  def call
    folders = Array(Rails.application.config.x.site.drive_photo_folders).map { |f| f.to_s.strip }.reject(&:empty?)
    return Result.new(status: :skipped, message: "drive_photo_folders is empty") if folders.empty?

    bad = folders.reject { |id| id.match?(ID) }
    return Result.new(status: :failed, message: "invalid folder id(s) in drive_photo_folders") if bad.any?

    key = ENV["GOOGLE_API_KEY"].to_s.strip
    return Result.new(status: :skipped, message: "GOOGLE_API_KEY is not set") if key.empty?

    listing = folders.flat_map { |folder| list(folder, key).first(MAX_FILES) }.uniq { |file| file["id"] }
    manifest = SyncStore.read("drive_manifest") || {}
    entries = []
    kept = {}

    listing.each do |file|
      entry = ingest(file, manifest, key)
      next if entry.nil?

      entries << entry[:entry]
      kept[file["id"]] = entry[:record]
    end

    # Only reached when every listing succeeded (a failure raises above).
    remove_stale(kept)
    SyncStore.write("drive_manifest", kept)
    SyncStore.write("photos_drive", entries)
    Result.new(status: :ok, message: "#{entries.size} photos")
  rescue FeedClient::FetchError => e
    Result.new(status: :failed, message: "#{e.message} (kept the previous data)")
  end

  def self.media_dir = Rails.root.join("public/media/synced/drive")

  private

  def list(folder, key)
    files = []
    token = nil
    loop do
      params = {
        q: "'#{folder}' in parents and mimeType contains 'image/' and trashed = false",
        fields: FIELDS, pageSize: 100, orderBy: "createdTime desc", key: key
      }
      params[:pageToken] = token if token
      page = FeedClient.get_json(API, params: params)
      files.concat(Array(page["files"]).select { |f| f.is_a?(Hash) && f["id"].to_s.match?(ID) })
      token = page["nextPageToken"]
      break if token.nil? || files.size >= MAX_FILES
    end
    files
  end

  def ingest(file, manifest, key)
    ext = StaticSite::ImageSniffer.extension_for_mime(file["mimeType"])
    return nil if ext.nil?
    return nil if file["size"].to_i > MAX_BYTES

    id = file["id"]
    name = "#{id}#{ext}"
    path = self.class.media_dir.join(name)
    record = { "md5" => file["md5Checksum"].to_s, "file" => name }

    unchanged = manifest.dig(id, "md5") == record["md5"] && record["md5"] != "" && File.file?(path)
    return nil unless unchanged || download(id, ext, path, key) || File.file?(path)

    { record: record, entry: describe(file, name) }
  end

  def download(id, ext, path, key)
    bytes = FeedClient.get("#{API}/#{id}", accept: "*/*", params: { alt: "media", key: key }, max_bytes: MAX_BYTES)
    return false unless StaticSite::ImageSniffer.valid?(bytes, ext)

    FileUtils.mkdir_p(path.dirname)
    temp = "#{path}.tmp"
    File.binwrite(temp, bytes)
    File.rename(temp, path)
    true
  rescue FeedClient::FetchError
    false
  end

  def describe(file, name)
    caption = file["description"].to_s.strip.presence || caption_from(file["name"])
    taken = file.dig("imageMediaMetadata", "time").to_s.sub(/\A(\d{4}):(\d{2}):(\d{2})/, '\1-\2-\3').presence ||
            file["createdTime"].to_s
    {
      "image_url" => "/media/synced/drive/#{name}",
      "caption"   => caption.truncate(200),
      "alt"       => caption.presence || "Photograph",
      "taken_on"  => Time.zone.parse(taken)&.to_date&.iso8601,
      "sort_name" => name
    }
  rescue ArgumentError
    { "image_url" => "/media/synced/drive/#{name}", "caption" => caption.to_s, "alt" => "Photograph", "taken_on" => nil, "sort_name" => name }
  end

  # "morning-light.JPG" -> "Morning light"; camera names (IMG_1234) give "".
  def caption_from(name)
    stem = File.basename(name.to_s, ".*").sub(/\A\d{4}-\d{2}-\d{2}[-_ ]*/, "")
    return "" if stem.match?(/\A(?:img|dsc|dscf|pxl|mvimg|photo|image|screenshot)[-_ ]?\d*\z/i) || stem.match?(/\A\d+\z/)

    words = stem.tr("-_", "  ").squish
    words.empty? ? "" : words.sub(/\A./, &:upcase)
  end

  def remove_stale(kept)
    dir = self.class.media_dir
    return unless dir.directory?

    wanted = kept.values.map { |r| r["file"] }
    Dir.children(dir).each do |child|
      next if wanted.include?(child) || child == ".keep"

      FileUtils.rm_f(dir.join(child))
    end
  end
end
