# frozen_string_literal: true

require 'sequel/adapters/postgres'

class ReeDao::BuildPgConnection
  include Ree::FnDSL

  fn :build_pg_connection do
    link :build_connection
  end

  contract(
    {
      conn_str?: String,
      adapter?: String,
      database?: String,
      encoding?: String,
      user?: String,
      password?: String,
      host?: String,
      port?: String,
      convert_infinite_timestamps?: Or[:string, :nil, :float],
      connect_timeout?: Integer,
      driver_options?: Hash,
      notice_receiver?: Proc,
      sslmode?: Or['disable', 'allow', 'prefer', 'require', 'verify-ca', 'verify-full'],
      sslrootcert?: String,
      search_path?: String,
      use_iso_date_format?: Bool,
    },
    Ksplat[
      RestKeys => Any # inherited from `build_connection` opts
    ] => nil
  )
  def call(conn_opts, **opts)
    build_connection(conn_opts, **opts)
  end
end