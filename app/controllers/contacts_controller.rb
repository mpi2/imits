# encoding: utf-8

class ContactsController < ApplicationController
  respond_to :html, :only => [:new, :create, :show, :edit]
  respond_to :json, :only => [:new, :create, :show, :edit]
  
  before_filter :authenticate_user!
  
  def new
    @gene = Gene.find_by_mgi_accession_id(params[:mgi_accession_id])
    @contact = Contact.find_by_email(params[:email]) || Contact.new

  end

  def create
    @contact = Contact.new(params[:contact])
    @gene = Gene.find(params[:contact][:notification][:gene_id])

    if @contact.save
      flash[:notice] = "Successfully created contact."
      redirect_to register_notification_path(@contact, {:mgi_accession_id => @gene.mgi_accession_id, :email => @contact.email})
    end

  end

  def destroy
    @contact = Contact.find(params[:id])
    @contact.destroy
    flash[:notice] = "Successfully destroyed contact."
    respond_with(@contact)
  end

  def update
    @contact = Contact.find(params[:id])
    if @contact.update_attributes(params[:contact])
      flash[:notice] = "Successfully updated contact details."
    end
    respond_with(@contact)
  end

  def show
    @contact = Contact.find_by_id!(params[:id])
    @gene = Gene.find_by_mgi_accession_id!(params[:mgi_accession_id])
    respond_with(@contact)
  end

  def index

  end

end
