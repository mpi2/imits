# encoding: utf-8

require 'test_helper'

class NotificationTest < ActiveSupport::TestCase

  context 'Notification' do

    def default_notification
      puts EmailTemplate.count
      @default_notification ||= Factory.create :notification
    end

    context 'attribute tests:' do
      should 'have associations' do
        assert (default_notification.gene != nil)
        assert (default_notification.contact != nil)
      end

      should 'have db columns' do
        assert_should have_db_column(:gene_id)
        assert_should have_db_column(:contact_id)
        assert_should have_db_column(:welcome_email_sent)
        assert_should have_db_column(:welcome_email_text)
        assert_should have_db_column(:last_email_sent)
        assert_should have_db_column(:last_email_text)
      end
    end

  end

end
