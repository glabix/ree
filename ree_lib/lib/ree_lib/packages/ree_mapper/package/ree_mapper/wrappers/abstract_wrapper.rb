class ReeMapper::AbstractWrapper
  attr_reader :subject

  contract ReeMapper::Field => Any
  def initialize(field)
    @subject = field
  end

  private

  def truncate(str, limit = 180)
    @trancator ||= ReeString::Truncate.new
    @trancator.call(str, limit)
  end
end