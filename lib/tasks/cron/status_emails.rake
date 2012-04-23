desc 'Generate status emails'
task 'cron:status_emails' => [:environment] do
  ApplicationModel.audited_transaction do
    notifications = Notification.all
    notifications.each do |this_notification|
      if !this_notification.check_statuses.empty?
        mailer = NotificationMailer.status_email(this_notification)
        this_notification.last_email_text = mailer.body
        this_notification.last_email_sent = Time.now.utc
        this_notification.save!
        mailer.deliver
      end
    end 
  end
end
