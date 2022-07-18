#frozen_string_literal = true

package_require('ree_logger/appenders/file_appender')

RSpec.describe ReeLogger::FileAppender do
  link :is_blank, from: :ree_object

  let(:file_appender) { described_class }

  let(:log_event) {
    ReeLogger::LogEvent.new(
      :info,
      "Some message",
      nil,
      {}
    )
  }

  let(:log_file_path) { ENV['LOG_FILE_PATH'] }

  before(:all) do
    tmp_file_log = ENV['LOG_FILE_PATH']
      
    if !is_blank(tmp_file_log)
      File.open(tmp_file_log, 'w') {|file| file.truncate(0) }
    end
  end

  after(:all) do
    tmp_file_log = ENV['LOG_FILE_PATH']
      
    if !is_blank(tmp_file_log)
      File.open(tmp_file_log, 'w') {|file| file.truncate(0) }
    end
  end

  let(:custom_formatter) {
    Class.new(ReeLogger::Formatter) do
      def format(event, progname = nil)
        event.message.upcase
      end
    end
  }

  it "with default formatter" do
    appender = file_appender.new(
      :info,
      nil,
      log_file_path,
      auto_flush: true
    )

    expect(appender).to respond_to(:append)

    appender.append(log_event)
    expect(File.read(log_file_path)).to match(log_event.message)
  end

  it "with custom formatter" do
    appender = file_appender.new(
      :info,
      custom_formatter.new,
      log_file_path,
      auto_flush: true
    )

    expect(appender).to respond_to(:append)

    appender.append(log_event)
    expect(File.read(log_file_path)).to match(log_event.message.upcase)
  end
end