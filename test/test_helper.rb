ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "tmpdir"

module TestSupport
  # Swap a singleton method for the length of a block (no mocking library needed).
  def with_stubbed(object, method, replacement)
    original = object.method(method)
    object.define_singleton_method(method) { |*args, **kwargs, &block| replacement.respond_to?(:call) ? replacement.call(*args, **kwargs, &block) : replacement }
    yield
  ensure
    object.define_singleton_method(method, original)
  end

  def with_content_path(path)
    config = Rails.application.config.x
    previous = config.content_path
    config.content_path = Pathname.new(path)
    yield
  ensure
    config.content_path = previous
  end
end

class ActiveSupport::TestCase
  include TestSupport
end
