# frozen_string_literal: true

class ReeSwagger::GetCasterDefinition
  include Ree::FnDSL

  fn :get_caster_definition do
    link :type_definitions_repo
  end

  contract(Any, Proc => Nilor[Hash])
  def call(type, schema_builder)
    type_definitions_repo
      .dig(:casters, type.class.name)
      &.(type, schema_builder)
  end
end
