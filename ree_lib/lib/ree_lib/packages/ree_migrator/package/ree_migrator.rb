# frozen_string_literal: true

require 'sequel'
require 'ostruct'

module ReeMigrator
  include Ree::PackageDSL

  package do
    depends_on :ree_object
    depends_on :ree_datetime
    depends_on :ree_date
    depends_on :ree_logger
    depends_on :ree_array
  end
end