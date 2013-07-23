
desc 'Generate status emails'
task 'cron:status_emails' => [:environment] do
  NotificationMailer.send_status_emails
end

desc 'Generate welcome emails'
task 'cron:welcome_emails' => [:environment] do
  NotificationMailer.send_welcome_email_bulk
end
