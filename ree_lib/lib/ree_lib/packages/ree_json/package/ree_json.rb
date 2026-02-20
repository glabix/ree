require "json"

module ReeJson
  include Ree::PackageDSL

  package do
    depends_on :ree_hash
  end
end
