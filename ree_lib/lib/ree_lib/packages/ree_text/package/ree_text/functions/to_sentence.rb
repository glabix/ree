# frozen_string_literal: true

class ReeText::ToSentence
  include Ree::FnDSL

  fn :to_sentence do
    link :safe_join
    link :escape_html
    link :t, from: :ree_i18n
  end

  DEFAULTS = {
    locale: :en
  }

  DEFAULT_CONNECTORS = {
    words_connector: ", ",
    two_words_connector: " and ",
    last_word_connector: ", and "
  }

  doc(<<~DOC)
    Converts the array to a comma-separated sentence where the last element is
    joined by the connector word.

      to_sentence(["one", "two", "three"])                                      # => "one, two, and three"
      to_sentence(["one", "two", "three"], words_connector: " "))               # => "one two, and three"
      to_sentence(["one", "two", "three"], last_word_connector: ", and also ")  # =>"one, two, and also three"
      to_sentence(["one", "two"], two_words_connector: " & ")                   # => "one &amp; two"
  DOC
  
  contract(
    Array,
    Kwargs[
      locale: Symbol
    ],
    Ksplat[
      words_connector?: String,
      two_words_connector?: String,
      last_word_connector?: String
    ] => String
  )
  def call(array, locale: nil, **opts)
    locale = locale || DEFAULTS[:locale]

    i18n_connectors = t("sentence", locale: locale)
    DEFAULT_CONNECTORS.merge(i18n_connectors)
    options  = DEFAULT_CONNECTORS.merge(opts)

    case array.length
    when 0
      ""
    when 1
      escape_html(array[0])
    when 2
      safe_join([array[0], array[1]], sep: options[:two_words_connector])
    else
      safe_join(
        [
          safe_join(
            array[0...-1], 
            sep: options[:words_connector]
          ), 
          options[:last_word_connector], 
          array[-1]
        ], 
        sep: ""
      )
    end
  end
end