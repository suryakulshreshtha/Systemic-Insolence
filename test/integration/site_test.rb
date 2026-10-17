require "test_helper"

class SiteTest < ActionDispatch::IntegrationTest
  test "home page renders with security headers in the markup" do
    get "/"
    assert_response :success
    assert_select "meta[http-equiv='Content-Security-Policy']"
    assert_select "link[rel=canonical]"
    assert_select "h1", text: Rails.application.config.x.site.name
  end

  test "no page uses inline styles or inline scripts" do
    [ "/", "/blog", "/about" ].each do |path|
      get path
      assert_response :success
      assert_no_match(/\sstyle=/, response.body, "#{path} has an inline style")
      assert_select "script:not([src]):not([type='application/ld+json'])", false, "#{path} has an inline script"
    end
  end

  test "blog index lists published posts only" do
    get "/blog"
    assert_response :success
    PostRepository.published.each { |post| assert_select "a[href='/blog/#{post.slug}']" }
    PostRepository.all.select(&:draft?).each { |post| assert_select "a[href='/blog/#{post.slug}']", false }
  end

  test "a published post renders" do
    post = PostRepository.published.first
    skip "no published posts" if post.nil?

    get "/blog/#{post.slug}"
    assert_response :success
    assert_select "h1", text: post.title
  end

  test "unknown addresses get the site's 404 page" do
    get "/definitely/not/here"
    assert_response :not_found
    assert_select "meta[name=robots][content=noindex]"
  end

  test "a section with no data is not published" do
    get "/photos"
    assert_response(PhotoJournal.any? ? :success : :not_found)
  end

  test "feed and sitemap are absolute and well formed" do
    get "/feed.xml"
    assert_response :success
    assert_match "application/atom+xml", response.media_type
    assert_includes response.body, Rails.application.config.x.site.host

    get "/sitemap.xml"
    assert_response :success
    assert_includes response.body, "<urlset"
    assert_includes response.body, "https://#{Rails.application.config.x.site.host}"
  end
end
