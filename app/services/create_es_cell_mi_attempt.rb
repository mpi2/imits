# encoding: utf-8
class CreateEsCellMiAttempt


  def initialize(form)
  	raise 'Please provide form' if form.blank?
  	@form = form
  end

end
