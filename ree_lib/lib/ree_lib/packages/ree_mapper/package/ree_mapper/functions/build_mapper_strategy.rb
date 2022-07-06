# frozen_string_literal: true

class ReeMapper::BuildMapperStrategy
  include Ree::FnDSL

  fn :build_mapper_strategy

  OUTPUT_MAP = {
    string_key_hash: ReeMapper::StringKeyHashOutput,
    symbol_key_hash: ReeMapper::SymbolKeyHashOutput,
    object:          ReeMapper::ObjectOutput
  }.freeze

  contract(Kwargs[
    method:          Symbol,
    output:          Symbol,
    always_optional: Bool
  ] => ReeMapper::MapperStrategy).throws(ArgumentError)
  def call(method:, output:, always_optional: false)
    raise ArgumentError, 'invalid output' unless OUTPUT_MAP.key?(output)

    ReeMapper::MapperStrategy.new(
      method:          method,
      output:          OUTPUT_MAP.fetch(output).new,
      always_optional: always_optional
    )
  end
end
