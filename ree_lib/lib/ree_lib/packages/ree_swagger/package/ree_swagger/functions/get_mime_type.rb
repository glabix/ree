# frozen_string_literal: true

class ReeSwagger::GetMimeType
  include Ree::FnDSL

  MIME_TYPES = {
    :html => "text/html", 
    :text => "text/plain", 
    :js => "text/javascript", 
    :css => "text/css", 
    :ics => "text/calendar", 
    :csv => "text/csv", 
    :vcf => "text/vcard", 
    :vtt => "text/vtt", 
    :png => "image/png", 
    :jpeg => "image/jpeg", 
    :gif => "image/gif", 
    :bmp => "image/bmp", 
    :tiff => "image/tiff", 
    :svg => "image/svg+xml", 
    :mpeg => "video/mpeg", 
    :mp3 => "audio/mpeg", 
    :ogg => "audio/ogg", 
    :m4a => "audio/aac", 
    :webm => "video/webm", 
    :mp4 => "video/mp4", 
    :otf => "font/otf", 
    :ttf => "font/ttf", 
    :woff => "font/woff", 
    :woff2 => "font/woff2", 
    :xml => "application/xml", 
    :rss => "application/rss+xml", 
    :atom => "application/atom+xml", 
    :yaml => "application/x-yaml", 
    :multipart_form => "multipart/form-data", 
    :url_encoded_form => "application/x-www-form-urlencoded", 
    :json => "application/json", 
    :pdf => "application/pdf", 
    :zip => "application/zip", 
    :gzip => "application/gzip"
  }.freeze

  fn :get_mime_type

  contract(Or[*MIME_TYPES.keys] => String)
  def call(type)
    MIME_TYPES.fetch(type)
  end
end