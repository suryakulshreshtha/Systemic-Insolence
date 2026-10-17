module StaticSite
  # Do not trust a file extension or a Content-Type header. Check the first
  # bytes. SVG is deliberately NOT supported for downloads: an SVG served from
  # your own domain can carry script.
  module ImageSniffer
    SIGNATURES = {
      ".jpg"  => ->(b) { b.start_with?("\xFF\xD8\xFF".b) },
      ".png"  => ->(b) { b.start_with?("\x89PNG\r\n\x1A\n".b) },
      ".gif"  => ->(b) { b.start_with?("GIF87a".b, "GIF89a".b) },
      ".webp" => ->(b) { b.bytesize >= 12 && b.byteslice(0, 4) == "RIFF".b && b.byteslice(8, 4) == "WEBP".b }
    }.freeze

    MIME_TO_EXT = {
      "image/jpeg" => ".jpg",
      "image/png"  => ".png",
      "image/gif"  => ".gif",
      "image/webp" => ".webp"
    }.freeze

    module_function

    def extension_for_mime(mime) = MIME_TO_EXT[mime.to_s.downcase]

    # True when the bytes really are the image type the extension claims.
    def valid?(bytes, extension)
      check = SIGNATURES[extension.to_s.downcase.sub(".jpeg", ".jpg")]
      check ? check.call(bytes.to_s.b) : false
    end
  end
end
