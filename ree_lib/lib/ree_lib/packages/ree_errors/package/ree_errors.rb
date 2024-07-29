module ReeErrors
  include Ree::PackageDSL

  package do
    depends_on :ree_i18n
    depends_on :ree_string
  end
end
