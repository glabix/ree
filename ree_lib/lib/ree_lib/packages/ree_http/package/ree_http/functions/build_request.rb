# frozen_string_literal: true

class ReeHttp::BuildRequest
  include Ree::FnDSL

  fn :build_request do
    link :not_blank, from: :ree_object
    link :to_json, from: :ree_json
    link 'ree_http/constants', -> {
      HTTPS_STR & HTTP_STR & HTTPS_PORT & HTTP_PORT & DEFAULT_FORCE_SSL
    }
  end

  DEFAULT_PROTOCOL_PORTS = [HTTPS_PORT, HTTP_PORT]

  DEFAULTS = {
    headers: {},
    force_ssl: DEFAULT_FORCE_SSL,
  }.freeze

  doc(<<~DOC)
    Builds Net::HTTPRequest with specified method, url, headers, body, form data,
    query params, basic auth or bearer token. Forces SSL mode
  DOC

  contract(
    Symbol,
    String,
    Ksplat[
      headers?: HashOf[Or[String, Symbol], Or[String, Integer]],
      body?: Or[HashOf[Or[Symbol, String], Or[Integer, Float, Bool, String, Hash, Array]], String, File],
      form_data?: HashOf[Or[Symbol, String], Or[Integer, Float, Bool, String, Array, File]],
      query_params?: HashOf[Or[String, Symbol], Or[String, Integer]],
      force_ssl?: Bool,
      basic_auth?: {
        username: String,
        password: String
      },
      bearer_token?: String,
    ] => Net::HTTPRequest,
    ).throws(ArgumentError)
  def call(method, url, **opts)
    unless opts[:body].nil?
      unless  opts[:form_data].nil?
        raise ArgumentError, "You can't use body argument with form_data argument"
      end
    end

    opts = DEFAULTS.merge(opts)
    uri = URI(url)

    uri.scheme = opts[:force_ssl] ? HTTPS_STR : uri.scheme

    if DEFAULT_PROTOCOL_PORTS.include?(uri.port)
      uri.port = opts[:force_ssl] ? HTTPS_PORT : uri.port
    end

    q_string = opts[:query_params] ? URI.encode_www_form(opts[:query_params]) : nil

    uri.query = if uri.query.nil?
      q_string
    else
      if not_blank(q_string)
        uri.query + '&' + q_string.to_s
      else
        uri.query
      end
    end

    request =
      case method
      when :get then Net::HTTP::Get.new(uri)
      when :post then Net::HTTP::Post.new(uri)
      when :put then Net::HTTP::Put.new(uri)
      when :delete then Net::HTTP::Delete.new(uri)
      when :patch then Net::HTTP::Patch.new(uri)
      when :head then Net::HTTP::Head.new(uri)
      when :options then Net::HTTP::Options.new(uri)
      else
        raise ArgumentError, "Unavailable rest method"
      end

    unless opts[:body].nil?
      request.body =
        case opts[:body]
        when Hash then to_json(opts[:body])
        when File then opts[:body].read
        else
          opts[:body]
        end
    end

    unless opts[:form_data].nil?
      request = add_form_data(request, opts[:form_data])
    end

    opts[:headers].each do |k, v|
      request.add_field k, v
    end

    unless opts[:basic_auth].nil?
      request.basic_auth(opts[:basic_auth][:username], opts[:basic_auth][:password])
    end

    unless opts[:bearer_token].nil?
      request.add_field "Authorization", generate_bearer_auth(opts[:bearer_token])
    end

    request
  end

  private

  def add_form_data(request, form_data)
    array_form_data = []

    form_data.each_pair do |k, v|
      array_form_data << [k.to_s, v]
    end

    request.set_form([*array_form_data], "multipart/form-data", charset: "UTF-8")

    request
  end

  def generate_bearer_auth(token)
    "Bearer " + token.to_s
  end
end

