#frozen_string_literal: true

require 'timecop'
package_require('ree_logger/formatters/default_formatter')

RSpec.describe ReeLogger::DefaultFormatter do
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
    expected = "[05/11/05 00:00:00] INFO: Some message"
    expect(formatter.format(info_log_event, nil)).to eq(expected)
  }

  it {
    expected = "[SomeCoolApp] [05/11/05 00:00:00] INFO: Some message"
    expect(formatter.format(info_log_event, "SomeCoolApp")).to eq(expected)
  }

  it {
    expected = "[05/11/05 00:00:00] ERROR: Some error message\nPARAMETERS: {some_error: \"params\"}\nEXCEPTION: StandardError (Help me, I am error)\n"
    expect(formatter.format(error_log_event, nil)).to eq(expected)
  }
end
