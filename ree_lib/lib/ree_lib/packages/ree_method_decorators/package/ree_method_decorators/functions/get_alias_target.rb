# frozen_string_literal: true

class ReeMethodDecorators::GetAliasTarget
  include Ree::FnDSL

  fn :get_alias_target do
  end

  def call(target, is_class_method)
    if is_class_method
      class << target
        self
      end
    else
      target
    end
  end
end
