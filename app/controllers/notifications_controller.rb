# encoding: utf-8

require 'pp'

class NotificationsController < ApplicationController

  #  respond_to :json, :only => [:create, :delete, :show]
  respond_to :json, :only => [:create, :delete]

  before_filter :authenticate_user!
  before_filter :remote_access_allowed!

  #def show
  #  if params[:id]
  #    contact = Contact.find_by_email params[:id]
  #
  #    if ! contact
  #      render :json => {:success =>  false, :errors => ["Cannot find contact."]}, :status => :not_acceptable
  #    end
  #
  #    notifications = Notification.find_by_contact_id contact.id
  #
  #    render :json => { :notifications => notifications }, :status => :success
  #  else
  #    render :json => {:success =>  false, :errors => ["No parameters provided :: Email Address must be supplied."]}, :status => :not_acceptable
  #  end
  #end

  def create
    if params[:contact] && params[:gene]

      @notification = Notification.new(:contact_email => params[:contact][:email], :gene_mgi_accession_id => params[:gene][:mgi_accession_id])

      if @notification.save

        if params[:contact][:immediate]
          mailer = NotificationMailer.welcome_email(@notification)
          mailer.deliver if mailer
        end

        render :json => {:success => true}, :status => :success
      else
        render :json => {:success => false, :errors => @notification.errors.full_messages}, :status => :not_acceptable
      end
    else
      render :json => {:success =>  false, :errors => ["No parameters provided :: Gene MGI Accession ID and Contact Email Address must be supplied."]}, :status => :not_acceptable
    end
  end

  #def destroy_old
  #  if params[:contact] && params[:gene]
  #    @notification = Notification.search(:contact_email_ci_eq => params[:contact][:email], :gene_mgi_accession_id_ci_eq => params[:gene][:mgi_accession_id]).result.first
  #
  #    if @notification
  #      @notification.destroy
  #      render :json => {:success => true}, :status => :success
  #    else
  #      render :json => {:success => true, :errors => ["Notification not found"]}, status: :unprocessable_entity
  #    end
  #  else
  #    render :json => {:success =>  false, :errors => ["No parameters provided :: Gene MGI Accession ID and Contact Email Address must be supplied."]}, :status => :not_acceptable
  #  end
  #end

  def destroy
    if params[:contact] && params[:gene]
      #@notifications = Notification.search(:contact_email_ci_eq => params[:contact][:email],
      #  :gene_mgi_accession_id_ci_eq => params[:gene][:mgi_accession_id]).result

      #@notifications = Notification.join(:contacts, :genes).where(
      #  "contact.email ilike '#{params[:contact][:email]}' and gene.mgi_accession_id ilike '#{params[:gene][:mgi_accession_id]}'")



      #model = Product.find(:first, :conditions => [ "lower(name) = ?", name.downcase ])

      #contact = Contact.find_by_email params[:contact][:email]
      contact = Contact.find(:first, :conditions => [ "lower(email) = ?", params[:contact][:email].downcase ])

      #gene = Gene.find_by_mgi_accession_id params[:gene][:mgi_accession_id]
      gene = Gene.find(:first, :conditions => [ "lower(mgi_accession_id) = ?", params[:gene][:mgi_accession_id].downcase ] )

      @notifications = nil

      if contact && gene
        @notifications = Notification.where("contact_id = #{contact.id} and gene_id = #{gene.id}")
      end

      #puts "#### @notifications:"
      #pp @notifications
      #puts "#### @notifications.size:"
      #pp @notifications.size
      #
      #puts "#### params[:contact][:email]:"
      #pp params[:contact][:email]
      #puts "#### params[:gene][:mgi_accession_id]:"
      #pp params[:gene][:mgi_accession_id]

      if @notifications && @notifications.size > 0
        @notifications.destroy_all
        render :json => {:success => true}, :status => :success
      else
        render :json => {:success => true, :errors => ["Notification not found"]}, :status => :unprocessable_entity
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
      render :json => {:success => false, :errors => ["Login Failed :: Remote access denied for user"]}, :status => :unauthorized
      return false
    end
  end

end
