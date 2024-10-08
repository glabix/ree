# frozen_string_literal: true

RSpec.describe Ree::LinkDSL do
  Ree.enable_irb_mode

  module TestLinkDsl
    include Ree::PackageDSL

    package

    class TestFn
      include Ree::FnDSL

      fn :test_fn

      def call
        1
      end
    end
  end

  Ree.disable_irb_mode

  it {
    class TestClass
      include Ree::LinkDSL

      link :test_fn, from: :test_link_dsl

      def call
        test_fn
      end
    end

    expect(TestClass.new.call).to eq(1)
  }

  it {
    class TestLinkDsl::TestClass
      include Ree::LinkDSL

      link :test_fn

      def call
        test_fn
      end
    end

    expect(TestClass.new.call).to eq(1)
  }

  it {
    expect {
      class TestClass
        include Ree::LinkDSL

        link :test_fn

        def call
          test_fn
        end
      end
    }.to raise_error do |e|
      expect(e.code).to eq(:invalid_dsl_usage)
      expect(e.message).to eq("package is not provided for link :test_fn")
    end
  }
end