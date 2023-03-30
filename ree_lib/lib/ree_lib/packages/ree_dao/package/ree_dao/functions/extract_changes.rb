# frozen_string_literal: true

class ReeDao::ExtractChanges
  include Ree::FnDSL

  fn :extract_changes do
    link :dao_cache, as: :__ree_dao_cache
  end

  contract(Symbol, Any, Hash => Hash)
  def call(table_name, primary_key, hash)
    cached = __ree_dao_cache.get(table_name, primary_key)
    return hash unless cached
    changes = {}

    hash.each do |column, value|
      previous_column_value = cached[column]

      if cached.has_key?(column) && previous_column_value != value
        changes[column] = value
      end
    end

    changes
  end
end