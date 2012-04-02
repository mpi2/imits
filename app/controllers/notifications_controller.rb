# encoding: utf-8

class NotificationsController < ApplicationController
  respond_to :html, :only => [:new, :create, :show, :edit]
  def new
    @contact = Contact.find_by_email(params[:email])
    @gene = Gene.find_by_mgi_accession_id(params[:mgi_accession_id])
    notifications = Notification.where(:gene_id => @gene.id, :contact_id => @contact.id)
    if notifications.length > 0
      flash[:notice] = "You have previously registered interest in this gene. Resending notification email."
      @notification = notifications.first
      if NotificationMailer.registration_confirmation(@notification).deliver
        @notification.update_attributes(:welcome_email_sent => Time.now)
      end
      redirect_to @notification
    else
      @notification = Notification.new
    end
  end
  
  def create
    @contact = Contact.find(params[:notification][:contact_id])
    
    @gene = Gene.find(params[:notification][:gene_id])
    @notification = Notification.new
    @notification.gene = @gene
    @notification.contact = @contact
    
    respond_to do |format|  
      if @notification.save  
        if NotificationMailer.registration_confirmation(@notification).deliver  
          @notification.welcome_email_sent = Time.now
          @notification.save
        end
        format.html { redirect_to(@notification, :notice => 'Notification was successfully created.') }  
      else  
        format.html { render :action => "new" }  
      end  
    end 
  end
  
  def destroy
    
  end
  
  def update

  end
  
  def show
    @notification = Notification.find_by_id(params[:id])
    @gene = Gene.find(@notification.gene_id)
    @contact = Contact.find(@notification.contact_id)
  end
  
  def index
    
  end
    
end
