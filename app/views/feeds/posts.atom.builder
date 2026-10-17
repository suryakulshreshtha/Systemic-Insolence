xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xml:lang" => site.language do
  xml.title site.name
  xml.subtitle site.description
  xml.id absolute_url("/")
  xml.link rel: "alternate", type: "text/html", href: absolute_url("/")
  xml.link rel: "self", type: "application/atom+xml", href: absolute_url("/feed.xml")
  xml.updated((@posts.first ? @posts.first.date : Date.current).to_time.utc.iso8601)
  xml.author { xml.name site.name }

  @posts.each do |post|
    xml.entry do
      xml.title post.title
      xml.id absolute_url(post_path(post.slug))
      xml.link rel: "alternate", type: "text/html", href: absolute_url(post_path(post.slug))
      xml.published post.date.to_time.utc.iso8601
      xml.updated post.date.to_time.utc.iso8601
      xml.summary post.summary
      xml.content absolutize_html(post.body_html), type: "html"
    end
  end
end
