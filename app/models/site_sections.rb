# Which sections of the site exist right now. A section appears in the menu,
# the home page and the sitemap only when it has something to show, so a visitor
# never lands on an empty page or a "set this up" message.
class SiteSections
  Section = Struct.new(:label, :path, :blurb, keyword_init: true)

  def self.available
    [
      Section.new(label: "Blog", path: "/blog", blurb: "Notes and longer pieces."),
      (Section.new(label: "Now", path: "/now", blurb: "What has my attention at the moment.") if Page.find("now")),
      (Section.new(label: "Bookshelf", path: "/bookshelf", blurb: "What I am reading.") if Bookshelf.any?),
      (Section.new(label: "Photos", path: "/photos", blurb: "Everyday photography.") if PhotoJournal.any?)
    ].compact
  end
end
