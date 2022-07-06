RSpec.describe Ree::Contracts::HashValidator do
  subject(:obj) {
    Class.new do
      contract({key: Symbol, other: Symbol, opt?: String} => :ok)
      def call(hsh)
        :ok
      end
    end.new
  }

  context 'with valid args' do
    it {
      expect(obj.call({ key: :ok, other: :ok })).to eq :ok

      expect(obj.call({ key: :ok, other: :ok, opt: 'str' })).to eq :ok
    }
  end

  context 'with invalid args' do
    it {
      expect { obj.call }.to raise_error(<<~MSG.chomp)
        Wrong number of arguments for #{obj.class}#call
        \t - missing value for `hsh`
      MSG
    }

    it {
      expect { obj.call([]) }.to raise_error(<<~MSG.chomp)
        Contract violation for #{obj.class}#call
        \t - hsh: expected Hash, got Array => []
      MSG
    }

    it {
      expect {
        obj.call({
          key: 'not symbol',
          missing: 'any'
        })
      }.to raise_error(<<~MSG.chomp)
        Contract violation for #{obj.class}#call
        \t - hsh:
        \t   - hsh[:key]: expected Symbol, got String => "not symbol"
        \t   - hsh[:other]: missing
        \t   - hsh[:missing]: unexpected
      MSG
    }

    it {
      expect {
        obj.call({
          key: :ok,
          other: :ok,
          opt: :not_string
        })
      }.to raise_error(<<~MSG.chomp)
        Contract violation for #{obj.class}#call
        \t - hsh:
        \t   - hsh[:opt]: expected String, got Symbol => :not_string
      MSG
    }
  end
end
