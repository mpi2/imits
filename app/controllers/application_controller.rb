class ApplicationController < ActionController::Base
  protect_from_forgery

  def params_cleaned_for_search(dirty_params)
    dirty_params = dirty_params.dup.stringify_keys
    if dirty_params['q']
      dirty_params['q'].stringify_keys!
      dirty_params.merge!(dirty_params['q'])
      dirty_params.delete('q')
    end
    new_params = dirty_params.delete_if {|k| ['controller', 'action', 'format', 'page', 'per_page', 'utf8', '_dc'].include? k }
    return new_params
  end
  protected :params_cleaned_for_search
end
