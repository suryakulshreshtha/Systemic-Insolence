require "test_helper"

class CollectionsTest < ActiveSupport::TestCase
  test "photo captions and dates come from the file name" do
    assert_equal "Morning light", PhotoJournal.send(:caption_from_filename, "2026-10-09-morning-light.jpg")
    assert_equal "", PhotoJournal.send(:caption_from_filename, "IMG_1234.jpg")
    assert_equal Date.new(2026, 10, 9), PhotoJournal.send(:date_from_filename, "2026-10-09-x.jpg")
    assert_nil PhotoJournal.send(:date_from_filename, "x.jpg")
  end

  test "books.yml entries win over synced duplicates and unsafe links are dropped" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "books.yml"), <<~YAML)
        read:
          - {title: "Dune", author: "Frank Herbert", rating: 4, url: "javascript:alert(1)"}
      YAML
      with_content_path(dir) do
        with_stubbed(SyncStore, :read, { "read" => [ { "title" => "dune", "author" => "Dup" }, { "title" => "Other" } ] }) do
          read = Bookshelf.read
          assert_equal [ "Dune", "Other" ], read.map { |book| book["title"] }.sort
          assert_nil read.find { |book| book["title"] == "Dune" }["url"]
        end
      end
    end
  end

  test "post slugs must be web safe" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "2026-01-01-bad.md")
      File.write(path, "---\ntitle: Bad\ndate: 2026-01-01\nslug: \"../evil\"\n---\nx")
      assert_raises(Post::InvalidPost) { Post.from_file(path) }
    end
  end

  test "pages and projects reject path tricks" do
    assert_nil Page.find("../config/site")
    assert_nil Project.find("../../etc/passwd")
  end
end
