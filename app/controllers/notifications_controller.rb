# encoding: utf-8

class NotificationsController < ApplicationController

  respond_to :json, :only => [:create, :delete]

  before_filter :authenticate_user!
  before_filter :remote_access_allowed

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

        @notification = notifications.first

        if mailer = NotificationMailer.welcome_email(@notification)

          @notification.welcome_email_text = mailer.body
          @notification.welcome_email_sent = Time.now.utc
          @notification.save!
          mailer.deliver
          render :json => {}
        end
      else
        @notification = Notification.new
        @notification.gene = @gene
        @notification.contact = @contact


        if @notification.save!
          if mailer = NotificationMailer.welcome_email(@notification)

             @notification.welcome_email_text = mailer.body
             @notification.welcome_email_sent = Time.now.utc
             @notification.save!
             mailer.deliver
          end
          render :json => {}
        end

      end

    end
  end

  def delete
    @contact = Contact.where(:email => params[:contact][:email]).first
    @gene = Gene.where(:mgi_accession_id => params[:gene][:mgi_accession_id]).first

    if @gene && @contact
      notifications = Notification.where(:gene_id => @gene.id, :contact_id => @contact.id)
      if notifications.length > 0
        @notification = notifications.first
        @notification.destroy

        render :json => {}
      end
    end
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
