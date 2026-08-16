class ReeMapper::AbstractWrapper
  attr_reader :subject

  contract ReeMapper::Field => Any
  def initialize(field)
    @subject = field
  end

  # See ReeMapper::AbstractType#db_load_trusted_check. Wrappers always cast.
  def db_load_trusted_check(var)
    nil
  end

  private

  def truncate(str, limit = 180)
    @trancator ||= ReeString::Truncate.new
    @trancator.call(str, limit)
  end
end