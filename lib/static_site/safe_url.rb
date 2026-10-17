module StaticSite
  # Content files (books.yml, photos.yml, projects/*.yml) hold URLs that end up in
  # href/src attributes. Only allow schemes that cannot run script.
  module SafeUrl
    WEB = %r{\Ahttps?://[^\s<>"']+\z}i
    MAIL = /\Amailto:[^\s<>"']+\z/i
    SITE_PATH = %r{\A/(?!/)[^\s<>"']*\z} # "/media/x.jpg" but not "//evil.example"

    module_function

    # Returns the URL if it is safe to publish, otherwise nil.
    def clean(url, allow_mail: false, allow_site_path: true)
      value = url.to_s.strip
      return nil if value.empty?
      return value if value.match?(WEB)
      return value if allow_mail && value.match?(MAIL)
      return value if allow_site_path && value.match?(SITE_PATH)

      nil
    end

    def web?(url) = !clean(url, allow_site_path: false).nil?
  end
end
