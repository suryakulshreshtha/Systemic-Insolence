class ApplicationController < ActionController::Base
  include Seo

  before_action :set_default_meta

  private

  def site = Rails.application.config.x.site

  def set_default_meta
    set_meta(
      title: site.name,
      description: site.description,
      image: social_image_url,
      type: "website"
    )
  end
end
