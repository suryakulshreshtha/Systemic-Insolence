namespace :media do
  desc "Check photos, covers and post images for problems before you push"
  task check: :environment do
    errors = []
    warnings = []
    media = Rails.root.join("public/media")
    allowed = %w[.jpg .jpeg .png .webp .gif]

    Dir.glob(media.join("{photos,posts,books,projects}/**/*")).sort.each do |path|
      next unless File.file?(path)

      name = path.delete_prefix("#{Rails.root}/")
      next if File.basename(path) == ".keep"

      ext = File.extname(path).downcase
      size = File.size(path)

      if !allowed.include?(ext)
        errors << "#{name}: .#{ext.delete('.')} is not allowed here (use JPG, PNG, WebP or GIF; SVG and HEIC are not published)"
      elsif !StaticSite::ImageSniffer.valid?(File.binread(path, 16), ext)
        errors << "#{name}: the contents do not look like a real #{ext} image"
      end

      errors << "#{name}: #{(size / 1_048_576.0).round(1)} MB is too large (limit 25 MB)" if size > 25 * 1_048_576
      warnings << "#{name}: #{(size / 1_048_576.0).round(1)} MB (the build shrinks it, but git keeps every version; consider resizing)" if size.between?(8 * 1_048_576, 25 * 1_048_576)
    end

    PhotoJournal.missing_files.each do |file|
      errors << "content/photos.yml lists #{file}, but public/media/photos/#{file} does not exist"
    end

    warnings << "ImageMagick not found: photos would be published with their camera metadata (GPS location). CI always has it." unless StaticSite::ImageProcessor.binary

    warnings.each { |line| puts "warning: #{line}" }
    errors.each { |line| puts "ERROR:   #{line}" }
    abort "#{errors.size} problem(s) found." if errors.any?
    puts "Media OK (#{warnings.size} warning#{'s' unless warnings.size == 1})."
  end
end
