# Pure-Ruby tests: no Rails needed, so they also run with plain `ruby`.
require "minitest/autorun" unless defined?(Rails)
require "tmpdir"
require "fileutils"
$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "static_site/url_rewriter"
require "static_site/link_checker"
require "static_site/safe_url"
require "static_site/image_sniffer"
require "static_site/image_processor"

class UrlRewriterTest < Minitest::Test
  R = StaticSite::UrlRewriter

  def test_root_page_uses_dot_slash
    out = R.relativize_html(%(<a href="/blog">x</a>), depth: 0)
    assert_equal %(<a href="./blog/">x</a>), out
  end

  def test_nested_page_climbs_to_the_root
    out = R.relativize_html(%(<link href="/css/site.css"><a href="/blog/misty">m</a>), depth: 2)
    assert_includes out, %(href="../../css/site.css")
    assert_includes out, %(href="../../blog/misty/")
  end

  def test_home_link_from_a_nested_page
    assert_equal %(<a href="../../">h</a>), R.relativize_html(%(<a href="/">h</a>), depth: 2)
  end

  def test_files_do_not_get_a_trailing_slash
    assert_equal %(<a href="../feed.xml">f</a>), R.relativize_html(%(<a href="/feed.xml">f</a>), depth: 1)
  end

  def test_fragments_and_queries_survive
    out = R.relativize_html(%(<a href="/blog/x#top">t</a><link href="/css/site.css?v=ab12">), depth: 1)
    assert_includes out, %(href="../blog/x/#top")
    assert_includes out, %(href="../css/site.css?v=ab12")
  end

  def test_external_and_protocol_relative_urls_are_untouched
    html = %(<a href="https://example.com/x">a</a><a href="//cdn.example/x">b</a><a href="mailto:a@b.c">c</a><a href="#top">d</a>)
    assert_equal html, R.relativize_html(html, depth: 1)
  end

  def test_single_quoted_attributes
    assert_equal %(<img src='../a.png'>), R.relativize_html(%(<img src='/a.png'>), depth: 1)
  end

  def test_prefix_html_for_base_path_and_feeds
    assert_equal %(<a href="/repo/blog/x">x</a>), R.prefix_html(%(<a href="/blog/x">x</a>), "/repo")
    assert_equal %(<img src="https://e.com/m/a.jpg">), R.prefix_html(%(<img src="/m/a.jpg">), "https://e.com")
    assert_equal %(<a href="/x">x</a>), R.prefix_html(%(<a href="/x">x</a>), "")
  end
end

class LinkCheckerTest < Minitest::Test
  def with_site
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "blog/hello"))
      FileUtils.mkdir_p(File.join(dir, "css"))
      File.write(File.join(dir, "css/site.css"), "")
      File.write(File.join(dir, "blog/hello/index.html"), "<p>hi</p>")
      yield dir
    end
  end

  def test_valid_site_has_no_broken_links
    with_site do |dir|
      File.write(File.join(dir, "index.html"),
                 %(<link href="./css/site.css"><a href="./blog/hello/">h</a><a href="https://x.y">e</a><a href="#a">a</a>))
      assert_empty StaticSite::LinkChecker.new(dir).broken_links
    end
  end

  def test_reports_missing_page_and_asset
    with_site do |dir|
      File.write(File.join(dir, "index.html"), %(<a href="./nope/">n</a><img src="./media/missing.jpg">))
      urls = StaticSite::LinkChecker.new(dir).broken_links.map(&:url)
      assert_equal ["./nope/", "./media/missing.jpg"], urls
    end
  end

  def test_nested_relative_links_resolve_from_the_page_directory
    with_site do |dir|
      File.write(File.join(dir, "blog/hello/index.html"), %(<link href="../../css/site.css"><a href="../../">home</a>))
      File.write(File.join(dir, "index.html"), "")
      assert_empty StaticSite::LinkChecker.new(dir).broken_links
    end
  end

  def test_links_escaping_the_site_root_are_broken
    with_site do |dir|
      File.write(File.join(dir, "index.html"), %(<a href="../../etc/passwd">x</a>))
      refute_empty StaticSite::LinkChecker.new(dir).broken_links
    end
  end
end

class SafeUrlTest < Minitest::Test
  S = StaticSite::SafeUrl

  def test_allows_web_and_site_paths
    assert_equal "https://example.com/a?b=1", S.clean("https://example.com/a?b=1")
    assert_equal "/media/x.jpg", S.clean("/media/x.jpg")
  end

  def test_blocks_script_and_data_schemes
    ["javascript:alert(1)", "JaVaScRiPt:alert(1)", "data:text/html;base64,AAAA", "vbscript:x", "file:///etc/passwd",
     "//evil.example/x", "  ", nil, "https://exa mple.com", %(https://a.com/"onmouseover="x)].each do |bad|
      assert_nil S.clean(bad), "expected #{bad.inspect} to be rejected"
    end
  end

  def test_mail_only_when_allowed
    assert_nil S.clean("mailto:a@b.co")
    assert_equal "mailto:a@b.co", S.clean("mailto:a@b.co", allow_mail: true)
  end

  def test_web_predicate
    assert S.web?("http://a.example")
    refute S.web?("/local")
  end
end

class ImageSnifferTest < Minitest::Test
  I = StaticSite::ImageSniffer

  def test_accepts_real_signatures
    assert I.valid?("\xFF\xD8\xFF\xE0rest".b, ".jpg")
    assert I.valid?("\xFF\xD8\xFF\xE0rest".b, ".jpeg")
    assert I.valid?("\x89PNG\r\n\x1A\nrest".b, ".png")
    assert I.valid?("GIF89arest".b, ".gif")
    assert I.valid?("RIFF\x00\x00\x00\x00WEBPVP8 ".b, ".webp")
  end

  def test_rejects_mismatched_html_and_svg_content
    refute I.valid?("<html><script>alert(1)</script>".b, ".jpg")
    refute I.valid?("<svg xmlns='http://www.w3.org/2000/svg'></svg>".b, ".png")
    refute I.valid?("\x89PNG\r\n\x1A\n".b, ".jpg")
    refute I.valid?("anything".b, ".svg")
  end

  def test_mime_mapping_excludes_svg
    assert_equal ".jpg", I.extension_for_mime("image/jpeg")
    assert_nil I.extension_for_mime("image/svg+xml")
  end
end

class ImageProcessorTest < Minitest::Test
  # Records the commands instead of running ImageMagick.
  class FakeRunner
    attr_reader :calls

    def initialize = @calls = []

    def capture3(*argv)
      @calls << argv
      File.write(argv.last, "processed") # pretend IM wrote the output
      ["", "", Struct.new(:success?).new(true)]
    end
  end

  def test_copies_everything_when_no_tool_is_available
    skip "ImageMagick is installed here" if StaticSite::ImageProcessor.binary
    Dir.mktmpdir do |dir|
      src = File.join(dir, "media")
      FileUtils.mkdir_p(File.join(src, "photos"))
      File.write(File.join(src, "photos/a.jpg"), "raw")
      processed, copied = StaticSite::ImageProcessor.new(source_root: src, output_root: File.join(dir, "out")).call
      assert_equal [0, 1], [processed, copied]
      assert_equal "raw", File.read(File.join(dir, "out/photos/a.jpg"))
    end
  end

  def test_required_tool_missing_raises
    skip "ImageMagick is installed here" if StaticSite::ImageProcessor.binary
    assert_raises(StaticSite::ImageProcessor::MissingTool) do
      StaticSite::ImageProcessor.new(source_root: ".", output_root: ".", require_tool: true)
    end
  end

  def test_strips_metadata_and_builds_thumbnails_with_safe_argv
    skip "needs ImageMagick present to exercise the processing branch" unless StaticSite::ImageProcessor.binary
    Dir.mktmpdir do |dir|
      src = File.join(dir, "media")
      FileUtils.mkdir_p(File.join(src, "photos"))
      File.write(File.join(src, "photos/-rf weird name.jpg"), "raw")
      File.write(File.join(src, "photos/.keep"), "")
      runner = FakeRunner.new
      processed, = StaticSite::ImageProcessor.new(source_root: src, output_root: File.join(dir, "out"), runner: runner).call
      assert_equal 1, processed
      assert_equal 2, runner.calls.size
      runner.calls.each do |argv|
        assert_includes argv, "-strip"
        assert argv[1].start_with?("/"), "source must be an absolute path"
        assert argv.last.start_with?("/"), "destination must be an absolute path"
      end
      assert File.exist?(File.join(dir, "out/thumbs/photos/-rf weird name.jpg"))
    end
  end
end

class LinkCheckerExtrasTest < Minitest::Test
  def build(files)
    Dir.mktmpdir do |dir|
      files.each do |path, content|
        full = File.join(dir, path)
        FileUtils.mkdir_p(File.dirname(full))
        File.write(full, content)
      end
      yield dir
    end
  end

  def test_percent_encoded_file_names_are_found
    build("index.html" => '<img src="./media/my%20photo.jpg">', "media/my photo.jpg" => "x") do |dir|
      assert_empty StaticSite::LinkChecker.new(dir).broken_links
    end
  end

  def test_root_absolute_links_are_checked_against_the_base_path
    page = '<a href="/repo/css/site.css">x</a><a href="/css/site.css">y</a>'
    build("404.html" => page, "css/site.css" => "") do |dir|
      broken = StaticSite::LinkChecker.new(dir, base_path: "/repo").broken_links
      assert_equal [ "/css/site.css" ], broken.map(&:url)
      assert_equal [ "/repo/css/site.css" ], StaticSite::LinkChecker.new(dir).broken_links.map(&:url)
    end
  end

  def test_links_cannot_escape_the_site_folder
    build("sub/index.html" => '<a href="../../outside">x</a>') do |dir|
      assert_equal 1, StaticSite::LinkChecker.new(File.join(dir, "sub")).broken_links.size
    end
  end
end
