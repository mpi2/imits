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
        assert_difference('Notification.count') do
         post(:create, :gene => {:mgi_accession_id => gene.mgi_accession_id}, :contact =>{:email => contact.email}, :format => :json)
        end
        
        notification = Notification.last
        assert_equal notification.gene, gene
        assert_equal notification.contact, contact
        assert_equal ActionMailer::Base.deliveries.last.to.first, contact.email
      end
    end
    
    context 'DELETE delete' do
      should 'work' do
        
        gene = Factory.create(:gene_cbx1)
        contact = Factory.create(:contact)
        
        notification = Factory.create :notification, {:gene => gene, :contact => contact}
        assert_difference('Notification.count', -1) do
          delete( :delete, :gene => {:mgi_accession_id => gene.mgi_accession_id}, :contact =>{:email => contact.email}, :format => :json )
        end        
      end
    end
    
    
  end
  
  
end
