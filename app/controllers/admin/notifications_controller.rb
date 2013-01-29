class Admin::NotificationsController < Admin::BaseController

  def index

    respond_to do |format|
      format.html
      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def show
    @notification = Notification.find(params[:id])
    
    respond_to do |format|
      format.json {
        render :json => @notification.to_json(:only => [:id], :methods => [:last_email, :welcome_email])
      }
    end
  end

  def create
    @notification = Notification.new(params[:admin_notification])

    if @notification.save
      render :json => @notification.to_json      
    else
      render :json => {'error' => @notification.errors.full_messages.join("\n")}, :status => 422
    end
  end

  def retry
    @notification = Notification.find(params[:id])
    @notification.retry!
    render :nothing => true
  end

  def params_cleaned_for_sort(sorts)
    sorts.gsub!(/contact_email/, "contacts.email")
    sorts.gsub!(/gene_marker_symbol/, "genes.marker_symbol")

    sorts
  end

  def data_for_serialized(format)
    super(format, 'updated_at desc', Notification, :search)
  end
  protected :data_for_serialized

  ## Override to add as_json options. See ApplicationController for overidden method.
  def json_format_extended_response(data, total)
    data = [data] unless data.kind_of? Array
    data = data.as_json(:methods => [:contact_email, :gene_marker_symbol])

    retval = {
      controller_path.gsub('/', '_') => data,
      'success' => true,
      'total' => total
    }
    return retval
  end
  protected :json_format_extended_response

end