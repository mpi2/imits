#encoding: utf-8

##
## iMITS
##

##
## Centres
##

Factory.define :centre do |centre|
  centre.sequence(:name) { |n| "Auto-generated Centre Name #{n}" }
end

##
## Consortia
##

Factory.define :consortium do |consortium|
  consortium.sequence(:name) { |n| "Auto-generated Consortium Name #{n}" }
end

##
## Users
##

Factory.define :user do |user|
  user.sequence(:email) { |n| "user#{n}@example.com" }
  user.password 'password'
  user.production_centre { Centre.find_by_name!('WTSI') }
end

Factory.define :admin_user, :parent => :user do |user|
  user.email 'vvi@sanger.ac.uk'
  user.admin true
end
