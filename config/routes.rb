Rails.application.routes.draw do
  root "pages#home"

  # --- Writing ---------------------------------------------------------------
  get "blog",       to: "posts#index", as: :posts
  get "blog/:slug", to: "posts#show",  as: :post, constraints: { slug: /[a-z0-9\-]+/ }

  # --- Standing pages (each one only exists when it has something to show) ---
  get "now",             to: "pages#now"
  get "about",           to: "pages#about"
  get "about-this-site", to: "pages#about_site", as: :about_site
  get "bookshelf",       to: "pages#bookshelf"
  get "photos",          to: "pages#photos"

  # --- Projects (data-driven from content/projects/*.yml) --------------------
  get "projects/:slug",         to: "projects#show",    as: :project,         constraints: { slug: /[a-z0-9\-]+/ }
  get "projects/:slug/privacy", to: "projects#privacy", as: :project_privacy, constraints: { slug: /[a-z0-9\-]+/ }

  # --- Machine-readable ------------------------------------------------------
  get "feed.xml",    to: "feeds#posts",   defaults: { format: :atom }, as: :feed
  get "sitemap.xml", to: "feeds#sitemap", defaults: { format: :xml },  as: :sitemap

  # --- Anything else: the site's own 404 page (the exporter saves it as 404.html)
  get "404", to: "errors#not_found", as: :not_found
  match "*unmatched", to: "errors#not_found", via: :all, format: false,
        constraints: ->(request) { !request.path.start_with?("/rails/") }
end
