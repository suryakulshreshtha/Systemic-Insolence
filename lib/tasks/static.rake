namespace :static do
  desc "Build the whole site into _site/ (run with RAILS_ENV=production)"
  task build: :environment do
    StaticSite::Exporter.new(
      app: Rails.application,
      root: Rails.root,
      output: Rails.root.join(ENV.fetch("OUTPUT_DIR", "_site")),
      site: Rails.application.config.x.site,
      require_imagemagick: ENV["STATIC_REQUIRE_IMAGEMAGICK"] == "1"
    ).call
  rescue StaticSite::Exporter::BuildError, StaticSite::ImageProcessor::MissingTool => e
    abort "Build failed: #{e.message}"
  end

  desc "Check the built site (_site/) for broken internal links and missing images"
  task :check do
    require_relative "../static_site/link_checker"
    root = File.expand_path(ENV.fetch("OUTPUT_DIR", "_site"), Dir.pwd)
    abort "Nothing to check: run `bin/rails static:build` first." unless File.directory?(root)

    broken = StaticSite::LinkChecker.new(root, base_path: ENV["SITE_BASE_PATH"].to_s).broken_links
    if broken.empty?
      puts "No broken internal links."
    else
      broken.each { |link| puts "#{link.page}: #{link.url}" }
      abort "#{broken.size} broken link(s)."
    end
  end

  desc "Serve the built site locally at http://localhost:8080 (Ctrl-C to stop)"
  task serve: :environment do
    require "puma"
    require "rack/mime"

    root = Pathname.new(ENV.fetch("OUTPUT_DIR", "_site")).expand_path(Rails.root)
    abort "Nothing to serve: run `bin/rails static:build` first." unless root.directory?

    app = lambda do |env|
      path = Rack::Utils.unescape_path(env["PATH_INFO"].to_s)
      candidate = root.join(path.delete_prefix("/")).cleanpath
      candidate = candidate.join("index.html") if candidate.directory?
      inside = candidate.to_s.start_with?("#{root}/")

      if inside && candidate.file?
        [ 200, { "content-type" => Rack::Mime.mime_type(candidate.extname, "application/octet-stream") }, [ candidate.binread ] ]
      else
        page = root.join("404.html")
        [ 404, { "content-type" => "text/html" }, [ page.file? ? page.binread : "Not found" ] ]
      end
    end

    server = Puma::Server.new(app)
    server.add_tcp_listener("127.0.0.1", 8080)
    puts "Serving #{root} at http://localhost:8080 (Ctrl-C to stop)"
    begin
      server.run.join
    rescue Interrupt
      server.stop(true)
    end
  end
end
