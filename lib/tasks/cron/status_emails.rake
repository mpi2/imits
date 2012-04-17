desc 'Generate status emails'
task 'cron:status_emails' => [:environment] do
  ApplicationModel.audited_transaction do
    Notification.all.each do |this_notification|
      if NotificationMailer.status_email(this_notification)
        this_notification.last_email_sent = Time.now.utc
      end
    end 
  end
end
