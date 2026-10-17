require "active_support/core_ext/integer/time"

# "production" here means "the environment that builds the public static site".
# It is only ever used by `bin/rails static:build`; no Rails server runs in
# production, so there is no TLS, host or session configuration to harden.
Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true

  config.consider_all_requests_local = false
  # Fail the build loudly on any rendering error instead of writing an error page.
  config.action_dispatch.show_exceptions = :none
  config.action_controller.perform_caching = false
  config.cache_store = :memory_store

  # The site has no sessions, cookies or signed data, so nothing depends on this
  # value. Rails still wants one to boot, so give it a fixed non-secret.
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "static-site-build-not-a-secret")

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.logger = ActiveSupport::TaggedLogging.logger($stdout)
  config.active_support.report_deprecations = false
end
