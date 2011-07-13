#!/usr/bin/env ruby
# encoding: utf-8

if ! Object.constants.include?(:Rails)
  require File.expand_path('../../../config/environment', __FILE__)
end
raise 'Cannot run in production environment' if Rails.env.production?

User.all.each do |user|
  user.update_attributes!(:password => 'password')
end
