# frozen_string_literal: true

class ReeString::Camelize
  include Ree::FnDSL

  fn :camelize do
    link :acronyms_camelize_regex
  end

  doc(<<~DOC)
    Converts strings to UpperCamelCase.
    If the +uppercase_first_letter+ parameter is set to false, then produces
    lowerCamelCase.
    
    Also converts '/' to '::' which is useful for converting
    paths to namespaces.
    
      camelize('active_model')                # => "ActiveModel"
      camelize('active_model', false)         # => "activeModel"
      camelize('active_model/errors')         # => "ActiveModel::Errors"
      camelize('active_model/errors', false)  # => "activeModel::Errors"
    
    As a rule of thumb you can think of +camelize+ as the inverse of
    #underscore, though there are cases where that does not hold:
    
      camelize(underscore('SSLError'))        # => "SslError"
  DOC
  contract(
    String,
    Ksplat[
      uppercase_first_letter?: Bool,
      acronyms?: HashOf[String, String]
    ] => String
  )
  def call(str, **opts)
    str = str.dup
    uppercase_first_letter = opts.has_key?(:uppercase_first_letter) ? opts[:uppercase_first_letter] : true
    acronyms = opts[:acronyms] || {}
    regex = acronyms_camelize_regex(acronyms.values)

    if !uppercase_first_letter
      str = str.sub(regex) { |match| match.downcase! || match }
    else
      str = str.sub(/^[a-z\d]*/) { |match| acronyms[match] || match.capitalize! || match }
    end

    str.gsub!(/(?:_|(\/))([a-z\d]*)/i) do
      word = $2
      substituted = acronyms[word] || word.capitalize! || word
      $1 ? "::#{substituted}" : substituted
    end

    str
  end
end