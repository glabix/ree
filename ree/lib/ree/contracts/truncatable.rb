# frozen_string_literal: true

module Ree::Contracts
  module Truncatable
    def truncate(str, limit = 80)
      str.length > limit ? "#{str[0..limit]}..." : str
    end
  end
end
