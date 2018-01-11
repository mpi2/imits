
desc 'Generate production centre emails'
task 'cron:production_centre_emails' => [:environment] do
  NotificationMailer.send_production_centre_emails
end
