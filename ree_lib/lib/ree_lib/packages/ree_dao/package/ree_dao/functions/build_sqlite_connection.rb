# frozen_string_literal: true

require 'sequel/adapters/sqlite'

class ReeDao::BuildSqliteConnection
  include Ree::FnDSL

  fn :build_sqlite_connection do
    link :build_connection
  end

  contract(
    {
      database: String,
      readonly?: Bool,
      timeout?: Integer,
    },
    Ksplat[
      RestKeys => Any # inherited from `build_connection` opts
    ] => Sequel::SQLite::Database
  )
  def call(conn_opts, **opts)
    build_connection(conn_opts.merge(adapter: 'sqlite'), **opts)
  end
end