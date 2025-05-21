# frozen_string_literal: true

package_require('ree_decorators/decorators/doc')

RSpec.describe ReeDecorators::Doc do
  class TestDocDecorator
    include Ree::LinkDSL

    link :doc, from: :ree_decorators

    doc "Adds two numbers"
    def addition(a, b)
      a + b
    end
  end

  it "decorates methods with doc" do
    decorator = ReeDecorators::DecoratorStore.new
      .get_method_decorator(TestDocDecorator, :addition, false, ReeDecorators::Doc)

    expect(decorator.context).to eq("Adds two numbers")
  end
end
