# frozen_string_literal: true

class ReeSwagger::GetSerializerDefinition
  include Ree::FnDSL

  fn :get_serializer_definition do
    link :type_definitions_repo
  end

  contract(Any, Proc => Nilor[Hash])
  def call(type, build_serializer_schema)
    type_definitions_repo
      .dig(:serializers, type.class)
      &.(type, build_serializer_schema)
  end
end
