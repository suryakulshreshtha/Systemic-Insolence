xml.instruct!
xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url { xml.loc absolute_url("/") }

  @sections.each do |section|
    xml.url { xml.loc absolute_url(section.path) }
  end

  xml.url { xml.loc absolute_url("/about") } if Page.find("about")

  @posts.each do |post|
    xml.url do
      xml.loc absolute_url(post_path(post.slug))
      xml.lastmod iso_date(post.date)
    end
  end

  @projects.each do |project|
    xml.url { xml.loc absolute_url(project_path(project.slug)) }
  end
end
