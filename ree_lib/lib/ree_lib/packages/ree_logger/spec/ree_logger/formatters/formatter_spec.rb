#frozen_string_literal = true

package_require('ree_logger/formatters/formatter')

RSpec.describe ReeLogger::Formatter do
  let(:formatter) { described_class.new }

  it {
    expect { formatter.format({})}.to raise_error(NotImplementedError) do |e|
      expect(e.message).to eq("should be implemented in derived class")
    end
  }
end