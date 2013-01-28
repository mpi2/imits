class Admin::NotificationsController < Admin::BaseController

  def index

    @notifications = Notification.order('updated_at desc')

    respond_to do |format|
      format.html
      format.json { render :json => @notifications.to_json(:methods => [:contact_email, :gene_marker_symbol])}
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

  def retry
    @notification = Notification.find(params[:id])
    @notification.retry!
    render :nothing => true
  end

end