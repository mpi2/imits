require 'test_helper'

class NotificationMailerTest < ActionMailer::TestCase
  context 'NotificationMailer' do
    setup do
      ActionMailer::Base.deliveries.clear 
    end
    
    should '#SEND welcome_email' do
      gene = Factory.create(:gene_cbx1)
      contact = Factory.create(:contact)
      notification = Factory.create :notification, {:gene => gene, :contact => contact}
      assert_equal 0, ActionMailer::Base.deliveries.size
      notification_mail = NotificationMailer.welcome_email(notification)
      notification_mail.deliver
      assert_equal 1, ActionMailer::Base.deliveries.size
      
      email = ActionMailer::Base.deliveries.first
     
      assert_equal [email.to.first, email.from.first, email.subject],[contact.email, 'team87@sanger.ac.uk', notification_mail.subject]

    end
    
    should '#SEND status_email' do
      mi_attempt_with_recent_history = Factory.create :mi_attempt_with_recent_status_history

      contact = Factory.create(:contact)
      notification = Factory.create :notification, {:gene => mi_attempt_with_recent_history.gene, :contact => contact}
      
      assert_equal 0, ActionMailer::Base.deliveries.size
      if !notification.check_statuses.empty?
        notification_mail = NotificationMailer.status_email(notification)
     
        notification_mail.deliver
      end
      assert_equal 0, ActionMailer::Base.deliveries.size
      
      #email = ActionMailer::Base.deliveries.first
      #assert_equal [email.to.first, email.from.first, email.subject],[contact.email, 'team87@sanger.ac.uk', notification_mail.subject]
    end
  end
end
