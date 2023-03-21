class ReeMapper::AbstractWrapper
  attr_reader :subject

  contract ReeMapper::Field => Any
  def initialize(field)
    @subject = field
  end
end