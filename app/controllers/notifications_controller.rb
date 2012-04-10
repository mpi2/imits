# encoding: utf-8

class NotificationsController < ApplicationController
  respond_to :html, :only => [:new, :create, :show, :edit]
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
  
  def register

    @contact = Contact.find_by_email(params[:email])
    @gene = Gene.find_by_mgi_accession_id(params[:mgi_accession_id])
    if @contact  
      if @gene
        notifications = Notification.where(:gene_id => @gene.id, :contact_id => @contact.id)
        if notifications.length > 0
          # duplicate notification
          flash[:notice] = "You have previously registered interest in this gene. Resending notification email."
          @notification = notifications.first
          
          if NotificationMailer.registration_confirmation(@notification).deliver
            @notification.update_attributes(:welcome_email_sent => Time.now)
            redirect_to @notification
          end
        else
          @notification = Notification.new
          @notification.gene = @gene
          @notification.contact = @contact
        end
      else
        # error : gene not found
      end
    else 
      if @gene
        @contact = Contact.new(:email => params[:email])
        @notification = Notification.new
        @notification.gene = @gene
        @notification.contact = @contact
      else
        # error : gene not found
      end   
    end
    
    if @contact.save && @notification.save
      if NotificationMailer.registration_confirmation(@notification).deliver
        @notification.welcome_email_sent = Time.now.utc
        @notification.save!
        flash[:notice] = "Successfully created contact and registered for email notification."
        redirect_to notification_path(@notification, {:mgi_accession_id => @gene.mgi_accession_id, :email => @contact.email})
      end

    end
  end
  
  def unregister
    @contact = Contact.find_by_email(params[:email])
    @gene = Gene.find_by_mgi_accession_id(params[:mgi_accession_id])
    if @contact && @gene
      this_notification = Notification.where(:contact_id => @contact.id, :gene_id => @gene.id)
      this_notification.destroy!
    else
      flash[:notice] = "Notification cannot be found."
    end
    
  end
 
end
