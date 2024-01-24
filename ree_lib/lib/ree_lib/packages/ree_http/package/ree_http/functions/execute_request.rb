# frozen_string_literal: true

class ReeHttp::ExecuteRequest
  include Ree::FnDSL

  fn :execute_request do
    link :build_request
    link :build_request_executor
    link :slice, from: :ree_hash
    link 'ree_http/constants', -> {
      DEFAULT_TIMEOUT & DEFAULT_WRITE_TIMEOUT & DEFAULT_FORCE_SSL
    }
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
    timeout: DEFAULT_TIMEOUT,
    write_timeout: DEFAULT_WRITE_TIMEOUT,
    force_ssl: DEFAULT_FORCE_SSL,
  }.freeze

  doc(<<~DOC)
    Executes prepared Net::HTTPRequest.

    Optional options:
      strict_redirect_mode - raise RedirectMethodError if strict_redirect_mode=true (default)
      otherwise redirects with GET method if response code in [300, 301, 302]

      redirects_count - raise TooManyRedirectsError if we have more redirects than specified otherwise proceed redirects

      timeout - wait response timeout (defaults to 60 seconds)

      write_timeout - send request timeout (defaults to 30 seconds)

      force_ssl - force SSL on

      ca_certs - sets path of a CA certification files

      proxy - set proxy server auth
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
         address: String,
         port?: Integer,
         username?: String,
         password?: String
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

    if response.is_a?(Net::HTTPRedirection)
      return process_redirect_response(response, request, opts, &block)
    end

    response
  end

  private

  def process_redirect_response(response, request, opts, &block)
    if opts[:redirects_count] == 0
      raise TooManyRedirectsError, "Got too match redirects, if you want more redirects, use redirects_count"
    end

    if opts[:strict_redirect_mode] && STRICT_SENSITIVE_CODES.include?(response.code.to_i) && UNSAFE_VERBS.include?(request.method.to_sym)
      raise RedirectMethodError, "Got #{response.code.to_i} with strict_mode"
    end

    if (ALWAYS_GET_CODES.include?(response.code.to_i) || STRICT_SENSITIVE_CODES.include?(response.code.to_i)) && UNSAFE_VERBS.include?(request.method.downcase.to_sym)
      request.instance_variable_set(:@method, 'GET')
    end

    new_uri = URI(response['Location'] || response['location'])
    new_request = build_request(
      request.method.downcase.to_sym,
      new_uri.to_s,
      **slice(opts, [
          :headers, :body, :form_data, :query_params,
          :force_ssl, :ca_certs, :basic_auth, :bearer_token
      ])
    )

    opts[:redirects_count] -= 1

    call(new_request, **opts, &block)
  end
end
