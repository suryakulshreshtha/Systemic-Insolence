# The site's own "not found" page. The static exporter saves this as 404.html,
# which GitHub Pages serves for any address that does not exist.
class ErrorsController < ApplicationController
  def not_found
    set_meta(title: "Not found", noindex: true)
    render :not_found, status: :not_found
  end
end
