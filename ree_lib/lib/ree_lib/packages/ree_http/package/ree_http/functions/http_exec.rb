# frozen_string_literal: true

class ReeHttp::HttpExec
  include Ree::FnDSL

  fn :http_exec do
    link :build_request
    link :execute_request
    link :slice, from: :ree_hash
  end

  DEFAULTS = {
    headers: {},
    timeout: 60,
    write_timeout: 30,
    force_ssl: false,
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