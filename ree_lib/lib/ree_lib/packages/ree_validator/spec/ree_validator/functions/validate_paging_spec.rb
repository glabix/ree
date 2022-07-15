# frozen_string_literal: true

package_require('ree_validator/functions/validate_paging')
package_require('ree_i18n/functions/add_load_path')

ReeI18n::AddLoadPath.new.call(
  Dir[File.join(__dir__, 'locales/*.yml')]
)

RSpec.describe ReeValidator::ValidatePaging do
  link :validate_paging, from: :ree_validator
  link :set_locale, from: :ree_i18n

  context "ru locale" do
    before :each do
      set_locale(:fr)
    end

    it {
      expect {
        validate_paging(page: -1, per_page: 10, min_per_page: 10, max_per_page: 20)
      }.to raise_error(ReeValidator::ValidatePaging::PagingErr, 'min page 1')
    }

    it {
      expect {
        validate_paging(page: 1, per_page: 9, min_per_page: 10, max_per_page: 20)
      }.to raise_error(ReeValidator::ValidatePaging::PagingErr, "per_page should be >= 10")
    }

    it {
      expect {
        validate_paging(page: 1, per_page: 21, min_per_page: 10, max_per_page: 20)
      }.to raise_error(ReeValidator::ValidatePaging::PagingErr, "per_page should be <= 20")
    }

    it {
      expect {
        validate_paging(page: 5, per_page: 10, min_per_page: 10, max_per_page: 20, max_result_window: 42)
      }.to raise_error(ReeValidator::ValidatePaging::PagingErr, "product of page and per_page should be <= 42")
    }
  end

  context "en locale" do
    before :each do
      set_locale(:en)
    end

    it {
      expect {
        validate_paging(page: -1, per_page: 10, min_per_page: 10, max_per_page: 20)
      }.to raise_error(ReeValidator::ValidatePaging::PagingErr, 'page should be more than 1')
    }

    it {
      expect {
        validate_paging(page: 1, per_page: 9, min_per_page: 10, max_per_page: 20)
      }.to raise_error(ReeValidator::ValidatePaging::PagingErr, "per_page should be >= 10")
    }

    it {
      expect {
        validate_paging(page: 1, per_page: 21, min_per_page: 10, max_per_page: 20)
      }.to raise_error(ReeValidator::ValidatePaging::PagingErr, "per_page should be <= 20")
    }

    it {
      expect {
        validate_paging(page: 5, per_page: 10, min_per_page: 10, max_per_page: 20, max_result_window: 42)
      }.to raise_error(ReeValidator::ValidatePaging::PagingErr, "product of page and per_page should be <= 42")
    }
  end
end
