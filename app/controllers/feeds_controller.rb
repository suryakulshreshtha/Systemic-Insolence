class FeedsController < ApplicationController
  # Full-content Atom feed: how regular readers actually follow a writing site.
  def posts
    @posts = PostRepository.published.first(30)
    render formats: :atom
  end

  def sitemap
    @posts    = PostRepository.published
    @projects = Project.all
    @sections = SiteSections.available

    render formats: :xml
  end
end
