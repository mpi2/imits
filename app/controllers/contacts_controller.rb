# encoding: utf-8

class ContactsController < ApplicationController
  respond_to :html, :only => [:new, :create, :show]
  def new
    @contact = Contact.new
  end
  
  def create
    @contact = Public::Contact.create(params[:contact])
    respond_with @contact
  end
  
  def destroy
    
  end
  
  def update
    
  end
  
  def show
    respond_with Public::Contact.find_by_id(params[:id])
  end
  
  def index
    
  end
  
  alias_method :public_contact_url, :contact_url
  helper do
    def public_contacts_path(*args); contacts_path(*args); end
      def public_contact_path(*args); contact_path(*args); end
  end
  
  
end
