require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  context 'UserMailer' do

    should '#email' do
      user = Factory.create :user, :email => 'fred@example.com'
      assert_equal 0, ActionMailer::Base.deliveries.size
      UserMailer.email(:user => user, :subject => 'Email Subject', :body => 'Email Body').deliver
      assert_equal 1, ActionMailer::Base.deliveries.size
      email = ActionMailer::Base.deliveries.first

      assert_equal ['fred@example.com', 'htgt@sanger.ac.uk', 'Email Subject', 'Email Body'],
              [email.to.first, email.from.first, email.subject, email.body.to_s.strip]
    end

  end
end
