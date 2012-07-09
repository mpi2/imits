# encoding: utf-8

class NotificationsController < ApplicationController

  respond_to :json, :only => [:create, :delete]

  before_filter :authenticate_user!
  before_filter :remote_access_allowed!

  def create

    @contact = Contact.where(:email => params[:contact][:email]).first
    if !@contact
      @contact = Contact.new(params[:contact])
      @contact.save!
    end

    @gene = Gene.where(:mgi_accession_id => params[:gene][:mgi_accession_id]).first

    if @gene && @contact
      notifications = Notification.where(:gene_id => @gene.id, :contact_id => @contact.id)
      if notifications.length == 0

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
        else
          render json: {success: false, errors: ["Notification could not be created"]}, status: :unprocessable_entity
        end

      else
        render json: {success: false, errors: ["Already registered for this contact and gene"]}, status: :not_acceptable
      end

    else
      if @gene.nil?
        render json: {success: false, errors: ["Gene not found :: Gene is nil"]}, status: :unprocessable_entity
      elsif @contact.nil?
        render json: {success: false, errors: ["Contact not found or could not be created :: Contact is nil"]}, status: :unprocessable_entity
      elsif @gene.nil? && @contact.nil?
        render json: {success: false, errors: ["No parameters provided :: Both Gene and Contact are nil"]}, status: :not_acceptable
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

  def remote_access_allowed!
    if current_user.remote_access?
      return true
    else
      render json: {success: false, errors: ["Login Failed :: Remote access denied for user"]}, status: :unauthorized
      return false
    end
  end

end
