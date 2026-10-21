class ReeMapper::AbstractType
  # Ruby expression (as source string) checking that `var` already holds a
  # correctly-typed DB value, so db_load may return it as-is. Types that
  # cannot be skipped (custom types, enums, pg wrappers) return nil. The
  # expression must accept exactly the values for which this type's db_load
  # is an identity, or db_load semantics change in performance mode.
  def db_load_trusted_check(var)
    nil
  end

  private

  def truncate(str, limit = 180)
    @truncate ||= ReeString::Truncate.new
    @truncate.(str, limit)
  end
end
