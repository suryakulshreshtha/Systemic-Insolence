require "faraday"
require "faraday/retry"
require "json"

# A deliberately paranoid HTTP client for build-time syncs. Every external
# source is an RSS feed or API that can and will misbehave, so timeouts are
# short, responses are size-capped and failures are explicit.
class FeedClient
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 20
  MAX_BYTES = 25 * 1024 * 1024
  USER_AGENT = "PersonalSiteBot/1.0 (+https://%{host})".freeze
  FEED_ACCEPT = "application/rss+xml, application/atom+xml, application/xml, text/xml".freeze

  class FetchError < StandardError; end

  def self.get(url, **options) = new.get(url, **options)

  def self.get_json(url, **options) = new.get_json(url, **options)

  def get(url, accept: FEED_ACCEPT, params: nil, max_bytes: MAX_BYTES)
    response = connection(accept).get(url, params)
    raise FetchError, "#{safe(url)} returned #{response.status}" unless response.success?
    raise FetchError, "#{safe(url)} returned an empty body" if response.body.blank?
    raise FetchError, "#{safe(url)} is larger than #{max_bytes} bytes" if response.body.bytesize > max_bytes

    response.body
  rescue Faraday::Error => e
    raise FetchError, "#{safe(url)} failed: #{e.class}"
  end

  def get_json(url, params: nil)
    JSON.parse(get(url, accept: "application/json", params: params))
  rescue JSON::ParserError => e
    raise FetchError, "#{safe(url)} did not return JSON: #{e.message.truncate(80)}"
  end

  private

  # Never print query strings: they can carry API keys.
  def safe(url) = url.to_s.sub(/\?.*\z/, "")

  def connection(accept)
    Faraday.new do |f|
      f.request :retry,
                max: 2,
                interval: 1,
                backoff_factor: 2,
                retry_statuses: [ 429, 500, 502, 503, 504 ]

      f.headers["User-Agent"] = format(USER_AGENT, host: Rails.application.config.x.site.host)
      f.headers["Accept"] = accept

      f.options.open_timeout = OPEN_TIMEOUT
      f.options.timeout = READ_TIMEOUT

      f.adapter Faraday.default_adapter
    end
  end
end
