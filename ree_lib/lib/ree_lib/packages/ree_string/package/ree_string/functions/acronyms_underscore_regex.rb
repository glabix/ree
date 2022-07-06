# frozen_string_literal: true

class ReeString::AcronymsUnderscoreRegex
  include Ree::FnDSL

  fn :acronyms_underscore_regex

  contract(ArrayOf[String] => Regexp)
  def call(acronyms)
    acronym_regex = acronyms.empty? ? /(?=a)b/ : /#{acronyms.join("|")}/
    /(?:(?<=([A-Za-z\d]))|\b)(#{acronym_regex})(?=\b|[^a-z])/
  end
end