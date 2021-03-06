# frozen_string_literal: true

module ReeHttp
  module HttpExceptions
    RedirectError = Class.new(StandardError)
    TooManyRedirectsError = Class.new(RedirectError)
    RedirectMethodError = Class.new(RedirectError)
  end
end
