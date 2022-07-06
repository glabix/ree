# frozen_string_literal: true

require "concurrent/map"

class ReeObject::IsBlank
  include Ree::FnDSL

  fn :is_blank 

  BLANK_RE = /\A[[:space:]]*\z/

  ENCODED_BLANKS = Concurrent::Map.new do |h, enc|
    h[enc] = Regexp.new(BLANK_RE.source.encode(enc), BLANK_RE.options | Regexp::FIXEDENCODING)
  end

  doc(<<~DOC)
    An object is blank if it's false, empty, or a whitespace string.
    For example, +nil+, '', '   ', [], {}, and +false+ are all blank.
  DOC
  contract(Any => Bool)
  def call(obj)
    return is_string_blank?(obj) if obj.is_a?(String)
    return obj.empty? if obj.is_a?(Array) || obj.is_a?(Hash)
    return true if obj.nil?
    return true if obj == false
    return false if obj == true
    false
  end

  private

  def is_string_blank?(str)
    str.empty? ||
      begin
        BLANK_RE.match?(str)
      rescue Encoding::CompatibilityError
        ENCODED_BLANKS[str.encoding].match?(str)
      end
  end
end