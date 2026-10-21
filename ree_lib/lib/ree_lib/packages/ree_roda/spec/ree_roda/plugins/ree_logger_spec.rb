# frozen_string_literal = true

package_require("ree_roda/plugins/ree_logger")

RSpec.describe :ree_logger do
  class TestFilterLogger
    def info(msg)
      logs << msg
    end

    def logs
      @logs ||= []
    end
  end

  let(:logger) { TestFilterLogger.new }

  let(:app) {
    log = logger

    Class.new(ReeRoda::App) do
      plugin(:ree_logger, ree_logger: log, filter_params: ["password", "token"])

      route do |r|
        r.is "health" do
          "success"
        end
      end
    end
  }

  def request_line
    logger.logs.first.lines.find { _1.include?("Request:") }
  end

  def params_line
    logger.logs.first.lines.find { _1.include?("Params:") }
  end

  it "filters request params" do
    env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/health", "QUERY_STRING" => "email=test@example.com&password=password" }

    app.app.call(env)

    expect(logger.logs.first).to match('"password" => "\[FILTERED\]"')
  end

  it "filters secrets in the query string of the request line" do
    env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/health", "QUERY_STRING" => "email=test%40example.com&password=s3cret&token=tok-1" }

    app.app.call(env)

    expect(request_line).to include("/health?email=test%40example.com&password=[FILTERED]&token=[FILTERED]")
    expect(logger.logs.first).not_to include("s3cret")
    expect(logger.logs.first).not_to include("tok-1")
  end

  it "filters bracketed and encoded names in the query string" do
    env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/health", "QUERY_STRING" => "user%5Bpassword%5D=s3cret&user[name]=bob&token_id=7" }

    app.app.call(env)

    expect(request_line).to include("user%5Bpassword%5D=[FILTERED]&user[name]=bob&token_id=7")
    expect(logger.logs.first).not_to include("s3cret")
    expect(params_line).to include('"token_id" => "7"')
  end

  it "keeps an empty query string out of the request line" do
    env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/health", "QUERY_STRING" => "" }

    app.app.call(env)

    expect(request_line).to include("Request: GET /health \n")
  end

  it "filters nested params of a JSON body" do
    body = '{"user":{"name":"bob","password":"s3cret"},"sessions":[{"token":"tok-1","id":1}]}'
    env = {
      "REQUEST_METHOD" => "POST", "PATH_INFO" => "/health",
      "CONTENT_TYPE" => "application/json", "rack.input" => StringIO.new(body)
    }

    app.app.call(env)

    expect(params_line).to include('"name" => "bob"')
    expect(params_line).to include('"id" => 1')
    expect(logger.logs.first).not_to include("s3cret")
    expect(logger.logs.first).not_to include("tok-1")
  end

  it "logs the query string untouched without filter params" do
    log = logger
    plain_app = Class.new(ReeRoda::App) do
      plugin(:ree_logger, ree_logger: log)

      route do |r|
        r.is "health" do
          "success"
        end
      end
    end

    env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/health", "QUERY_STRING" => "password=p" }

    plain_app.app.call(env)

    expect(request_line).to include("/health?password=p")
  end
end
