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

      assert_equal [email.to.first, email.from.first, email.subject],[contact.email, 'info@mousephenotype.org', notification_mail.subject]

    end

    should '#SEND status_email with mi_plan statuses' do
      mi_plan_with_recent_history = Factory.create :mi_plan_with_recent_status_history

      contact = Factory.create(:contact)
      notification = Factory.create :notification, {:gene => mi_plan_with_recent_history.gene, :contact => contact}

      assert_equal 0, ActionMailer::Base.deliveries.size
      if !notification.check_statuses.empty?
        notification_mail = NotificationMailer.status_email(notification)

        notification_mail.deliver
      end
      assert_equal 1, ActionMailer::Base.deliveries.size

      email = ActionMailer::Base.deliveries.first
      assert_equal [email.to.first, email.from.first, email.subject],[contact.email, 'info@mousephenotype.org', notification_mail.subject]
    end

    should '#SEND status_email with mi_attempt statuses' do
      mi_attempt_with_recent_history = Factory.create :mi_attempt_with_recent_status_history

      contact = Factory.create(:contact)
      notification = Factory.create :notification, {:gene => mi_attempt_with_recent_history.gene, :contact => contact}

      assert_equal 0, ActionMailer::Base.deliveries.size
      if !notification.check_statuses.empty?
        notification_mail = NotificationMailer.status_email(notification)

        notification_mail.deliver
      end
      assert_equal 1, ActionMailer::Base.deliveries.size

      email = ActionMailer::Base.deliveries.first
      assert_equal [email.to.first, email.from.first, email.subject],[contact.email, 'info@mousephenotype.org', notification_mail.subject]
    end


    should '#SEND status_email with phenotype_attempt statuses' do
      phenotype_attempt_with_recent_history = Factory.create :phenotype_attempt_with_recent_status_history

      contact = Factory.create(:contact)
      notification = Factory.create :notification, {:gene => phenotype_attempt_with_recent_history.gene, :contact => contact}

      assert_equal 0, ActionMailer::Base.deliveries.size
      if !notification.check_statuses.empty?
        notification_mail = NotificationMailer.status_email(notification)

        notification_mail.deliver
      end
      assert_equal 1, ActionMailer::Base.deliveries.size

      email = ActionMailer::Base.deliveries.first
      assert_equal [email.to.first, email.from.first, email.subject],[contact.email, 'info@mousephenotype.org', notification_mail.subject]
    end

    should '#NOT SEND status_email with gene.relevant_status[:status] that is in excluded_statuses' do
       mi_attempt_with_recent_history = Factory.create :mi_attempt_with_recent_status_history
       mi_attempt_with_recent_history.is_active = false
       mi_attempt_with_recent_history.save!

       contact = Factory.create(:contact)
       notification = Factory.create :notification, {:gene => mi_attempt_with_recent_history.gene, :contact => contact}
       excluded_statuses = ['aborted_es_cell_qc_failed', 'microinjection_aborted', 'phenotype_attempt_aborted']

       assert_equal 0, ActionMailer::Base.deliveries.size
       if !notification.check_statuses.empty?
         if !excluded_statuses.any? {|status| notification.gene.relevant_status[:status].include? status}
           notification_mail = NotificationMailer.status_email(notification)

           notification_mail.deliver
         end
       end
       email = ActionMailer::Base.deliveries.first

       assert_equal 0, ActionMailer::Base.deliveries.size
    end
  end
end
