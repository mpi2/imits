class Admin::ContactsController < Admin::BaseController

  respond_to :json

  def index
    respond_to do |format|
      format.html
      format.json { render :json => data_for_serialized(:json).to_json(:methods => [:contact_email, :gene_marker_symbol])}
    end
  end

  def create
    @contact = Contact.new(params[:admin_contact])

    if @contact.save
      respond_with @contact
    else
      render :json => {'error' => 'Could not create contact (invalid data)'}, :status => 422
    end
  end

  def update
    find_contact

    if @contact.update_attributes(params[:admin_contact])
      respond_with @contact
    else
      render :json => {'error' => 'Could not update contact (invalid data)'}, :status => 422
    end
  end

  def destroy
    find_contact
    @contact.destroy
    render :nothing => true
  end

  def data_for_serialized(format)
    super(format, 'id asc', Contact, :search)
  end
  protected :data_for_serialized

  def find_contact
    @contact = Contact.find(params[:id])
  end
  protected :find_contact

end