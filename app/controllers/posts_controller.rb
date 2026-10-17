class PostsController < ApplicationController
  def index
    @posts = PostRepository.published

    set_meta(
      title: "Blog",
      description: "Posts by #{site.name}.",
      canonical: helpers.absolute_url(posts_path)
    )
  end

  def show
    @post = PostRepository.find(params[:slug])
    return render_not_found if @post.nil?

    @newer, @older = PostRepository.neighbours(@post)

    set_meta(
      title: @post.title,
      description: @post.summary,
      image: @post.og_image ? absolute_asset_url(@post.og_image) : social_image_url,
      type: "article",
      canonical: helpers.absolute_url(post_path(@post.slug)),
      published_time: @post.date.iso8601
    )
  end

  private

  def render_not_found
    set_meta(title: "Not found", noindex: true)
    render "errors/not_found", status: :not_found
  end
end
