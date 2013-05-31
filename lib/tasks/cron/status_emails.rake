#desc 'Generate status emails'
#task 'cron:status_emails' => [:environment] do
#ApplicationModel.audited_transaction do
#  @excluded_statuses = ['aborted_es_cell_qc_failed', 'microinjection_aborted', 'phenotype_attempt_aborted']
#  notifications = Notification.all
#  notifications.each do |this_notification|
#    if !this_notification.gene.relevant_status.empty?
#      if !@excluded_statuses.any? {|status| this_notification.gene.relevant_status[:status].include? status}
#        if !this_notification.check_statuses.empty?
#          mailer = NotificationMailer.status_email(this_notification)
#          this_notification.last_email_text = mailer.body.to_s
#          this_notification.last_email_sent = Time.now.utc
#          this_notification.save!
#          mailer.deliver
#        end
#      end
#    end
#  end
#end

desc 'Generate status emails'
task 'cron:status_emails' => [:environment] do
  NotificationMailer.send_status_emails
end

desc 'Generate welcome emails'
task 'cron:welcome_emails' => [:environment] do
  NotificationMailer.send_welcome_email_bulk
end

#end
