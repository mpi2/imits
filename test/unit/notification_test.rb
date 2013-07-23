# encoding: utf-8

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

    context 'method tests' do

      should '#check_statuses' do

        mi_plan_with_recent_history = Factory.create :mi_plan_with_recent_status_history3
        contact = Factory.create(:contact)
        notification = Factory.create :notification, {:gene => mi_plan_with_recent_history.gene, :contact => contact}

        assert_equal 1, notification.check_statuses.size
        assert_equal "assigned_es_cell_qc_complete", notification.check_statuses[0][:status]

        Notification.delete_all

        mi_attempt_with_recent_status_history = Factory.create :mi_attempt_with_recent_status_history

        contact = Factory.create(:contact)
        notification = Factory.create :notification, {:gene => mi_attempt_with_recent_status_history.mi_plan.gene, :contact => contact}

        assert_equal 1, notification.check_statuses.size
        assert_equal "genotype_confirmed", notification.check_statuses[0][:status]

        mi_attempt_with_recent_status_history.is_active = false
        mi_attempt_with_recent_status_history.save!

        mi_attempt_with_recent_status_history.reload

        assert_false mi_attempt_with_recent_status_history.is_active?

        contact = Factory.create(:contact)
        notification = Factory.create :notification, {:gene => mi_attempt_with_recent_status_history.mi_plan.gene, :contact => contact}

        assert_equal 0, notification.check_statuses.size

        mi_plan_with_recent_history = Factory.create :mi_plan_with_recent_status_history3
        mi_plan_with_recent_history.is_active = false
        mi_plan_with_recent_history.save!
        mi_plan_with_recent_history.reload

        contact = Factory.create(:contact)
        notification = Factory.create :notification, {:gene => mi_plan_with_recent_history.gene, :contact => contact}

        assert_equal 0, notification.check_statuses.size

        Notification.delete_all

        mi_plan_with_recent_history = Factory.create :mi_plan_with_recent_status_history
        mi_plan = Factory.create(:mi_plan, :gene => mi_plan_with_recent_history.gene)

        mi_plan.withdrawn = true
        mi_plan.save!

        contact = Factory.create(:contact)
        notification = Factory.create :notification, {:gene => mi_plan.gene, :contact => contact}

        assert_equal 1, notification.check_statuses.size
        assert_equal "assigned_es_cell_qc_complete", notification.check_statuses[0][:status]

        phenotype_attempt = Factory.create(:phenotype_attempt)

        phenotype_attempt.is_active = false
        phenotype_attempt.save!
        phenotype_attempt.reload

        contact = Factory.create(:contact)
        notification = Factory.create :notification, {:gene => phenotype_attempt.mi_plan.gene, :contact => contact}

        assert_equal 0, notification.check_statuses.size
      end

      should '#send_welcome_email' do
        contact_email = 'fred@example.com'
        assert_nil Contact.find_by_email contact_email
        gene = Factory.create(:gene_cbx1)
        notification = Notification.create!(:contact_email => contact_email, :gene_mgi_accession_id => gene.mgi_accession_id)
        assert notification

        notification.send_welcome_email

        assert_equal 1, ActionMailer::Base.deliveries.size
      end
    end

    context 'other tests' do
      should 'ensure we create contact if one does not already exist' do
        contact_email = 'fred@example.com'
        assert_nil Contact.find_by_email contact_email
        gene = Factory.create(:gene_cbx1)
        notification = Notification.create!(:contact_email => contact_email, :gene_mgi_accession_id => gene.mgi_accession_id)
        assert notification
        contact = Contact.find_by_email(contact_email)
        assert contact
        actual_email = contact.email
        assert actual_email
        assert_equal contact_email, actual_email
      end
    end
  end

end
