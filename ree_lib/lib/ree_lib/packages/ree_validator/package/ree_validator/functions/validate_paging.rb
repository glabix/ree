# frozen_string_literal: true

class ReeValidator::ValidatePaging
  include Ree::FnDSL

  fn :validate_paging do
    link :t, from: :ree_i18n
  end

  PagingErr = Class.new(StandardError)

  contract(
    Kwargs[
      page: Integer,
      per_page: Integer,
      min_per_page: Integer,
      max_per_page: Integer,
      error: Nilor[SubclassOf[StandardError]],
    ],
    Ksplat[
      max_result_window?: Integer
    ] => Bool
  ).throws(PagingErr)
  def call(page:, per_page:, min_per_page:, max_per_page:, error: nil, **opts)
    klass = error || PagingErr

    if page < 1
      raise klass.new(
        t('validator.paging.min_page', default_by_locale: :en)
      )
    end

    if per_page < min_per_page
      raise klass.new(
        t(
          'validator.paging.min_per_page',
          {min_per_page: min_per_page},
          default_by_locale: :en
        )
      )
    end

    if per_page > max_per_page
      raise klass.new(
        t(
          'validator.paging.max_per_page',
          {max_per_page: max_per_page},
          default_by_locale: :en
        )
      )
    end

    max_result_window = opts[:max_result_window]

    if max_result_window && page * per_page > max_result_window
      raise klass.new(
        t(
          'validator.paging.max_result_window',
          {max_result_window: max_result_window},
          default_by_locale: :en
        )
      )
    end

    true
  end
end