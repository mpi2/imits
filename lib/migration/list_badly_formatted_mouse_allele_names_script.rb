#!/usr/bin/env ruby
#encoding: utf-8

Old::MiAttempt.all.each do |mi|
  next if mi.mouse_allele_name.blank?


  if ! /\A[A-Za-z0-9]+<sup>(tm\d)([a-e])?(\(\w+\)\w+)<\/sup>\Z/.match(mi.mouse_allele_name)
    puts "MI(#{mi.id}) Clone(#{mi.clone.clone_name}): #{mi.mouse_allele_name.inspect} is bad mouse allele name"
  end
end
