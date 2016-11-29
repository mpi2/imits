# encoding: utf-8
class CreateMiPlan


  def initialize(form)
  	raise 'Please provide form' if form.blank?
  	@form = form
  end

end
