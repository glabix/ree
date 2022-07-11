# frozen_string_literal: true

class ReeHttp::HttpPost
  include Ree::FnDSL

  fn :http_post do
    link :http_exec, import: -> { OPTS_CONTRACT }
  end

  doc(<<~DOC)
    Sends POST request
    Returns response.    
    Options:
      url - url of request 
      headers - headers of the request
      body - body of the request, if File was given file will be read and added to the body as String. Can't use with form_data
      form_data - form_data of the request, if File was given file, file will be read with specific file_name
      query_params - query string of the request. Will added after the path like <path>?a=100&b=simple
      force_ssl - use True that if you want send request with HTTPS protocol. Will be applied with 443 port if protocol in URI is HTTP or HTTPS. If True In other cases will change only protocol, not port. If false, dont change anything
      auth - can be "Basic" or "Bearer", use username & password or bearer_token respectively

      strict_redirect_mode - if response code in [300, 301, 302] and strict_redirect_mode=false, will be redirected with GET method, if strict_redirect_mode=true(default) will raise RedirectMethodError
      redirects_count - count of redirects, if redirects more than redirects_count will raise TooManyRedirectsError
      timeout - timeout of waiting of response after request was sent, default 60
      write_timeout - timeout of waiting of sending request, if you send large file maybe should be increased, default 30
      force_ssl - Turn on/off SSL. This flag must be set before starting session. If you change use_ssl value after session started, a Net::HTTP object raises IOError.
      ca_certs - adds ca_certs by reading files
      proxy - auth on proxy server, address required
  DOC
  
  contract(
    String,
    Ksplat[**OPTS_CONTRACT],
    Optblock => Net::HTTPResponse,
    )
  def call(url, **opts, &block)
    http_exec(:post, url, **opts, &block)
  end
end