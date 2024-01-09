# frozen_string_literal: true

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

        bean :test_bean do
          freeze false
        end

        def call
          :ok
        end
      end
    end

    bean = TestPackageModule::TestBean.new
    result = bean.call
    expect(result).to eq(:ok)
    expect(bean.frozen?).to eq(false)
  }
end