require "test_helper"

class SyncTest < ActiveSupport::TestCase
  GOODREADS_XML = <<~XML
    <?xml version="1.0"?>
    <rss version="2.0"><channel>
      <item>
        <title>Dune</title>
        <author_name>Frank Herbert</author_name>
        <book_id>234225</book_id>
        <user_rating>5</user_rating>
        <user_read_at>Mon, 01 Sep 2025 00:00:00 -0700</user_read_at>
        <book_large_image_url>https://images.example.com/dune.jpg</book_large_image_url>
      </item>
      <item>
        <title>Script Injection</title>
        <author_name>Nobody</author_name>
        <book_id>not-a-number</book_id>
        <book_large_image_url>javascript:alert(1)</book_large_image_url>
      </item>
    </channel></rss>
  XML

  PHOTO_FEED = <<~XML
    <?xml version="1.0"?>
    <rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/"><channel>
      <item>
        <title>Harbour</title>
        <link>https://photos.example.com/1</link>
        <pubDate>Tue, 07 Oct 2025 08:00:00 +0000</pubDate>
        <media:content url="https://photos.example.com/1.jpg" medium="image"/>
      </item>
      <item><title>Bad</title><media:content url="javascript:alert(1)" medium="image"/></item>
    </channel></rss>
  XML

  setup do
    @sync_dir = Rails.root.join("tmp/test_sync")
    FileUtils.rm_rf(@sync_dir)
    @original_dir = SyncStore.method(:dir)
    dir = @sync_dir
    SyncStore.define_singleton_method(:dir) { dir }
  end

  teardown do
    SyncStore.define_singleton_method(:dir, @original_dir)
    FileUtils.rm_rf(@sync_dir)
  end

  test "goodreads sync stores safe books and drops unsafe links" do
    site = Rails.application.config.x.site
    previous = [ site.goodreads_user_id, site.goodreads_shelves ]
    site.goodreads_user_id = "12345"
    site.goodreads_shelves = { "read" => "read" }

    with_stubbed(FeedClient, :get, GOODREADS_XML) do
      result = GoodreadsSync.call
      assert_equal :ok, result.status
    end

    books = SyncStore.read("bookshelf")["read"]
    dune = books.find { |book| book["title"] == "Dune" }
    assert_equal "https://www.goodreads.com/book/show/234225", dune["url"]
    assert_equal 5, dune["rating"]
    assert_equal "2025-09-01", dune["finished"]

    injected = books.find { |book| book["title"] == "Script Injection" }
    assert_nil injected["url"]
    assert_nil injected["cover"]
  ensure
    site.goodreads_user_id, site.goodreads_shelves = previous
  end

  test "goodreads sync does nothing without a user id" do
    site = Rails.application.config.x.site
    previous = site.goodreads_user_id
    site.goodreads_user_id = ""
    assert_equal :skipped, GoodreadsSync.call.status
  ensure
    site.goodreads_user_id = previous
  end

  test "a failed sync keeps the previous data" do
    SyncStore.write("bookshelf", { "read" => [ { "title" => "Kept" } ] })
    site = Rails.application.config.x.site
    previous = [ site.goodreads_user_id, site.goodreads_shelves ]
    site.goodreads_user_id = "12345"
    site.goodreads_shelves = { "read" => "read" }

    failing = ->(*_args, **_kwargs) { raise FeedClient::FetchError, "boom" }
    with_stubbed(FeedClient, :get, failing) do
      assert_equal :failed, GoodreadsSync.call.status
    end

    assert_equal "Kept", SyncStore.read("bookshelf")["read"].first["title"]
  ensure
    site.goodreads_user_id, site.goodreads_shelves = previous
  end

  test "photo feed sync keeps only safe image addresses" do
    site = Rails.application.config.x.site
    previous = site.photo_feed_url
    site.photo_feed_url = "https://photos.example.com/feed.xml"

    with_stubbed(FeedClient, :get, PHOTO_FEED) do
      assert_equal :ok, FeedPhotoSync.call.status
    end

    photos = SyncStore.read("photos_feed")
    assert_equal [ "https://photos.example.com/1.jpg" ], photos.map { |photo| photo["image_url"] }
    assert_equal "Harbour", photos.first["caption"]
    assert_equal "2025-10-07", photos.first["taken_on"]
  ensure
    site.photo_feed_url = previous
  end

  test "drive sync refuses bad folder ids and missing keys" do
    site = Rails.application.config.x.site
    previous = site.drive_photo_folders
    site.drive_photo_folders = [ "../../etc" ]
    assert_equal :failed, DriveSync.call.status

    site.drive_photo_folders = [ "1AbCdEfGhIjKlMnOpQrStUvWxYz" ]
    previous_key = ENV.delete("GOOGLE_API_KEY")
    assert_equal :skipped, DriveSync.call.status
  ensure
    site.drive_photo_folders = previous
    ENV["GOOGLE_API_KEY"] = previous_key if previous_key
  end
end
