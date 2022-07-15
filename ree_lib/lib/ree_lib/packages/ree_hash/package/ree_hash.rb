# frozen_string_literal: true

module ReeHash
  include Ree::PackageDSL

  package do
    depends_on :ree_date
    depends_on :ree_validator
  end

end
