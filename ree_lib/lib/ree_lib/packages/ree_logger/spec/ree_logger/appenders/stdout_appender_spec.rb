#frozen_string_literal: true

package_require('ree_logger/appenders/stdout_appender')

RSpec.describe ReeLogger::StdoutAppender do
  let(:stdout_appender) { described_class }

  let(:log_event) {
    ReeLogger::LogEvent.new(
      :info,
      "Some message",
      nil,
      {}
    )
  }

  let(:custom_formatter) {
    Class.new(ReeLogger::Formatter) do
      def format(event, progname = nil)
        event.message.upcase
      end
    end
  }

  it "with default formatter" do
    appender = stdout_appender.new(
      :info,
      nil
    )

    expect(appender).to respond_to(:append)
    expect { appender.append(log_event) }.to output(/#{log_event.message}/).to_stdout
  end

  it "with custom formatter" do
    appender = stdout_appender.new(
      :info,
      custom_formatter.new
    )

    expect(appender).to respond_to(:append)
    expect { appender.append(log_event) }.to output(/#{log_event.message.upcase}/).to_stdout
  end
end