# frozen_string_literal: true

require 'sequel'
require 'ostruct'

module ReeMigrator
  package do
    depends_on :ree_object
    depends_on :ree_datetime
  end
end