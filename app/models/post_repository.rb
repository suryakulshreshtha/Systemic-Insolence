# Loads every Markdown post once and keeps them in memory, newest first.
#
# A personal blog has hundreds of posts at most, each a few kilobytes, so there
# is no database. In development the list reloads whenever a file changes so
# you can write with the preview server running.
class PostRepository
  class << self
    def all
      reload_if_stale
      @all ||= load_all
    end

    def published
      all.select(&:published?)
    end

    def recent(limit)
      published.first(limit)
    end

    def find(slug)
      reload_if_stale
      @by_slug ||= all.index_by(&:slug)
      post = @by_slug[slug]
      return nil if post.nil?
      return nil if post.draft? && !Rails.env.development?

      post
    end

    # Posts are ordered newest first, so "older" is the next index along.
    def neighbours(post)
      list = published
      index = list.index { |candidate| candidate.slug == post.slug }
      return [ nil, nil ] if index.nil?

      newer = index.positive? ? list[index - 1] : nil
      older = list[index + 1]
      [ newer, older ]
    end

    def reload!
      @all = nil
      @by_slug = nil
      @loaded_fingerprint = current_fingerprint
      all
    end

    private

    def content_dir = Rails.application.config.x.content_path.join("posts")

    def load_all
      posts = Dir.glob(content_dir.join("*.md")).sort.map { |path| Post.from_file(path) }

      duplicates = posts.group_by(&:slug).select { |_slug, list| list.size > 1 }.keys
      raise Post::InvalidPost, "duplicate post slug(s): #{duplicates.join(', ')}" if duplicates.any?

      posts.sort_by { |post| [ -post.date.to_time.to_i, post.slug ] }.freeze
    end

    def reload_if_stale
      return unless Rails.env.development?
      return if @loaded_fingerprint == current_fingerprint

      @all = nil
      @by_slug = nil
      @loaded_fingerprint = current_fingerprint
    end

    # Cheap change detection: filenames plus modification times.
    def current_fingerprint
      Dir.glob(content_dir.join("*.md")).sort.map { |f| "#{f}:#{File.mtime(f).to_i}" }.join
    end
  end
end
