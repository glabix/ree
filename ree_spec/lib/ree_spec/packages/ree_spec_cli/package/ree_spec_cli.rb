module ReeSpecCli
  include Ree::PackageDSL

  package do
    depends_on :ree_array
    depends_on :ree_json
    depends_on :ree_dto
    depends_on :ree_hash
    depends_on :ree_object
  end
end
