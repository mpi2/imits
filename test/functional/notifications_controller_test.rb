require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase
  
  context 'NotificationsController' do
    
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
