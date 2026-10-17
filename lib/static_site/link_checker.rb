module StaticSite
  # Walks a finished static site and reports internal links and assets that
  # point at files which do not exist. Stdlib only.
  class LinkChecker
    REFERENCE = /\b(?:href|src|poster)=(?<q>["'])(?<url>.*?)\k<q>/m
    SKIP = %r{\A(?:[a-z][a-z0-9+.-]*:|//|#)}i # http:, https:, mailto:, tel:, data:, //host, #anchor

    Broken = Struct.new(:page, :url, keyword_init: true)

    # base_path: where the site lives on its host ("" or "/repo"). Pages that
    # use root-absolute links (404.html) are checked against it.
    def initialize(root, base_path: "")
      @root = File.expand_path(root)
      @base_path = base_path.to_s.chomp("/")
    end

    def broken_links
      Dir.glob(File.join(@root, "**", "*.html")).sort.flat_map do |page|
        html = File.read(page, encoding: "UTF-8")
        html.scan(REFERENCE).filter_map do |_quote, raw_url|
          url = raw_url.strip
          next if url.empty? || url.match?(SKIP)
          next if exists?(page, url)

          Broken.new(page: page.delete_prefix("#{@root}/"), url: url)
        end
      end
    end

    private

    def exists?(page, url)
      path = unescape(url.sub(/[?#].*\z/m, ""))
      return true if path.empty?

      target = resolve(page, path)
      return false if target.nil?
      return false unless target == @root || target.start_with?("#{@root}/")

      File.file?(target) || File.file?(File.join(target, "index.html"))
    rescue ArgumentError # a NUL byte or similar in the address
      false
    end

    def resolve(page, path)
      return File.expand_path(path, File.dirname(page)) unless path.start_with?("/")

      # Root-absolute: it must start with the site's base path.
      return nil unless @base_path.empty? || path == @base_path || path.start_with?("#{@base_path}/")

      File.expand_path(path.delete_prefix(@base_path).delete_prefix("/"), @root)
    end

    # "my%20photo.jpg" is the file "my photo.jpg".
    def unescape(path)
      path.gsub(/%([0-9a-fA-F]{2})/) { Regexp.last_match(1).hex.chr }.force_encoding("UTF-8")
    end
  end
end
