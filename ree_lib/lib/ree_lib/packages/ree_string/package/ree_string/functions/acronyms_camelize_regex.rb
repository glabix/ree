# frozen_string_literal: true

class ReeString::AcronymsCamelizeRegex
  include Ree::FnDSL

  fn :acronyms_camelize_regex

  contract(ArrayOf[String] => Regexp)
  def call(acronyms)
    acronym_regex = acronyms.empty? ? /(?=a)b/ : /#{acronyms.join("|")}/
    /^(?:#{acronym_regex}(?=\b|[A-Z_])|\w)/
  end
end