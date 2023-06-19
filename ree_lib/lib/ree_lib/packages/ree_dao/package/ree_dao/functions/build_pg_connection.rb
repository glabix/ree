# frozen_string_literal: true

class ReeDao::BuildPgConnection
  include Ree::FnDSL

  fn :build_pg_connection do
    link :build_connection
  end

  contract(
    {
      conn_str?: String,
      adapter: String,
      database?: String,
      encoding?: String,
      user?: String,
      password?: String,
      host?: String,
      port?: Or[String, Integer],
      convert_infinite_timestamps?: Or[:string, :nil, :float],
      connect_timeout?: Integer,
      driver_options?: Hash,
      notice_receiver?: Proc,
      sslmode?: Or['disable', 'allow', 'prefer', 'require', 'verify-ca', 'verify-full'],
      sslrootcert?: String,
      search_path?: String,
      use_iso_date_format?: Bool,
      max_connections?: Integer,
      pool_timeout?: Integer
    },
    Ksplat[
      RestKeys => Any # inherited from `build_connection` opts
    ] => Sequel::Database
  )
  def call(conn_opts, **opts)
    require 'sequel/adapters/postgres'
    build_connection(conn_opts, **opts)
  end
end