# frozen_string_literal: true

class ReeSwagger::RegisterType
  include Ree::FnDSL

  fn :register_type do
    link :type_definitions_repo
  end

  SEMAPHORE = Mutex.new

  contract(Or[:casters, :serializers], Any, Proc => nil)
  def call(kind, type, definition)
    SEMAPHORE.synchronize do
      type_definitions_repo[kind][type.name] = definition
    end

    nil
  end
end
