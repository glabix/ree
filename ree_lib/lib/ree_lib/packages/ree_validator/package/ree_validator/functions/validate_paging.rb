# frozen_string_literal: true

class ReeValidator::ValidatePaging
  include Ree::FnDSL

  fn :validate_paging do
    link :t, from: :ree_i18n

    def_error(:invalid_param) { MinPageErr }
    def_error(:invalid_param) { MinPerPageErr }
    def_error(:invalid_param) { MaxPerPageErr }
    def_error(:invalid_param) { MaxResultWindowErr }
  end

  contract(
    Kwargs[
      page: Integer,
      per_page: Integer,
      min_per_page: Integer,
      max_per_page: Integer,
    ],
    Ksplat[
      max_result_window?: Integer
    ] => Bool
  ).throws(MinPageErr, MinPerPageErr, MaxPerPageErr, MaxResultWindowErr)
  def call(page:, per_page:, min_per_page:, max_per_page:, **opts)
    if page < 1
      raise MinPageErr.new(
        t('validator.paging.min_page', default_by_locale: :en),
        :page
      )
    end

    if per_page < min_per_page
      raise MinPerPageErr.new(
        t('validator.paging.min_per_page', {min_per_page: min_per_page}, default_by_locale: :en),
        :min_per_page
      )
    end

    if per_page > max_per_page
      raise MaxPerPageErr.new(
        t('validator.paging.max_per_page', {max_per_page: max_per_page}, default_by_locale: :en),
        :max_per_page
      )
    end

    max_result_window = opts[:max_result_window]
    
    if max_result_window && page * per_page > max_result_window
      raise MaxResultWindowErr.new(
        t('validator.paging.max_result_window', {max_result_window: max_result_window}, default_by_locale: :en),
        :max_result_window
      )
    end

    true
  end
end