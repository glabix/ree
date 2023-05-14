# frozen_string_literal: true


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
      max_connections?: Integer,
      pool_timeout?: Integer
    },
    Ksplat[
      RestKeys => Any # inherited from `build_connection` opts
    ] => Sequel::Database
  )
  def call(conn_opts, **opts)
    require 'sequel/adapters/sqlite'
    build_connection(conn_opts.merge(adapter: 'sqlite'), **opts)
  end
end