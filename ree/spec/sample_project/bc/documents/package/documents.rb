module Documents
  include Ree::PackageDSL
  
  package do
    tags       ['roles']

    depends_on :accounts
    depends_on :string_utils
  end
end
