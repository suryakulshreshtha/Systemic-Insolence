module StaticSite
  # Turns the root-absolute URLs Rails produces ("/blog/misty", "/css/site.css")
  # into URLs that work wherever the site is hosted:
  #
  #   * at a domain root          https://example.com/
  #   * under a project path      https://user.github.io/repo/
  #   * opened straight from disk file:///.../index.html
  #
  # Pure Ruby on purpose (no Rails, no Nokogiri) so it is easy to test.
  module UrlRewriter
    # href="/x", src='/x', action="/x" ... but never protocol-relative "//host".
    ATTRIBUTE = /(?<attr>\b(?:href|src|action|poster|data-src)=)(?<q>["'])(?<url>\/(?!\/)[^"']*)\k<q>/

    module_function

    # Rewrite root-absolute URLs in an HTML page into document-relative ones.
    # `depth` is how many directories deep the page file lives (blog/x/index.html => 2).
    def relativize_html(html, depth:)
      prefix = depth.zero? ? "./" : "../" * depth
      html.gsub(ATTRIBUTE) do
        m = Regexp.last_match
        "#{m[:attr]}#{m[:q]}#{relative(m[:url], prefix)}#{m[:q]}"
      end
    end

    # Rewrite root-absolute URLs by prefixing a base path ("/repo") or an origin.
    # Used for pages served from many depths (404.html) and for feed content.
    def prefix_html(html, prefix)
      return html if prefix.to_s.empty?

      html.gsub(ATTRIBUTE) do
        m = Regexp.last_match
        "#{m[:attr]}#{m[:q]}#{prefix}#{m[:url]}#{m[:q]}"
      end
    end

    def relative(url, prefix)
      path, tail = split_tail(url)
      stripped = path.delete_prefix("/")
      # Pretty URLs: pages live at <path>/index.html, so link to the directory.
      stripped += "/" if !stripped.empty? && !stripped.end_with?("/") && File.extname(stripped).empty?
      "#{prefix}#{stripped}#{tail}"
    end

    def split_tail(url)
      index = url.index(/[?#]/)
      index ? [url[0...index], url[index..]] : [url, ""]
    end
  end
end
