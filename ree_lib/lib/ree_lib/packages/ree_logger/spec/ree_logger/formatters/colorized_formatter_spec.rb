#frozen_string_literal: true

require 'timecop'
package_require('ree_logger/formatters/colorized_formatter')

RSpec.describe ReeLogger::ColorizedFormatter do
  link :parse, from: :ree_datetime

  let(:formatter) { described_class.new }

  let(:info_log_event) {
    ReeLogger::LogEvent.new(
      :info,
      "Some message",
      nil,
      {}
    )
  }

  let(:error_log_event) {
    ReeLogger::LogEvent.new(
      :error,
      "Some error message",
      StandardError.new('Help me, I am error'),
      { some_error: "params" }
    )
  }

  before { Timecop.travel(parse('1605-11-05 00:00:00')) }
  after { Timecop.return }

  it { expect(formatter).to respond_to(:format) }

  it {
    expected = "[05/11/05 00:00:00] \e[36minfo:\e[0m Some message"
    expect(formatter.format(info_log_event, nil)).to eq(expected)
  }

  it {
    expected = "[SomeCoolApp] [05/11/05 00:00:00] \e[36minfo:\e[0m Some message"
    expect(formatter.format(info_log_event, "SomeCoolApp")).to eq(expected)
  }

  it {
    expected = "[05/11/05 00:00:00] \e[31merror:\e[0m Some error message\n\e[34mPARAMETERS:\e[0m {:some_error=>\"params\"}\n\e[31mEXCEPTION:\e[0m StandardError (Help me, I am error)\n"
    expect(formatter.format(error_log_event, nil)).to eq(expected)
  }
end