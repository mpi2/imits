
desc 'Generate status emails'
task 'cron:status_emails' => [:environment] do
  NotificationMailer.send_status_emails
end

desc 'Generate welcome emails'
task 'cron:welcome_emails' => [:environment] do
  NotificationMailer.send_welcome_email_bulk
end

desc 'Generate production centre emails'
task 'cron:production_centre_emails' => [:environment] do
  NotificationMailer.send_production_centre_emails
end
