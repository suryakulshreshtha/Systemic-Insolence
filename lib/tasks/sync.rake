# Pull outside data in at build time. Each task is safe to run any time: a
# failure keeps the previous data and never stops the site from building,
# unless you set STRICT=1 (useful when testing a new setup).
namespace :sync do
  # Class names as strings so `rake -T` works without loading the app.
  sources = {
    goodreads:   "GoodreadsSync",
    feed_photos: "FeedPhotoSync",
    drive:       "DriveSync"
  }

  run = lambda do |name, class_name|
    result = class_name.constantize.call
    puts "sync:#{name}: #{result.status} (#{result.message})"
    abort "sync:#{name} failed" if result.status == :failed && ENV["STRICT"] == "1"
  end

  sources.each do |name, class_name|
    desc "Sync #{name.to_s.tr('_', ' ')} into the site"
    task(name => :environment) { run.call(name, class_name) }
  end

  desc "Run every configured sync (goodreads, feed_photos, drive)"
  task all: :environment do
    sources.each { |name, class_name| run.call(name, class_name) }
  end
end
