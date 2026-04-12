# frozen_string_literal = true

package_require("ree_roda/plugins/ree_logger")

RSpec.describe :ree_logger do
  it "filters request params" do
    class TestFilterApp < ReeRoda::App
      route do |r|
        r.get "health" do
          "success"
        end

        r.ree_routes
      end
    end

    env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/health", "QUERY_STRING" => "email=test@example.com&password=password" }

    class TestFilterLogger
      def info(msg)
        @logs ||= []
        @logs << msg
      end

      def logs
        @logs
      end
    end
    logger = TestFilterLogger.new

    TestFilterApp.plugin(:ree_logger, ree_logger: logger, filter_params: ['password'])
    TestFilterApp.app.call(env)

    expect(logger.logs.first).to match('"password" => "\[FILTERED\]"')
  end
end