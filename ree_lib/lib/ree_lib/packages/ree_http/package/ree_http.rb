# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'openssl'
require 'logger'

module ReeHttp
  include Ree::PackageDSL

  package do
    depends_on :ree_json
    depends_on :ree_hash
    depends_on :ree_object
  end

  class << self
    def logger
      @logger ||= begin
        logger = Logger.new(STDOUT)
        logger.level = Logger::WARN
        logger
      end
    end

    def logger=(logger)
      @logger = logger
    end
  end
end
