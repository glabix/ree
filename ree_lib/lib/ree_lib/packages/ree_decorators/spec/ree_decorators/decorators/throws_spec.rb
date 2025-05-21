# frozen_string_literal: true

package_require('ree_decorators/decorators/throws')

RSpec.describe ReeDecorators::Throws do
  link :throws, from: :ree_decorators

  class TestThrowsDecorator
    include Ree::LinkDSL

    link :throws, from: :ree_decorators

    throws(ArgumentError)
    def addition(a, b)
      a + b
    end
  end

  it "decorates methods with throws" do
    decorator = ReeDecorators::DecoratorStore.new
      .get_method_decorator(TestThrowsDecorator, :addition, false, ReeDecorators::Throws)

    expect(decorator.context).to eq([ArgumentError])
  end
end
