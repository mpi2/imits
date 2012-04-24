# encoding: utf-8

class NotificationsController < ApplicationController
  respond_to :html, :only => [:new, :create, :show, :edit]
  respond_to :json, :only => [:new, :create, :show, :edit]
  
  before_filter :authenticate_user!
  before_filter :remote_access_allowed
  
  def new
    @contact = Contact.find_by_email!(params[:email])
    @gene = Gene.find_by_mgi_accession_id!(params[:mgi_accession_id])
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
    
    @contact = Contact.where(:email => params[:contact][:email]).first
    if !@contact
      @contact = Contact.new(params[:contact])
      @contact.save!
    end
    
    @gene = Gene.where(:mgi_accession_id => params[:gene][:mgi_accession_id]).first
    
    if @gene && @contact
      notifications = Notification.where(:gene_id => @gene.id, :contact_id => @contact.id)
      if notifications.length > 0
        
        flash[:notice] = "You have previously registered interest in this gene. Resending notification email."
        @notification = notifications.first
          
        if mailer = NotificationMailer.welcome_email(@notification)
          logger.debug "RESENDING WELCOME EMAIL - NOTIFICATION EXISTS"
          logger.debug mailer.inspect
          @notification.welcome_email_text = mailer.body
          @notification.welcome_email_sent = Time.now.utc
          @notification.save!
          mailer.deliver
          respond_with @notification
        end
      else
        @notification = Notification.new
        @notification.gene = @gene
        @notification.contact = @contact
        
        
        if @notification.save!
          if mailer = NotificationMailer.welcome_email(@notification)
            logger.debug "SENDING WELCOME EMAIL"
            logger.debug mailer.inspect
             @notification.welcome_email_text = mailer.body
             @notification.welcome_email_sent = Time.now.utc
             @notification.save!
             mailer.deliver 
          end
            respond_with @notification
        end
       
      end
      
    end    
  end

  def destroy
    @notification = Notification.find(params[:id])
    @notification.destroy
    flash[:notice] = "Successfully destroyed notification."
    respond_with(@notification)
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

  private
  
  def remote_access_allowed
    if current_user.remote_access?
      return true
    else
      return false
    end
  end
 
end
