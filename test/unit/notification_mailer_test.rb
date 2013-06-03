require 'pp'
require 'test_helper'

class NotificationMailerTest < ActionMailer::TestCase
  context 'NotificationMailer' do
    setup do
      ActionMailer::Base.deliveries.clear

      Factory.create :user, :email => 'htgt@sanger.ac.uk'

      Factory.create(:email_template_without_status)
      Factory.create(:email_template_microinjection_aborted)
      Factory.create(:email_template_genotype_confirmed)
      Factory.create(:email_template_assigned_es_cell_qc_complete)
      Factory.create(:email_template_phenotyping_complete)
      Factory.create(:email_template_welcome)
    end

    should_eventually '#SEND status_email with mi_plan statuses' do
      #notification = Factory.create :notification_simple

      mi_plan_with_recent_history = Factory.create :mi_plan_with_recent_status_history2
      contact = Factory.create(:contact)
      notification = Factory.create :notification_simple, {:gene => mi_plan_with_recent_history.gene, :contact => contact}

      assert_equal 0, ActionMailer::Base.deliveries.size
      assert_true notification.welcome_email_sent.nil?

      # don't send if we haven't sent welcome
      notification_mail = NotificationMailer.status_email(notification)
      notification_mail.deliver
      assert_equal 0, ActionMailer::Base.deliveries.size

      Notification.send_welcome_email_bulk
      assert_equal 1, ActionMailer::Base.deliveries.size

      notification.reload

      # don't send if we haven't changed anything
      notification_mail = NotificationMailer.status_email(notification)
      notification_mail.deliver

      email = ActionMailer::Base.deliveries.last

      #   pp email
      #notification_mail = NotificationMailer.status_email(notification)
      #notification_mail.deliver

      assert_equal 1, ActionMailer::Base.deliveries.size

      mi_plan_with_recent_history.reload

      # puts "#### mi_plan_with_recent_history:"
      #pp mi_plan_with_recent_history
      # pp mi_plan_with_recent_history.status.name

      mi_plan_with_recent_history.number_of_es_cells_passing_qc = 2
      mi_plan_with_recent_history.save!

      # puts "#### mi_plan_with_recent_history 2:"
      #pp mi_plan_with_recent_history
      # pp mi_plan_with_recent_history.status.name

      mi_plan_with_recent_history.reload
      notification.reload

      notification_mail = NotificationMailer.status_email(notification)
      notification_mail.deliver

      assert_equal 2, ActionMailer::Base.deliveries.size
    end

    should_eventually '#SEND status_email with mi_attempt statuses' do
      mi_attempt_with_recent_history = Factory.create :mi_attempt_with_recent_status_history

      contact = Factory.create(:contact)
      notification = Factory.create :notification, {:gene => mi_attempt_with_recent_history.gene, :contact => contact}

      assert_equal 0, ActionMailer::Base.deliveries.size
      if !notification.check_statuses.empty?
        notification_mail = NotificationMailer.status_email(notification)

        notification_mail.deliver
      end
      assert_equal 2, ActionMailer::Base.deliveries.size

      email = ActionMailer::Base.deliveries.last
      assert_equal [email.to.first, email.from.first, email.subject],[contact.email, 'info@mousephenotype.org', notification_mail.subject]
    end


    should_eventually '#SEND status_email with phenotype_attempt statuses' do
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

      assert_equal 0, ActionMailer::Base.deliveries.size
      if !notification.check_statuses.empty?
        notification_mail = NotificationMailer.status_email(notification)

        notification_mail.deliver
      end
      assert_equal 2, ActionMailer::Base.deliveries.size

      email = ActionMailer::Base.deliveries.last
      assert_equal [email.to.first, email.from.first, email.subject],[contact.email, 'info@mousephenotype.org', notification_mail.subject]
    end

    should_eventually '#NOT SEND status_email with gene.relevant_status[:status] that is in excluded_statuses' do
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
      email = ActionMailer::Base.deliveries.last

      assert_equal 1, ActionMailer::Base.deliveries.size
    end

    should '#send_welcome_email_bulk' do
      gene = Factory.create(:gene_cbx1)
      gene1 = Factory.create(:gene, :marker_symbol => 'Xbnf1')
      gene2 = Factory.create(:gene, :marker_symbol => 'Ady3')

      contact = Factory.create(:contact)
      contact2 = Factory.create(:contact)

      notification = Factory.create :notification_simple, {:gene => gene, :contact => contact}
      notification = Factory.create :notification_simple, {:gene => gene1, :contact => contact}
      notification = Factory.create :notification_simple, {:gene => gene2, :contact => contact}

      notification = Factory.create :notification_simple, {:gene => gene, :contact => contact2}
      notification = Factory.create :notification_simple, {:gene => gene1, :contact => contact2}
      notification = Factory.create :notification_simple, {:gene => gene2, :contact => contact2}

      assert_equal 6, Notification.all.count

      NotificationMailer.send_welcome_email_bulk

      Notification.all.each do |notification|
        assert ! notification.welcome_email_sent.blank?
        assert ! notification.welcome_email_text.blank?
      end

      assert_equal 2, ActionMailer::Base.deliveries.size
    end

    should '#send_status_emails' do
      gene = Factory.create(:gene_cbx1)
      contact = Factory.create(:contact)
      notification = Factory.create :notification_simple, {:gene => gene, :contact => contact}

      gene = Factory.create(:gene, :marker_symbol => 'Xbnf1')
      notification = Factory.create :notification_simple, {:gene => gene, :contact => contact}

      gene = Factory.create(:gene, :marker_symbol => 'Ady3')
      notification = Factory.create :notification_simple, {:gene => gene, :contact => contact}

      NotificationMailer.send_status_emails

      Notification.all.each do |notification|
        assert notification.welcome_email_sent.blank?
        assert notification.welcome_email_text.blank?

        assert notification.last_email_sent.blank?
        assert notification.last_email_text.blank?
      end

      assert_equal 0, ActionMailer::Base.deliveries.size
    end
  end
end
