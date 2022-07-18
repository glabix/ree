# frozen_string_literal: true

module ReeEnum
  include Ree::PackageDSL

  package do
    depends_on :ree_mapper
    depends_on :ree_validator
  end
end

require_relative 'ree_enum/dsl'
require_relative 'ree_enum/enumerable'

# Example of Usage
# class YourPackageName::YourEnumName
#   include ReeEnum::DSL
#
#   enum :your_enum_name
#
#   val :first, 0
#   val :second, 1
#
#   register_as_mapper_type
# end