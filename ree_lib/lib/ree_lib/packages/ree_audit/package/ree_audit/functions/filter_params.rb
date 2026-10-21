# frozen_string_literal: true

require "json"

class ReeAudit::FilterParams
  include Ree::FnDSL

  fn :filter_params do
    link :config
  end

  FILTERED = 'FILTERED'
  TRUNCATED_DEPTH = '[TRUNCATED_DEPTH]'

  doc(<<~DOC)
    Strips secrets out of request params before they reach an audit sink.

    Unlike the logger filter, which only looks at top level keys, this one walks
    the whole structure: a token nested three levels deep is still a token.
    Two more limits keep a single event from becoming a payload dump — maximum
    nesting depth and maximum serialized size.
  DOC
  contract(Hash => Hash)
  def call(params)
    filtered = filter_value(
      params, 1, config.filter_words, config.max_params_depth
    )

    limit_size(filtered, config.max_params_bytes)
  end

  private

  def filter_value(value, depth, filter_words, max_depth)
    case value
    when Hash
      return TRUNCATED_DEPTH if depth > max_depth

      value.each_with_object({}) do |(key, nested), result|
        result[key] = if filtered_key?(key, filter_words)
          FILTERED
        else
          filter_value(nested, depth + 1, filter_words, max_depth)
        end
      end
    when Array
      return TRUNCATED_DEPTH if depth > max_depth

      value.map { filter_value(_1, depth + 1, filter_words, max_depth) }
    else
      value
    end
  end

  def filtered_key?(key, filter_words)
    name = key.to_s.downcase
    filter_words.any? { name.include?(_1) }
  end

  def limit_size(params, max_bytes)
    size = json_bytesize(params)

    return params if size.nil? || size <= max_bytes

    { truncated: true, size: size }
  end

  # A payload we cannot serialize is a payload we cannot measure; dropping the
  # size limit is better than dropping the whole request.
  def json_bytesize(params)
    JSON.generate(params).bytesize
  rescue StandardError
    nil
  end
end
