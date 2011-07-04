#!/usr/bin/env ruby
# encoding: utf-8

if ! Object.constants.include?(:Rails)
  require File.expand_path('../../../config/environment', __FILE__)
end
raise 'Running in production environment - comment out this line to confirm' if Rails.env.production?

ActionMailer::Base.logger = nil

User.all.each do |user|
  new_password = `pwgen -1 -y -n 12 1`.strip

  body = <<-"EOL"
Hello,

We have redesigned and redeveloped the new  Kermits to the stage where the old
site is no longer needed.  However, in the process of doing so, we had to reset
all the usernames and passwords.  Your new login details are as follows:

New URL : #{SITE_PATH}
Username: #{user.email}
Password: #{new_password}

You can change the password after you have logged in by following the link
in the top-right corner.

Regards,
   Team HTGT
  EOL

  user.update_attributes!(:password => new_password)
  UserMailer.email(:subject => 'New Kermits passwords', :user => user, :body => body).deliver
end
