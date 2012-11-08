#!/usr/bin/env ruby

hash = {}

#Centre.all.each do |centre|
#  hash[centre.name] = 'this_url'
#end

MiAttempt::DistributionCentre.all.each do |centre|
  hash[centre.centre.name] = { :preferred => '', :default => ''}
end

PhenotypeAttempt::DistributionCentre.all.each do |centre|
  hash[centre.centre.name] = { :preferred => '', :default => ''}
end

File.open("#{Rails.root}/config/dist_centre_urls.yml", 'w+') {|f| f.write(hash.to_yaml) }
