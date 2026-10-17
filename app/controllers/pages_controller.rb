class PagesController < ApplicationController
  def home
    @posts    = PostRepository.recent(site.posts_on_home)
    @about    = Page.find("about")
    @books    = Bookshelf.for_home(site.books_on_home)
    @photos   = PhotoJournal.recent(site.photos_on_home)
    @projects = Project.all

    set_meta(canonical: helpers.absolute_url(root_path))
  end

  def now         = render_markdown_page("now")
  def about       = render_markdown_page("about")
  def about_site  = render_markdown_page("about-this-site")

  def bookshelf
    @currently_reading = Bookshelf.currently_reading
    @read              = Bookshelf.read
    return render_not_found if @currently_reading.empty? && @read.empty?

    set_meta(
      title: "Bookshelf",
      description: "What #{site.name} is reading.",
      canonical: helpers.absolute_url(bookshelf_path)
    )
  end

  def photos
    @photos = PhotoJournal.all
    return render_not_found if @photos.empty?

    set_meta(
      title: "Photo journal",
      description: "Photographs by #{site.name}.",
      canonical: helpers.absolute_url(photos_path)
    )
  end

  private

  def render_markdown_page(slug)
    @page = Page.find(slug)
    return render_not_found if @page.nil?

    set_meta(
      title: @page.title,
      description: @page.description.presence || site.description,
      canonical: helpers.absolute_url(request.path)
    )
    render :show
  end

  def render_not_found
    set_meta(title: "Not found", noindex: true)
    render "errors/not_found", status: :not_found
  end
end
