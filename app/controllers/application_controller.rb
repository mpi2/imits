class ApplicationController < ActionController::Base
  protect_from_forgery

  def cleaned_params
    new_params = params.dup.delete_if {|k| ['controller', 'action', 'format', 'page', 'utf8'].include? k }
    return new_params
  end
  protected :cleaned_params
end
