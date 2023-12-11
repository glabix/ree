# frozen_string_literal: true

require 'time'
require 'logger'
require 'timeout'

class ReeDao::BuildConnection
  include Ree::FnDSL

  fn :build_connection do
    link :connections
    link 'ree_dao/dataset_extensions', -> { DatasetExtensions }
  end

  TIMEZONES = [:utc, :local].freeze

  DEFAULTS = {
    datetime_class: DateTime,
    database_timezone: :utc,
    application_timezone: :utc,
    typecast_timezone: :utc,
    single_threaded: false,
    timeout: 90
  }.freeze

  contract(
    Hash,
    Ksplat[
      fibered?: Bool,
      timeout?: Integer,
      convert_two_digit_years?: Bool,
      single_threaded?: Bool,
      extensions?: ArrayOf[Symbol],
      datetime_class?: Or[Time, DateTime],
      after_connect?: Proc,
      database_timezone?: Or[*TIMEZONES],
      application_timezone?: Or[*TIMEZONES],
      typecast_timezone?: Or[*TIMEZONES],
      logger?: Logger,
      sql_log_level?: [:fatal, :error, :warn, :info, :debug],
    ] => Any
  )
  def call(conn_opts, **opts)
    opts = DEFAULTS.merge(opts.dup)

    database_timezone = opts.delete(:database_timezone)
    application_timezone = opts.delete(:application_timezone)
    typecast_timezone = opts.delete(:typecast_timezone)
    convert_two_digit_years = opts.delete(:convert_two_digit_years)
    single_threaded = opts.delete(:single_threaded)
    datetime_class = opts.delete(:datetime_class)
    extensions = opts.delete(:extensions) || []
    timeout = opts.delete(:timeout)

    Sequel.database_timezone = database_timezone
    Sequel.application_timezone = application_timezone
    Sequel.typecast_timezone = typecast_timezone
    Sequel.single_threaded = single_threaded
    Sequel.convert_two_digit_years = convert_two_digit_years if convert_two_digit_years
    Sequel.datetime_class = datetime_class

    connection = Sequel.connect(conn_opts)

    if opts[:fibered]
      Sequel.extension :fiber_concurrency
    end

    if opts[:logger]
      connection.logger = opts[:logger]
    end

    if opts[:sql_log_level]
      connection.sql_log_level = opts[:sql_log_level]
    end

    Timeout::timeout(timeout) do
      loop do
        begin
          connection.test_connection
          break
        rescue => e
          puts("Unable to establish DB connection: #{conn_opts.inspect}")
          puts(e.inspect)
          sleep(1)
        end
      end
    end

    extensions.each { connection.extension(_1) }
    connections.add(connection)

    dataset_class = connection.dataset_class
    klass = Class.new(dataset_class)
    klass.extend(ReeDao::DatasetExtensions)

    connection.dataset_class = klass

    connection
  rescue => e
    connection&.disconnect
    raise e
  end
end