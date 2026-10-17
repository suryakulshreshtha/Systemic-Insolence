require "json"
require "fileutils"

# Where build-time syncs leave their results (tmp/sync/*.json). Writes are
# atomic, and a failed sync never overwrites the last good file, so a Goodreads
# or Google outage cannot empty the site.
module SyncStore
  module_function

  def dir = Rails.root.join("tmp/sync")

  def path(name) = dir.join("#{name}.json")

  def read(name)
    file = path(name)
    return nil unless File.exist?(file)

    JSON.parse(File.read(file, encoding: "UTF-8"))
  rescue JSON::ParserError
    nil
  end

  def write(name, data)
    FileUtils.mkdir_p(dir)
    temp = dir.join("#{name}.json.tmp")
    File.write(temp, JSON.pretty_generate(data))
    File.rename(temp, path(name))
  end

  def modified_at(name)
    file = path(name)
    File.exist?(file) ? File.mtime(file) : nil
  end
end
