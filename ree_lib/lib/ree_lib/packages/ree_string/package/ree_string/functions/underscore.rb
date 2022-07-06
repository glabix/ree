# frozen_string_literal: true

class ReeString::Underscore
  include Ree::FnDSL

  fn :underscore do
    link :acronyms_underscore_regex
  end

  doc(<<~DOC)
    Makes an underscored, lowercase form from the expression in the string.
    
    Changes '::' to '/' to convert namespaces to paths.
    
      underscore('ActiveModel')               # => "active_model"
      underscore('ActiveModel::Errors')       # => "active_model/errors"
      underscore("NRIS", {acronyms: ['NRI']}) # => "nri_s"
    
    As a rule of thumb you can think of +underscore+ as the inverse of
    #camelize, though there are cases where that does not hold:
    
      camelize(underscore('SSLError'))  # => "SslError"
  DOC
  contract(
    String,
    Ksplat[
      acronyms?: ArrayOf[String]
    ] => String
  )
  def call(camel_cased_word, **opts)
    return camel_cased_word.to_s unless /[A-Z-]|::/.match?(camel_cased_word)

    acronyms = opts[:acronyms] || []
    regex = acronyms_underscore_regex(acronyms)

    word = camel_cased_word.to_s.gsub("::", "/")
    word.gsub!(regex) { "#{$1 && '_' }#{$2.downcase}" }
    word.gsub!(/([A-Z]+)(?=[A-Z][a-z])|([a-z\d])(?=[A-Z])/) { ($1 || $2) << "_" }
    word.tr!("-", "_")
    word.downcase!
    word
  end
end