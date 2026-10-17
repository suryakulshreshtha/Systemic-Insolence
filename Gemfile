source "https://rubygems.org"

ruby file: ".ruby-version"

# --- Framework ---------------------------------------------------------------
# Rails is used as a static-site generator: it renders every page once at build
# time and the result is plain HTML. Nothing here runs on the public web.
gem "rails", "~> 8.1.4"
gem "puma", ">= 6.0"                 # local preview server only (bin/dev)

# --- Content -----------------------------------------------------------------
gem "commonmarker", "~> 2.0"         # Markdown + syntax highlighting

# --- Build-time data syncs (Goodreads, photo feed, Google Drive) -------------
gem "faraday", "~> 2.9"
gem "faraday-retry"
gem "feedjira", "~> 4.0"
gem "nokogiri", ">= 1.18"

gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end
