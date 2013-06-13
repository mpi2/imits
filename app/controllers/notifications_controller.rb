# encoding: utf-8

class NotificationsController < ApplicationController

  respond_to :json, :only => [:create, :delete]

  before_filter :authenticate_user!
  before_filter :remote_access_allowed!

  def create
    if params[:contact] && params[:gene]

      @notification = Notification.new(:contact_email => params[:contact][:email], :gene_mgi_accession_id => params[:gene][:mgi_accession_id])

      if @notification.save

        if params[:contact][:immediate]
          mailer = NotificationMailer.welcome_email(@notification)
          mailer.deliver
        end

        render :json => {:success => true}, :status => :success
      else
        render :json => {:success => false, :errors => @notification.errors.full_messages}, :status => :not_acceptable
      end
    else
      render :json => {:success =>  false, :errors => ["No parameters provided :: Gene MGI Accession ID and Contact Email Address and Mode must be supplied."]}, :status => :not_acceptable
    end
  end

  def destroy
    if params[:contact] && params[:gene]
      @notification = Notification.search(:contact_email_ci_eq => params[:contact][:email], :gene_mgi_accession_id_ci_eq => params[:gene][:mgi_accession_id]).result.first

      if @notification
        @notification.destroy
        render :json => {:success => true}, :status => :success
      else
        render :json => {:success => true, :errors => ["Notification not found"]}, status: :unprocessable_entity
      end
    else
      render :json => {:success =>  false, :errors => ["No parameters provided :: Gene MGI Accession ID and Contact Email Address must be supplied."]}, :status => :not_acceptable
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
