# frozen_string_literal: true

class Ree::StringUtils
  class << self
    def truncate(str, limit = 80)
      str.length > limit ? "#{str[0..limit]}..." : str
    end

    def underscore(camel_cased_word)
      return camel_cased_word unless /[A-Z-]|::/.match?(camel_cased_word)
      word = camel_cased_word.to_s.gsub("::".freeze, "/".freeze)
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2'.freeze)
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2'.freeze)
      word.tr!("-".freeze, "_".freeze)
      word.downcase!
      word
    end

    def camelize(string, uppercase_first_letter = true)
      if uppercase_first_letter
        string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
      else
        string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { |match| match.downcase }
      end

      string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub("/", "::")
    end
  end
end