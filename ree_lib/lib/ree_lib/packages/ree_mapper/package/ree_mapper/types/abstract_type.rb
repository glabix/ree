class ReeMapper::AbstractType
  private

  def truncate(str, limit = 180)
    @trancator ||= ReeString::Truncate.new
    @trancator.call(str, limit)
  end
end
