module ReeSwagger
  include Ree::PackageDSL

  package do
    depends_on :ree_mapper
    depends_on :ree_dto
    depends_on :ree_hash
    depends_on :ree_enum
  end
end
