# frozen_string_literal: true

class ReeHttp::HttpExec
  include Ree::FnDSL

  fn :http_exec do
    link :build_request
    link :execute_request
    link :slice, from: :ree_hash

    link 'ree_http/constants', -> {
      DEFAULT_TIMEOUT & DEFAULT_WRITE_TIMEOUT & DEFAULT_FORCE_SSL
    }
  end

  DEFAULTS = {
    headers: {},
    timeout: DEFAULT_TIMEOUT,
    write_timeout: DEFAULT_WRITE_TIMEOUT,
    force_ssl: DEFAULT_FORCE_SSL,
  }.freeze

  OPTS_CONTRACT = {
    headers?: HashOf[Or[String, Symbol], Or[String, Integer]],
    body?: Or[String, Hash, File],
    form_data?: HashOf[Or[Symbol, String], Or[Integer, Float, Bool, String, Array, File]],
    write_timeout?: Integer,
    timeout?: Integer,
    redirects_count?: Integer,
    strict_redirect_mode?: Bool,
    query_params?: HashOf[Or[String, Symbol], Any],
    force_ssl?: Bool,
    ca_certs?: ArrayOf[File],
    basic_auth?: {
      username: String,
      password: String
    },
    bearer_token?: String,
    proxy?: {
      address: String,
      port?: Integer,
      username?: String,
      password?: String
    }
  }

  doc(<<~DOC)
    Sends HTTP request to a specified destination.

    Options:
      method - request method (:get, :post, :delete, :put, :patch, :head, :options)
      url - request URL
      headers - request headers
      body - request body (String, Hash or File). Should not be used together with form data
      form_data - request form data. Files are being sent with corresponding filenames
      query_params - request query string params
      basic_auth - sets basic auth credentials
      strict_redirect_mode - see build_request_executor
      redirects_count - see build_request_executor
      timeout - see build_request_executor
      force_ssl - see build_request_executor
      write_timeout - see build_request_executor
      ca_certs - see build_request_executor
      proxy - see build_request_executor

    Examples usage:
      http_exec('https://example.com', :get)
      http_exec('https://example.com', :post, form_data: {name: 'John', file: file})
      http_exec('https://example.com', :delete, basic_auth: {username: 'John', password: 'password'})
      http_exec('http://example.com', :options, force_ssl: true)
  DOC

  contract(
    Or[:get, :post, :put, :patch, :head, :options, :delete],
    String,
    Ksplat[**OPTS_CONTRACT],
    Optblock => Net::HTTPResponse
  )
  def call(method, url, **opts, &block)
    opts = DEFAULTS.merge(opts)

    request = build_request(
      method, url,
      **slice(opts, [
          :headers, :body, :form_data, :query_params,
          :force_ssl, :ca_certs, :basic_auth, :bearer_token
      ])
    )

    request_opts = slice(
      opts, [
        :timeout, :force_ssl, :ca_certs, :proxy, :write_timeout,
        :redirects_count, :strict_redirect_mode
      ]
    )

    execute_request(request, **request_opts, &block)
  end
end