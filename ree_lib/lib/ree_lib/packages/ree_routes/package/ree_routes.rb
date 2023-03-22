module ReeRoutes
  include Ree::PackageDSL

  package do
    depends_on :ree_mapper
  end
end

require_relative "ree_routes/dsl"
