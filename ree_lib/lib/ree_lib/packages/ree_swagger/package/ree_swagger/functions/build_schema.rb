# frozen_string_literal: true

class ReeSwagger::BuildSchema
  include Ree::FnDSL

  fn :build_schema do
    link :build_endpoint_schema
    link 'ree_swagger/dto/endpoint_dto', -> { EndpointDto }
  end

  contract(String, String, String, ArrayOf[EndpointDto] => Hash)
  def call(title:, description:, version:, endpoints:)
    {
      openapi: "3.0.0",
      info: {
        title:       title,
        description: description,
        version:     version
      },
      paths: endpoints.each_with_object(Hash.new { _1[_2] = {} }) {
        path_dto = build_endpoint_schema(_1)
        _2[path_dto.path].merge!(path_dto.schema)
      }
    }
  end
end
