class ReeMapper::AbstractType
  private

  def truncate(str, limit = 180)
    @truncate ||= ReeString::Truncate.new
    @truncate.(str, limit)
  end
end
