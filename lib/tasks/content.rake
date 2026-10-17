namespace :content do
  desc "Check every post, page, project, book and photo entry for mistakes"
  task lint: :environment do
    problems = []
    content = Rails.application.config.x.content_path

    begin
      posts = PostRepository.all
      drafts = posts.count(&:draft?)
      scheduled = posts.count { |post| !post.draft? && post.date > Date.current }
      puts "Posts: #{posts.size} (#{drafts} draft, #{scheduled} scheduled for later)"
    rescue Post::InvalidPost => e
      problems << e.message
    end

    Dir.glob(content.join("pages", "*.md")).each do |path|
      slug = File.basename(path, ".md")
      problems << "#{path}: page name must be lowercase letters, numbers and hyphens" unless slug.match?(Page::SLUG)
    end

    Dir.glob(content.join("projects", "*.yml")).each do |path|
      begin
        Project.new(File.basename(path, ".yml"), path)
      rescue StandardError => e
        problems << "#{path}: #{e.message}"
      end
    end

    %w[books photos].each do |name|
      file = content.join("#{name}.yml")
      next unless File.exist?(file)

      begin
        YAML.safe_load(File.read(file, encoding: "UTF-8"), permitted_classes: [ Date ])
      rescue Psych::Exception => e
        problems << "content/#{name}.yml is not valid YAML: #{e.message.lines.first.to_s.strip}"
      end
    end

    # Links in books.yml / photos.yml that would be silently dropped as unsafe.
    { "books.yml" => %w[url cover], "photos.yml" => %w[link] }.each do |name, keys|
      file = content.join(name)
      next unless File.exist?(file)

      data = YAML.safe_load(File.read(file, encoding: "UTF-8"), permitted_classes: [ Date ]) || {}
      rows = data.is_a?(Hash) ? data.values.flatten : Array(data)
      rows.grep(Hash).each do |row|
        keys.each do |key|
          next if row[key].blank?

          problems << "content/#{name}: #{row['title'] || row['file']}: #{key} #{row[key].inspect} is not an http(s) or site address" if StaticSite::SafeUrl.clean(row[key]).nil?
        end
      end
    end

    problems.each { |line| puts "ERROR: #{line}" }
    abort "#{problems.size} problem(s) found." if problems.any?
    puts "Content OK."
  end

  desc 'Start a new post: bin/rails "content:post[My title]"'
  task :post, [ :title ] => :environment do |_task, args|
    title = args[:title].to_s.strip
    abort 'Give it a title: bin/rails "content:post[My title]"' if title.empty?

    slug = title.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    abort "Could not make a web address from that title; use letters or numbers." if slug.empty?

    file = Rails.application.config.x.content_path.join("posts", "#{Date.current.iso8601}-#{slug}.md")
    abort "#{file} already exists." if File.exist?(file)

    File.write(file, <<~MARKDOWN)
      ---
      title: #{title.inspect}
      date: #{Date.current.iso8601}
      description: ""
      draft: true
      ---

      Write here.
    MARKDOWN
    puts "Created #{file.relative_path_from(Rails.root)}"
    puts "It is a draft: change `draft: true` to `draft: false` when it is ready to publish."
  end
end
