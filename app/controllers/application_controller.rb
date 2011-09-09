class ApplicationController < ActionController::Base
  protect_from_forgery

  def params_cleaned_for_search(dirty_params)
    dirty_params = dirty_params.dup.stringify_keys

    if dirty_params['q']
      dirty_params['q'].stringify_keys!
      dirty_params.merge!(dirty_params['q'])
      dirty_params.delete('q')
    end

    if dirty_params['filter']
      unless dirty_params['filter'].is_a? Array
        dirty_params['filter'] = JSON.parse(dirty_params['filter'])
      end

      dirty_params['filter'].each do |filter|
        if filter['value'].match("\n")
          filter['value'] = filter['value'].split("\n")
        end
        dirty_params.merge!({ filter['property'] => filter['value'] })
      end
      dirty_params.delete('filter')
    end

    new_params = dirty_params.delete_if {|k| ['controller', 'action', 'format', 'page', 'per_page', 'utf8', '_dc'].include? k }
    return new_params
  end
  protected :params_cleaned_for_search
end
