require 'test_helper'

class ContactsControllerTest < ActionController::TestCase
  
  context 'ContactsController' do
    context 'GET check_email' do
      should 'return with valid MGI accession id' do
        get :check_email, :mgi_accession_id => 'MGI:105369'
        assert_response :success
      end
    end    
    
    context 'GET search_email' do
      should 'return new contact action if email is unknown' do 
        gene = Factory.create(:gene)
        get :search_email, :mgi_accession_id => gene.mgi_accession_id, :email => 'unknown@unknown.com'
        assert_response :success, response.body
        
      end
      should 'return new notification action if email is known' do 
        contact = Factory.create(:contact)
        gene = Factory.create(:gene)
        get :search_email, :mgi_accession_id => gene.mgi_accession_id, :email => contact.email
        assert_redirected_to new_notification_path(:mgi_accession_id => gene.mgi_accession_id, :email => contact.email)
      end
    end
    
    context 'DELETE destroy' do
      should 'work' do
        contact = Factory.create :contact
        assert_difference('Contact.count', -1) do
          delete( :destroy, :id => contact.id, :format => :json )
        end
      end
    end
    
    context 'GET show' do
      
      should 'find valid one' do
        contact = Contact.find(Factory.create(:contact))
        params = Hash.new
        params[:id] = contact.id
        params[:mgi_accession_id] = Factory.create(:gene).mgi_accession_id
        
        get :show, params, :format => :json
        
        assert response.success?
        #assert_equal JSON.parse(response.body), contact.as_json
      end

    end
    
    
  end
end
