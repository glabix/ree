# frozen_string_literal: true

class ReeDao::BuildDao
  include Ree::FnDSL

  fn :build_dao

  contract(
    Kwargs[
      connection: Any,
      table_name: Symbol,
      mapper: -> (v) { v.class.ancestors.include?(ReeMapper::Mapper) }
    ],
    Ksplat[
      primary_key?: Nilor[Or[Symbol, ArrayOf[Symbol]]],
      default_select_columns?: Nilor[ArrayOf[Symbol]],
    ] => Any
  )
  def call(connection:, table_name:, mapper:, **opts)
    connection[table_name]
      .clone(
        mode: :write,
        schema_mapper: mapper,
        primary_key: opts[:primary_key] || :id
      )
  end
end