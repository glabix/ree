# frozen_string_literal: true

module ReeEnum
  package
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
# end