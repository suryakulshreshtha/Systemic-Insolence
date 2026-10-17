require "open3"
require "fileutils"

module StaticSite
  # Publishes every raster image under public/media with its metadata removed
  # (camera EXIF can contain GPS coordinates) and a sensible size, plus a small
  # thumbnail for grids. Uses ImageMagick when present.
  #
  # Originals in the repository are never modified; processed copies are
  # written only into the generated site.
  class ImageProcessor
    PROCESSABLE = %w[.jpg .jpeg .png .webp].freeze
    FULL_BOUNDS = "2400x2400>".freeze # shrink only, never enlarge
    THUMB_BOUNDS = "800x800>".freeze

    class MissingTool < StandardError; end

    def self.binary
      %w[magick convert].find do |name|
        ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? { |dir| File.executable?(File.join(dir, name)) }
      end
    end

    def initialize(source_root:, output_root:, require_tool: false, runner: Open3)
      @source_root = File.expand_path(source_root)
      @output_root = File.expand_path(output_root)
      @require_tool = require_tool
      @runner = runner
      @binary = self.class.binary
      raise MissingTool, "ImageMagick (magick/convert) is required but was not found" if @require_tool && @binary.nil?
    end

    def tool? = !@binary.nil?

    # Returns [processed_count, copied_count].
    def call
      processed = copied = 0
      Dir.glob(File.join(@source_root, "**", "*")).sort.each do |file|
        next unless File.file?(file)
        next if File.basename(file) == ".keep"

        relative = file.delete_prefix("#{@source_root}/")
        destination = File.join(@output_root, relative)
        FileUtils.mkdir_p(File.dirname(destination))

        if tool? && PROCESSABLE.include?(File.extname(file).downcase)
          optimise(file, destination)
          thumbnail(file, File.join(@output_root, "thumbs", relative))
          processed += 1
        else
          FileUtils.cp(file, destination)
          copied += 1
        end
      end
      [processed, copied]
    end

    private

    def optimise(source, destination)
      run([@binary, source, "-auto-orient", "-strip", "-resize", FULL_BOUNDS, "-quality", "85", destination])
    end

    def thumbnail(source, destination)
      FileUtils.mkdir_p(File.dirname(destination))
      run([@binary, source, "-auto-orient", "-strip", "-resize", THUMB_BOUNDS, "-quality", "80", destination])
    end

    # Arguments are passed as an array (no shell), and source/destination are
    # absolute paths, so a file name can never be read as an option or a command.
    def run(argv)
      _out, err, status = @runner.capture3(*argv)
      raise "ImageMagick failed for #{argv[1]}: #{err.to_s.strip}" unless status.success?
    end
  end
end
