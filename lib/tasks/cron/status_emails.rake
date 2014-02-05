
require 'pp'

desc 'Generate status emails'
task 'cron:status_emails' => [:environment] do
  NotificationMailer.send_status_emails
end

desc 'Generate welcome emails'
task 'cron:welcome_emails' => [:environment] do
  NotificationMailer.send_welcome_email_bulk
end

#desc 'Generate production centre emails'
#task 'cron:production_centre_emails' => [:environment] do
#  #centre_contact = {}
#  #users_by_production_centre = {}
#  #
#  #Centre.all.each do |centre|
#  #  centre_contact[centre.name] = centre.contact_email;
#  #  users_by_production_centre[centre.name] = []
#  #end
#  #
#  #pp centre_contact
#  #
#  #hash = { 'contacts' => centre_contact }
#  #puts hash.to_yaml
#  #
#  ##centre_contact.keys.each do |key|
#  ##  puts "#### '#{key}' empty!" if centre_contact[key].nil?
#  ##end
#  #
#  #User.order('users.name').includes(:production_centre).each do |user|
#  #  if(user.is_contactable)
#  #    users_by_production_centre[user.production_centre.try(:name)] ||= []
#  #    next if ! users_by_production_centre[user.production_centre.try(:name)].empty?
#  #    users_by_production_centre[user.production_centre.try(:name)].push(user) if user.is_contactable
#  #  end
#  #end
#  #
#  #pp users_by_production_centre
#  #
#  ##users_by_production_centre.keys.each do |key|
#  ##  puts "#### '#{key}' empty!" if users_by_production_centre[key].empty?
#  ##end
#
#  contacts = YAML.load_file File.join(Rails.root, 'config', 'production_centre_contacts.yml')
#
#  contacts = contacts['contacts']
#
# # pp contacts
#
#  #NotificationMailer.send_production_centre_email('WTSI', 're4@sanger.ac.uk')
#
#  missing = []
#
#  contacts.keys.each do |centre|
#    if contacts[centre]
#      list = contacts[centre].split('|')
#      list.each do |email|
#        NotificationMailer.send_production_centre_email(centre, email)
#      end
#    else
#      missing.push centre
#    end
#  end
#
#  NotificationMailer.send_admin_email('re4@sanger.ac.uk', 'Monthly emails', "The following centres do not have contacts: #{missing}") if ! missing.empty?
#
#end

desc 'Generate production centre emails'
task 'cron:production_centre_emails' => [:environment] do
  NotificationMailer.send_production_centre_emails
end
