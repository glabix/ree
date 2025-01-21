#frozen_string_literal: true

require 'rollbar'
package_require('ree_logger/multi_logger')
package_require('ree_logger/appenders/stdout_appender')
package_require('ree_logger/appenders/file_appender')
package_require('ree_logger/appenders/rollbar_appender')

RSpec.describe ReeLogger::MultiLogger do
  link :is_blank, from: :ree_object

  before(:all) do
    tmp_file_log = ENV['LOG_FILE_PATH']

    if !is_blank(tmp_file_log)
      File.open(tmp_file_log, 'w') {|file| file.truncate(0) }
    end
  end

  let(:multi_logger) { described_class }
  let(:log_file_path) { ENV['LOG_FILE_PATH'] }
  let(:exception) {
    StandardError.new('Some Exception')
  }

  let(:file_appender) {
    ReeLogger::FileAppender.new(
      :info,
      nil,
      log_file_path,
      auto_flush: true
    )
  }

  let(:stdout_appender) {
    ReeLogger::StdoutAppender.new(
      :info,
      nil
    )
  }

  let(:rollbar_appender) {
    ReeLogger::RollbarAppender.new(
      :info,
      access_token: ENV['LOG_ROLLBAR_ACCESS_TOKEN'],
      environment: ENV['LOG_ROLLBAR_ENVIRONMENT']
    )
  }

  let(:logger) {
    multi_logger.new(
      'SomeCoolApp',
      nil,
      ['password']
    )
  }

  let(:logger_with_appenders) {
    [file_appender, stdout_appender, rollbar_appender].map { logger.add_appender(_1) }

    logger
  }

  before(:each) do
    allow(Rollbar).to receive(:log)
  end

  it {
    expect { logger.add_appender(stdout_appender) }.to change { logger.appenders }
  }

  it {
    expect { logger.info('any message') }.to_not output(/any message/).to_stdout
    expect(Rollbar).not_to have_received(:log)
    expect(File.read(log_file_path)).to_not match('any message')
  }

  it {
    expect { logger_with_appenders.info('hello world') }.to output(/hello world/).to_stdout
    expect(Rollbar).to have_received(:log)
    expect(File.read(log_file_path)).to match("hello world")
  }

  it {
    expect { logger_with_appenders.info {'block message'} }.to output(/block message/).to_stdout
    expect(Rollbar).to have_received(:log)
    expect(File.read(log_file_path)).to match("block message")
  }

  it {
    expect { logger_with_appenders.info('hello world', { param: 1, another_param: { name: 'John'}, password: 'password01' }) }.to output(/John/).to_stdout
    expect(Rollbar).to have_received(:log)
    expect(File.read(log_file_path)).to match("John")
    expect(File.read(log_file_path)).to match("password: \"FILTERED\"")
  }

  it {
    expect { logger_with_appenders.debug('debug message') }.to_not output(/debug message/).to_stdout
    expect(Rollbar).not_to have_received(:log)
    expect(File.read(log_file_path)).to_not match("debug")
  }

  it {
    expect { logger_with_appenders.warn('warning message') }.to output(/warning message/).to_stdout
    expect(Rollbar).to have_received(:log)
    expect(File.read(log_file_path)).to match("warning message")
  }

  it {
    output = with_captured_stdout {
      logger_with_appenders.error('some error message', {}, exception, false)
    }
    expect(output).to match(/some error message/)
    expect(output).to_not match(/method|args/)
    expect(File.read(log_file_path)).to match("some error message")
    expect(Rollbar).to have_received(:log)
    expect(File.read(log_file_path)).to_not match("PARAMETERS: {:method=>{:name=>:call, :args=>{:block=>{}}}}")
  }

  it {
    expect { logger_with_appenders.fatal('some fatal message', { email: 'some@mail.com', password: 'password01' }, exception) }.to output(/some fatal message/).to_stdout
    expect(Rollbar).to have_received(:log)
    expect(File.read(log_file_path)).to match("some fatal message")
    expect(File.read(log_file_path)).to match("password: \"FILTERED\"")
  }

  it {
    expect { logger_with_appenders.unknown('unknown message') }.to output(/unknown message/).to_stdout
    expect(Rollbar).to have_received(:log)
    expect(File.read(log_file_path)).to match("unknown message")
  }

  it {
    expect { logger_with_appenders.silence }.to change { logger_with_appenders.silenced }
  }

  it {
    expect {
      logger_with_appenders.silence do
        logger_with_appenders.info('hush')
        logger_with_appenders.info('I will keep my mouth shut')
      end
    }.to_not output.to_stdout
  }

  it {
    expect {
      logger_with_appenders.info("some info message", { email: 'some@email.com }'}) do
        {
          name: "John"
        }
      end
    }.to output(/John/).to_stdout
  }
end
