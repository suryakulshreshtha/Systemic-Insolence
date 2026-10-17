require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "every post on disk parses" do
    assert PostRepository.all.any?, "expected at least one post in content/posts"
  end

  test "posts are ordered newest first" do
    dates = PostRepository.published.map(&:date)
    assert_equal dates.sort.reverse, dates
  end

  test "slug falls back to the filename when frontmatter omits it" do
    post = Post.from_file(Rails.root.join("content/posts/2026-03-21-misty.md"))
    assert_equal "misty", post.slug
  end

  test "a post without frontmatter is rejected loudly" do
    file = Tempfile.new([ "bad", ".md" ])
    file.write("no frontmatter here")
    file.flush

    assert_raises(Post::InvalidPost) { Post.from_file(file.path) }
  ensure
    file&.close!
  end

  test "neighbours walk the published list in both directions" do
    posts = PostRepository.published
    skip "needs at least three posts" if posts.size < 3

    newer, older = PostRepository.neighbours(posts[1])
    assert_equal posts[0].slug, newer.slug
    assert_equal posts[2].slug, older.slug
  end
end
