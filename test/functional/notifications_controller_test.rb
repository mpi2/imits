require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase
  
  context 'NotificationsController' do
    setup do
      centre = Centre.find_by_name!('WTSI')
      remote_user = Factory.create :user, {:email => 'gj2@sanger.ac.uk', :password => 'password', :production_centre => centre}
      sign_in remote_user
    end
      
    context 'POST create' do 
      should 'work' do
        gene = Factory.create(:gene_cbx1)
        contact = Factory.create(:contact)
        post(:create, {:mgi_accession_id => gene.mgi_accession_id, :email => contact.email} , :format => :json)
        
        notification = Notification.first
        raise notification.inspect
        assert_equal ActionMailer::Base.deliveries.last.to, contact.email
      end
    end
    
    context 'DELETE destroy' do
      should 'work' do
        notification = Factory.create :notification
        assert_difference('Notification.count', -1) do
          delete( :destroy, :id => notification.id, :format => :json )
        end
      end
    end
    
    context 'GET show' do
      
      should 'find valid one' do
        notification = Notification.find(Factory.create(:notification))
        get :show, :id => notification.id
        
        assert response.success?
      end

    end
    
    
  end
  
  
end
