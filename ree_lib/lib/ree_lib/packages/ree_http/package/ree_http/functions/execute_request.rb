# frozen_string_literal: true

class ReeHttp::ExecuteRequest
  include Ree::FnDSL

  fn :execute_request do
    link :build_request_executor
    link :slice, from: :ree_hash
    link 'ree_http/http_exceptions', -> { HttpExceptions }
  end

  include HttpExceptions

  REDIRECT_CODES = [300, 301, 302, 303, 307, 308].to_set.freeze
  STRICT_SENSITIVE_CODES = [300, 301, 302].to_set.freeze
  ALWAYS_GET_CODES = [303].to_set.freeze
  METHOD_NOT_MODIFIED_CODES = [307, 308].to_set.freeze
  UNSAFE_VERBS = %i[put delete post patch options].to_set.freeze
  SEE_OTHER_ALLOWED_VERBS = %i[get head].to_set.freeze
  MAX_REDIRECT_COUNT = 10

  DEFAULTS = {
    redirects_count: MAX_REDIRECT_COUNT,
    strict_redirect_mode: true,
    timeout: 60,
    write_timeout: 30,
    force_ssl: false,
  }.freeze

  doc(<<~DOC)
    Returns response.
    Options:
      request - configured request, preferably by build_request
      strict_redirect_mode - if response code in [300, 301, 302] and strict_redirect_mode=false, will be redirected with GET method, if strict_redirect_mode=true(default) will raise RedirectMethodError
      redirects_count - count of redirects, if redirects more than redirects_count will raise TooManyRedirectsError
      timeout - timeout of waiting of response after request was sent, default 60
      write_timeout - timeout of waiting of sending request, if you send large file maybe should be increased, default 30
      force_ssl - Turn on/off SSL. This flag must be set before starting session. If you change use_ssl value after session started, a Net::HTTP object raises IOError.
      ca_certs - adds ca_certs by reading files
      proxy - auth on proxy server, address required
  DOC

  contract(
     Net::HTTPRequest,
     Ksplat[
       write_timeout?: Integer,
       timeout?: Integer,
       redirects_count?: Integer,
       strict_redirect_mode?: Bool,
       force_ssl?: Bool,
       ca_certs?: ArrayOf[File],
       proxy?: {
        username: String,
        password: String
       }
     ],
     Optblock => Net::HTTPResponse
  ).throws(TooManyRedirectsError, RedirectMethodError)
  def call(request, **opts, &block)
    opts = DEFAULTS.merge(opts)

    requester = build_request_executor(
      request.uri,
      **slice(opts, [:timeout, :force_ssl, :ca_certs, :proxy, :write_timeout])
    )

    ReeHttp.logger.debug(
      "Sending #{request.method} request: URI #{request.uri}\n BODY: #{request.body}\n"
    )

    response = requester.start do |http|
      http.request(request, &block)
    end

    ReeHttp.logger.debug(
      "Got #{response.code} response on request URI #{request.uri}\n With BODY: #{response.body}\n"
    )

    process_redirect_response(response, request, opts, &block)
    response
  end

  private

  def process_redirect_response(response, request, opts, &block)
    if response.is_a?(Net::HTTPRedirection)
      if opts[:redirects_count] == 0
        raise TooManyRedirectsError, "Got too match redirects, if you want more redirects, use redirects_count"
      end

      if opts[:strict_redirect_mode] && STRICT_SENSITIVE_CODES.include?(response.code.to_i) && UNSAFE_VERBS.include?(request.method.to_sym)
        raise RedirectMethodError, "Got #{response.code.to_i} with strict_mode"
      end

      if (ALWAYS_GET_CODES.include?(response.code.to_i) || STRICT_SENSITIVE_CODES.include?(response.code.to_i)) && UNSAFE_VERBS.include?(request.method.downcase.to_sym)
        request.instance_variable_set(:@method, 'GET')
      end

      request.instance_variable_set(:@uri, URI(response['Location']))
      request.instance_variable_set(:@path, request.uri.path)

      opts[:redirects_count] -= 1

      return call(request, **opts, &block)
    end

    response
  end
end