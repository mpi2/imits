#!/usr/bin/env ruby

#Issue #9313 has been reported by Vivek Iyer.
#
#----------------------------------------
#Task #9313: create 'robot' users for (most) production centres
#http://htgt.internal.sanger.ac.uk:4005/issues/9313
#
#There are a number of production centres, who - like us - need 'robot' users. Create these, assigning them to the various centres:
#
#... let's make one user PER centre.
#Password - make it random in production
#
#1) After this is done, do a rake db:production:clone from live => staging
#AND a
#2) rake db:password:reset
#
#so that the ROBOT users have 'password' set into the staging environment. This will mean that users in Toronto can try API out  
#stuff using the robot users, TOMORROW.

DEBUG = false

ApplicationModel.audited_transaction do

Centre.all.each do |centre|
	base_name = centre.name.gsub(/\s+/, '_').downcase
	name = base_name + '_robot'
	next if User.find_by_name name
	# see http://stackoverflow.com/questions/88311/how-best-to-generate-a-random-string-in-ruby
      	password = ('a'..'z').to_a.shuffle[0,8].join
	email = "#{name}@#{base_name}.ac.uk"
	puts "#{name} - '#{email}' - '#{password}'" if DEBUG
	puts "#{name} - '#{email}'" if ! DEBUG
      	User.create!( { :name => name, :email => email, :password => password, :production_centre_id => centre.id } )
end

raise 'rollback!' if DEBUG

end

#User.all.each do |user|
	#puts "NAME: #{user.name}"
#end
