require 'i18n'

module ReeI18n
  include Ree::PackageDSL

  package do
    depends_on :ree_array
  end
end
