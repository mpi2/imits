# encoding: utf-8

require 'pp'
require 'test_helper'

class NotificationTest < ActiveSupport::TestCase

  context 'Notification' do

    setup do
      Factory.create(:email_template_without_status)
    end

    def default_notification
      @default_notification ||= Factory.create :notification
    end

    context 'attribute tests:' do
      should 'have associations' do
        assert(default_notification.gene != nil)
        assert(default_notification.contact != nil)
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

    #context 'method tests' do
    #
    #  should '#send_welcome_email_bulk' do
    #
    #    gene = Factory.create(:gene_cbx1)
    #    contact = Factory.create(:contact)
    #    notification = Factory.create :notification_simple, {:gene => gene, :contact => contact}
    #
    #    gene = Factory.create(:gene, :marker_symbol => 'Xbnf1')
    #    notification = Factory.create :notification_simple, {:gene => gene, :contact => contact}
    #
    #    gene = Factory.create(:gene, :marker_symbol => 'Ady3')
    #    notification = Factory.create :notification_simple, {:gene => gene, :contact => contact}
    #
    #    Notification.send_welcome_email_bulk
    #
    #    Notification.all.each do |notification|
    #      assert ! notification.welcome_email_sent.blank?
    #      assert ! notification.welcome_email_text.blank?
    #     # pp notification
    #    end
    #  end
    #
    #  should '#send_status_emails'
    #  end

    context 'other tests' do
      should 'ensure we create contact if one does not already exist' do
        contact_email = 'fred@example.com'
        assert_nil Contact.find_by_email contact_email
        gene = Factory.create(:gene_cbx1)
        notification = Notification.create!(:contact_email => contact_email, :gene_mgi_accession_id => gene.mgi_accession_id)
        assert notification
        assert Contact.find_by_email contact_email
      #  pp Contact.find_by_email contact_email
      end
    end
  end

end
