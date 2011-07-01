#!/usr/bin/env ruby
#encoding: utf-8

if Rails.env.production?
  raise "Not supported yet"
else
  User.all.each do |user|
    user.update_attributes(:password => 'password')
  end
end
