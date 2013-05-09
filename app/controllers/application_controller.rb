class ApplicationController < ActionController::Base
  protect_from_forgery

  clear_helpers
  helper :application, :notification_mailer

  after_filter :log_json_response_parameters

  rescue_from Exception, :with => :custom_json_exception_handler

  after_filter :store_location

  def store_location
    # store last url as long as it isn't a /users path
    session[:previous_url] = request.fullpath unless request.fullpath =~ /\/users/
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

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

  def params_cleaned_for_sort(sorts)
    return sorts
  end
  protected :params_cleaned_for_sort

  def json_format_extended_response(data, total)
    # This fails with ActiveRecord::Relation
    #data = [data] unless data.kind_of? Array
    data = data.as_json

    retval = {
      controller_path.gsub('/', '_') => data,
      'success' => true,
      'total' => total
    }
    return retval
  end
  protected :json_format_extended_response

  def data_for_serialized(format, default_sort, model_class, search_method, select_distinct)

    params[:sorts] = default_sort if(params[:sorts].blank?)
    params.delete(:per_page) if params[:per_page].blank? or params[:per_page].to_i == 0

    result = model_class.send(search_method, params_cleaned_for_search(params)).result(:distinct => select_distinct)
    result = result.order(params_cleaned_for_sort(params[:sorts])) if params[:sorts]
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

  def authorize_admin_user!
    if current_user.try(:admin?) != true

      respond_to do |format|
        format.html do
          flash[:alert] = 'Access to restricted area detected - this incident has been logged'
          redirect_to root_path
        end

        format.json do
          render :json => {'error' => 'Access to restricted area detected - this incident has been logged' }
        end
      end

      Rails.logger.info 'Unauthorized access detected'
    end
  end
  protected :authorize_admin_user!

  def custom_json_exception_handler(exception)
    if request.format == :json
      error_json = {
        'error' => exception.class.name,
        'message' => exception.message
      }
      unless exception.kind_of? ApplicationModel::ValidationError
        error_json['backtrace'] = exception.backtrace.join("\n")
      end
      render :json => error_json.to_json, :status => :internal_server_error
      Rails.logger.error "#{exception.class.name}: #{exception.message}\n#{exception.backtrace.join("\n")}"
    else
      raise exception
    end
  end
  protected :custom_json_exception_handler

  def set_centres_and_consortia
    @centres = Centre.all
    @consortia = Consortium.all
  end
  protected :set_centres_and_consortia

  def create_attribute_documentation_for(klass)
    {
      'readable' => klass.const_get(:READABLE_ATTRIBUTES),
      'writable' => klass.const_get(:WRITABLE_ATTRIBUTES)
    }
  end
  protected :create_attribute_documentation_for

  def authorize_user_production_centre(object)
    return true unless request.format == :json

    if object.production_centre_name.present?
      production_centre_name = object.production_centre_name
    elsif object.mi_plan.present? and object.mi_plan.production_centre.present?
      production_centre_name = object.mi_plan.production_centre.name
    else
      return true
    end

    if current_user.production_centre.name != production_centre_name && !current_user.admin
      render :json => {
        'error' => 'Cannot create/update data for other production centres'
      }, :status => 401
      return false
    end

    return true
  end
  protected :authorize_user_production_centre

end
