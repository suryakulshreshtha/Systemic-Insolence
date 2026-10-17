require "fileutils"
require "rack/mock"

module StaticSite
  # Turns the Rails app into a folder of plain files (default: _site/) that any
  # static host can serve. Every page is rendered by the real app, through the
  # real router, exactly as a visitor's request would be, then saved as
  # <path>/index.html.
  #
  # The build fails loudly (and publishes nothing) if any page errors or any
  # internal link or image points at a file that does not exist.
  class Exporter
    class BuildError < StandardError; end

    def initialize(app:, root:, output:, site:, require_imagemagick: false, out: $stdout)
      @app = app
      @root = Pathname.new(root).expand_path
      @output = Pathname.new(output).expand_path
      @site = site
      @require_imagemagick = require_imagemagick
      @out = out
    end

    def call
      guard_output_path
      reset_output
      processor = copy_public_files
      # Thumbnails exist only if ImageMagick made them, so pages may link to them.
      Rails.application.config.x.thumbnails = processor.tool?
      pages = render_pages
      write_not_found
      write_extras
      check_links
      @out.puts "Built #{pages} pages into #{@output.relative_path_from(@root)}"
    end

    # The list of addresses that exist right now.
    def paths
      list = [ "/", "/blog" ]
      list += PostRepository.published.map { |post| "/blog/#{post.slug}" }
      list += %w[now about about-this-site].select { |slug| Page.find(slug) }.map { |slug| "/#{slug}" }
      list << "/bookshelf" if Bookshelf.any?
      list << "/photos" if PhotoJournal.any?
      Project.all.each do |project|
        list << "/projects/#{project.slug}"
        list << "/projects/#{project.slug}/privacy" if project.privacy_html
      end
      list + [ "/feed.xml", "/sitemap.xml" ]
    end

    private

    # The output folder is deleted on every build, so be certain it is a
    # folder inside the project and never the project itself.
    def guard_output_path
      inside = @output.to_s.start_with?("#{@root}/") && @output != @root
      raise BuildError, "Refusing to build into #{@output}: it must be a folder inside #{@root}" unless inside
    end

    def reset_output
      FileUtils.rm_rf(@output)
      FileUtils.mkdir_p(@output)
    end

    def copy_public_files
      processor = ImageProcessor.new(
        source_root: @root.join("public"),
        output_root: @output,
        require_tool: @require_imagemagick
      )
      processed, copied = processor.call
      if processor.tool?
        @out.puts "Images: #{processed} processed (metadata removed, resized, thumbnails made), #{copied} other files copied"
      else
        @out.puts "WARNING: ImageMagick not found. Photos are published as-is, including any camera metadata (location!)."
        @out.puts "         Install it (apt install imagemagick / brew install imagemagick) or build in CI."
      end
      processor
    end

    def render_pages
      client = Rack::MockRequest.new(@app)
      paths.each do |path|
        response = client.get(path, "HTTP_HOST" => "localhost")
        raise BuildError, "GET #{path} returned #{response.status}\n#{response.body.to_s[0, 400]}" unless response.status == 200

        body = response.body.dup.force_encoding("UTF-8")
        file = file_for(path)
        body = UrlRewriter.relativize_html(body, depth: file.count("/")) if file.end_with?(".html")
        write(file, body)
      end
      paths.size
    end

    def file_for(path)
      return "index.html" if path == "/"

      File.extname(path).empty? ? "#{path.delete_prefix('/')}/index.html" : path.delete_prefix("/")
    end

    # 404.html is served for addresses at any depth, so it cannot use relative
    # links: it gets the site's base path in front of every address instead.
    def write_not_found
      response = Rack::MockRequest.new(@app).get("/404", "HTTP_HOST" => "localhost")
      raise BuildError, "GET /404 returned #{response.status}, expected 404" unless response.status == 404

      html = response.body.dup.force_encoding("UTF-8")
      write("404.html", UrlRewriter.prefix_html(html, @site.base_path))
    end

    def write_extras
      write(".nojekyll", "")
      sitemap = "#{@site.protocol}://#{@site.host}#{@site.base_path}/sitemap.xml"
      write("robots.txt", "User-agent: *\nAllow: /\n\nSitemap: #{sitemap}\n")
    end

    def check_links
      broken = LinkChecker.new(@output, base_path: @site.base_path).broken_links
      return if broken.empty?

      lines = broken.first(25).map { |link| "  #{link.page}: #{link.url}" }
      raise BuildError, "#{broken.size} broken link(s) or missing file(s):\n#{lines.join("\n")}"
    end

    def write(relative, content)
      target = @output.join(relative)
      FileUtils.mkdir_p(target.dirname)
      File.write(target, content)
    end
  end
end
