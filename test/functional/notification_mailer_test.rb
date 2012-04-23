require 'test_helper'

class NotificationMailerTest < ActionMailer::TestCase
  context 'NotificationMailer' do
    setup do
      ActionMailer::Base.deliveries.clear 
    end
    
    should '#SEND welcome_email' do
      notification = Factory.create :notification
      assert_equal 0, ActionMailer::Base.deliveries.size
      NotificationMailer.welcome_email(notification).deliver
      assert_equal 1, ActionMailer::Base.deliveries.size
      email = ActionMailer::Base.deliveries.first

      assert_equal [notification.contact.email, 'htgt@sanger.ac.uk', "Gene #{notification.gene.marker_symbol} updates registered"],
      [email.to.first, email.from.first, email.subject]
    end
    
    should '#SEND status_email' do
      mi_attempt_with_history = Factory.create :mi_attempt_with_status_history 
      contact = Factory.create :contact
      notification = Factory.create :notification, :gene => mi_attempt_with_history.gene, :contact => contact
      
      assert_equal 0, ActionMailer::Base.deliveries.size
      NotificationMailer.status_email(notification).deliver
      assert_equal 1, ActionMailer::Base.deliveries.size
      email = ActionMailer::Base.deliveries.first
      
      assert_equal [notification.contact.email, 'htgt@sanger.ac.uk', "Status update for #{notification.gene.marker_symbol}"],
      [email.to.first, email.from.first, email.subject]
    end
    
    should 'contain relevant status text' do
      mi_attempt_with_history = Factory.create :mi_attempt_with_status_history
      contact = Factory.create :contact
      notification = Factory.create :notification, :gene => mi_attempt_with_history.gene, :contact => contact
      relevant_status_stamp = notification.gene.mi_plans.first.relevant_status_stamp
      
      NotificationMailer.status_email(notification).deliver
      
      email = ActionMailer::Base.deliveries.first
      
      assert_contains email.body, relevant_status_stamp[:status]
      
    end

  end
end
