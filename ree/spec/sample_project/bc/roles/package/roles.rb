module Roles
include Ree::PackageDSL
  package do
    tags       ['roles']

    depends_on :accounts
  end
end
