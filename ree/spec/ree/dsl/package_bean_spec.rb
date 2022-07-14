# frozen_string_literal  = true

RSpec.describe Ree::ObjectDsl do
  before :all do
    Ree.enable_irb_mode
  end

  after :all do
    Ree.disable_irb_mode
  end

  it {
    module TestPackageModule
      include Ree::PackageDSL
      package

      class TestBean
        include Ree::BeanDSL

        bean :test_bean

        def call
          :ok
        end
      end
    end

    result = TestPackageModule::TestBean.new.call
    expect(result).to eq(:ok)
  }
end