# encoding: utf-8
class CreateCrisprMiAttempt


  def initialize(form)
  	raise 'Please provide form' if form.blank?
  	@form = form
  end

end
