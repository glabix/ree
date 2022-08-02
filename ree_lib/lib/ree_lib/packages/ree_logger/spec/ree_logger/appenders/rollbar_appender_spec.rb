#frozen_string_literal = true

package_require('ree_logger/appenders/rollbar_appender')

RSpec.describe ReeLogger::RollbarAppender do
  let(:rollbar_appender) { described_class }

  let(:log_event) {
    ReeLogger::LogEvent.new(
      :info,
      "Some message",
      nil,
      {}
    )
  }

  # comment "before" block to test sending to api
  before do
    allow(Rollbar).to receive(:log)
  end

  it "sends log event to Rollbar" do
    appender = rollbar_appender.new(
      :info,
      {
        access_token: ENV['ROLLBAR_ACCESS_TOKEN']
      }
    )

    expect(appender).to respond_to(:append)
    expect { appender.append(log_event) }.not_to raise_error
    expect(Rollbar).to have_received(:log)
  end
end