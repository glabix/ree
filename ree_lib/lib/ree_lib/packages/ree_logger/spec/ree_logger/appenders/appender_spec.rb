#frozen_string_literal = true

package_require('ree_logger/appenders/appender')

RSpec.describe ReeLogger::Appender do
  let(:appender) { described_class }

  it {
    appender = described_class.new(:level, nil)

    expect { appender.append({}) }.to raise_error(NotImplementedError) do |e|
      expect(e.message).to eq("should be implemented in derived class")
    end
  }
end