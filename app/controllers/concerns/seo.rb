# Every page gets a complete, correct set of meta tags. No gem needed.
module Seo
  extend ActiveSupport::Concern

  included do
    helper_method :meta, :page_title
  end

  def meta
    @meta ||= {}
  end

  def set_meta(**attrs)
    meta.merge!(attrs.compact)
  end

  # Social cards need absolute URLs. A site path ("/media/x.jpg") becomes
  # https://host/<base>/media/x.jpg.
  def absolute_asset_url(name)
    return nil if name.blank?
    return name.to_s if name.to_s.start_with?("http")

    helpers.absolute_url(name.to_s.start_with?("/") ? name.to_s : "/images/#{name}")
  end

  # The site-wide share image, or nil. SVG is skipped on purpose: most link
  # previews cannot render it, which would show a broken picture.
  def social_image_url
    image = Rails.application.config.x.site.social_image.to_s
    return nil if image.blank? || image.downcase.end_with?(".svg")

    absolute_asset_url(image)
  end

  def page_title
    site_name = meta[:site_name] || Rails.application.config.x.site.name
    return site_name.to_s if meta[:title].blank? || meta[:title] == site_name

    "#{meta[:title]} | #{site_name}"
  end
end
