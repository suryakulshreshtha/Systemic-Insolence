require_relative "boot"

require "erb"
require "yaml"
require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module PersonalSite
  class Application < Rails::Application
    config.load_defaults 8.1

    # lib/ holds the static-site helpers (lib/static_site) and rake tasks.
    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "UTC"

    # Markdown content lives outside app/, so it is never autoloaded.
    config.x.content_path = Rails.root.join("content")

    # Site identity, read from config/site.yml. Three values can be overridden
    # from the environment, which is how the deploy workflow points the same
    # build at github.io today and at your own domain later.
    site_file = Rails.root.join("config/site.yml")
    site_yaml = YAML.safe_load(ERB.new(site_file.read).result, aliases: true)
    config.x.site = ActiveSupport::OrderedOptions.new
    site_yaml.each { |key, value| config.x.site[key.to_sym] = value }

    # Set to true by the static exporter when it has made small thumbnails.
    config.x.thumbnails = false

    site = config.x.site
    site.host      = ENV["SITE_HOST"]      if ENV["SITE_HOST"].to_s.strip != ""
    site.protocol  = ENV["SITE_PROTOCOL"]  if ENV["SITE_PROTOCOL"].to_s.strip != ""
    site.base_path = ENV["SITE_BASE_PATH"] if ENV.key?("SITE_BASE_PATH")
    site.base_path = site.base_path.to_s.chomp("/")
    site.base_path = "/#{site.base_path.delete_prefix('/')}" unless site.base_path.empty?

    # No sessions, cookies, forms or database: the generated site is static.
  end
end
