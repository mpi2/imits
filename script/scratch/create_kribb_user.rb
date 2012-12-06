#!/usr/bin/env ruby

ApplicationModel.audited_transaction do

  email = 'kangho11@gmail.com'

  raise "#{email} already entered!" if User.find_by_email email

  password = ('a'..'z').to_a.shuffle[0,8].join

  User.create!(:email => email, :password => password, :production_centre => Centre.find_by_name('KRIBB'))

  #raise 'ROLLBACK'
end
