require 'test_helper'

class NotificationMailerTest < ActionMailer::TestCase
  context 'NotificationMailer' do
    setup do
      ActionMailer::Base.deliveries.clear

      Factory.create(:email_template_without_status)
      Factory.create(:email_template_microinjection_aborted)
      Factory.create(:email_template_genotype_confirmed)
      Factory.create(:email_template_assigned_es_cell_qc_complete)
      Factory.create(:email_template_phenotyping_complete)
    end

    should '#SEND welcome_email' do
      gene = Factory.create(:gene_cbx1)
      contact = Factory.create(:contact)
      notification = Factory.create :notification, {:gene => gene, :contact => contact}
      assert_equal 1, ActionMailer::Base.deliveries.size

      email = ActionMailer::Base.deliveries.first

      assert_equal [email.to.first, email.from.first, email.subject],[contact.email, 'info@mousephenotype.org', email.subject]

    end

    should '#SEND status_email with mi_plan statuses' do
      mi_plan_with_recent_history = Factory.create :mi_plan_with_recent_status_history

      contact = Factory.create(:contact)
      notification = Factory.create :notification, {:gene => mi_plan_with_recent_history.gene, :contact => contact}

      assert_equal 1, ActionMailer::Base.deliveries.size
      if !notification.check_statuses.empty?
        notification_mail = NotificationMailer.status_email(notification)

        notification_mail.deliver
      end
      assert_equal 2, ActionMailer::Base.deliveries.size

      email = ActionMailer::Base.deliveries.last
      assert_equal [email.to.first, email.from.first, email.subject],[contact.email, 'info@mousephenotype.org', notification_mail.subject]
    end

    should '#SEND status_email with mi_attempt statuses' do
      mi_attempt_with_recent_history = Factory.create :mi_attempt_with_recent_status_history

      contact = Factory.create(:contact)
      notification = Factory.create :notification, {:gene => mi_attempt_with_recent_history.gene, :contact => contact}

      assert_equal 1, ActionMailer::Base.deliveries.size
      if !notification.check_statuses.empty?
        notification_mail = NotificationMailer.status_email(notification)

        notification_mail.deliver
      end
      assert_equal 2, ActionMailer::Base.deliveries.size

      email = ActionMailer::Base.deliveries.last
      assert_equal [email.to.first, email.from.first, email.subject],[contact.email, 'info@mousephenotype.org', notification_mail.subject]
    end


    should '#SEND status_email with phenotype_attempt statuses' do
      pa = Factory.create :phenotype_attempt_status_pdc

      pa.status_stamps.find_by_status_id!(PhenotypeAttempt::Status[:par].id).update_attributes!(:created_at => (Time.now - 1.hour))
      pa.status_stamps.find_by_status_id!(PhenotypeAttempt::Status[:pdc].id).update_attributes!(:created_at => (Time.now - 30.minute))
      pa.status_stamps.reload

      replace_status_stamps(pa.mi_attempt,
        :gtc => (Time.now - 1.hour),
        :chr => (Time.now - 2.weeks),
        :mip => (Time.now - 1.month)
      )

      pa.mi_plan.update_attributes!(:number_of_es_cells_passing_qc => 1)
      replace_status_stamps(pa.mi_plan,
        'asg' => (Time.now - 10.months),
        'asg-esp' => (Time.now - 20.days),
        'asg-esc' => (Time.now - 10.days)
      )

      contact = Factory.create(:contact)
      notification = Factory.create :notification, {:gene => pa.gene, :contact => contact}

      assert_equal 1, ActionMailer::Base.deliveries.size
      if !notification.check_statuses.empty?
        notification_mail = NotificationMailer.status_email(notification)

        notification_mail.deliver
      end
      assert_equal 2, ActionMailer::Base.deliveries.size

      email = ActionMailer::Base.deliveries.last
      assert_equal [email.to.first, email.from.first, email.subject],[contact.email, 'info@mousephenotype.org', notification_mail.subject]
    end

    should '#NOT SEND status_email with gene.relevant_status[:status] that is in excluded_statuses' do
      mi_attempt_with_recent_history = Factory.create :mi_attempt_with_recent_status_history
      mi_attempt_with_recent_history.is_active = false
      mi_attempt_with_recent_history.save!

      contact = Factory.create(:contact)
      notification = Factory.create :notification, {:gene => mi_attempt_with_recent_history.gene, :contact => contact}
      excluded_statuses = ['aborted_es_cell_qc_failed', 'microinjection_aborted', 'phenotype_attempt_aborted']

      assert_equal 1, ActionMailer::Base.deliveries.size
      if !notification.check_statuses.empty?
        if !excluded_statuses.any? {|status| notification.gene.relevant_status[:status].include? status}
          notification_mail = NotificationMailer.status_email(notification)

          notification_mail.deliver
        end
      end
      email = ActionMailer::Base.deliveries.last

      assert_equal 1, ActionMailer::Base.deliveries.size
    end
  end
end
