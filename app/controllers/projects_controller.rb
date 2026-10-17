class ProjectsController < ApplicationController
  def show
    @project = Project.find(params[:slug])
    return render_not_found if @project.nil?

    set_meta(
      title: @project.name,
      description: @project.description,
      image: @project.og_image ? absolute_asset_url(@project.og_image) : social_image_url,
      canonical: helpers.absolute_url(project_path(@project.slug))
    )
  end

  def privacy
    @project = Project.find(params[:slug])
    return render_not_found if @project.nil? || @project.privacy_html.nil?

    set_meta(
      title: "Privacy: #{@project.name}",
      description: "Privacy policy for #{@project.name}.",
      canonical: helpers.absolute_url(project_privacy_path(@project.slug))
    )
  end

  private

  def render_not_found
    set_meta(title: "Not found", noindex: true)
    render "errors/not_found", status: :not_found
  end
end
