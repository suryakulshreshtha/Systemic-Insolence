require "test_helper"

class ExportTest < ActiveSupport::TestCase
  test "the whole site builds into plain files with no broken links" do
    output = Rails.root.join("tmp/test_site")
    exporter = StaticSite::Exporter.new(
      app: Rails.application,
      root: Rails.root,
      output: output,
      site: Rails.application.config.x.site,
      out: StringIO.new
    )
    exporter.call

    %w[index.html 404.html blog/index.html feed.xml sitemap.xml robots.txt .nojekyll css/site.css js/theme.js].each do |file|
      assert output.join(file).file?, "#{file} was not built"
    end

    home = File.read(output.join("index.html"))
    assert_includes home, 'href="./css/site.css', "home page should use relative links"
    refute_match(%r{(?:href|src)="/[^/]}, home, "home page still has root-absolute links")

    assert_empty StaticSite::LinkChecker.new(output, base_path: Rails.application.config.x.site.base_path).broken_links
  ensure
    FileUtils.rm_rf(output) if output
  end

  test "the exporter refuses to delete anything outside the project" do
    exporter = StaticSite::Exporter.new(
      app: Rails.application, root: Rails.root, output: Rails.root.join(".."),
      site: Rails.application.config.x.site, out: StringIO.new
    )
    assert_raises(StaticSite::Exporter::BuildError) { exporter.call }
  end
end
