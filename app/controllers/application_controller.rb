class ApplicationController < ActionController::Base
  protect_from_forgery

  after_filter :log_json_response_parameters

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
        if filter['property'].match(/\_in/) and !filter['value'].is_a?(Array)
          filter['value'] = filter['value'].lines.map(&:strip)
        end
        dirty_params.merge!({ filter['property'] => filter['value'] })
      end
      dirty_params.delete('filter')
    end

    new_params = dirty_params.delete_if {|k| ['controller', 'action', 'format', 'page', 'per_page', 'utf8', '_dc'].include? k }
    return new_params
  end
  protected :params_cleaned_for_search

  def json_format_extended_response(data, total)
    data = [data] unless data.kind_of? Array
    data = data.as_json

    retval = {
      controller_name => data,
      'success' => true,
      'total' => total
    }
    return retval
  end
  protected :json_format_extended_response

  def data_for_serialized(format, default_sort, model_class, search_method)
    params[:sorts] = default_sort if(params[:sorts].blank?)
    params.delete(:per_page) if params[:per_page].blank? or params[:per_page].to_i == 0

    result = model_class.send(search_method, params_cleaned_for_search(params)).result
    retval = result.paginate(:page => params[:page], :per_page => params[:per_page] || 20)

    if format == :json and params[:extended_response].to_s == 'true'
      return json_format_extended_response(retval, result.count)
    else
      return retval
    end
  end
  protected :data_for_serialized

  def log_json_response_parameters
    if request.format == :json
      logger.info("  Response: #{response.body}")
    end
  end
  protected :log_json_response_parameters

  def send_data_csv(filename, csv_data)
    response.headers['Content-Length'] = csv_data.size.to_s
    send_data(
      csv_data,
      :type     => 'text/csv; charset=utf-8; header=present',
      :filename => filename
    )
  end
  protected :send_data_csv

  def format_languishing_report(report, params = {})
    group_type = params.fetch(:group_type)
    details_controller = params.fetch(:details_controller)
    details_action = params.fetch(:details_action)

    report.each do |group_name, group|
      group.each do |record|
        Reports::MiProduction::Languishing::DELAY_BINS.each_with_index do |bin, idx|
          if record[bin] == 0
            link = '&nbsp;'.html_safe
          else
            link = '<a href="' + url_for(:controller => details_controller,
              :action => details_action,
              group_type => group_name,
              :status => record[0],
              :delay_bin => bin,
              :only_path => true) + '">' + record[bin].to_s + '</a>'
          end
          css_classes = ['center', record[0].gsub(/[- ]+/, '_').downcase, "bin#{idx}"]
          record[bin] = "<div class=\"#{css_classes.join ' '}\">#{link}</div>".html_safe
        end
      end

      {
        'Micro-injection in progress' => 'Mouse production attempt',
        'Phenotype Attempt Registered' => 'Intent to phenotype'
      }.each do |from, to|
        row = group.find {|r| r[0] == from}
        row[0] = to
      end
    end
  end
  protected :format_languishing_report

end
