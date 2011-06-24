#!/usr/bin/env ruby
#encoding: utf-8

mis = Old::MiAttempt.all.group_by {|mi| cn = mi.colony_name; cn = nil if cn.blank?; next cn }

mis.delete nil

bad_mis = {}
mis.each {|colony_name, mis| bad_mis[colony_name] = mis if mis.size != 1 }

puts "Number of colony_names that have more than one MI: #{bad_mis.keys.size}"

fixable_mis = {}
unfixable_mis = {}
all_inactive_mis = {}
all_non_emma_but_one_active_mis = {}

bad_mis.each do |colony_name, mis|
  if mis.find_all {|mi| mi.is_active? and mi.emma? }.size == 1
    fixable_mis[colony_name] = mis
  elsif mis.find_all {|mi| mi.is_active? }.size == 1
    all_non_emma_but_one_active_mis[colony_name] = mis
  elsif mis.find_all {|mi| ! mi.is_active?}.size == mis.size
    all_inactive_mis[colony_name] = mis
  else
    unfixable_mis[colony_name] = mis
  end
end

unfixable_mis.each {|colony_name, mis| unfixable_mis.delete(colony_name) if mis.size == 1 }

puts "Number of colony_names whose MIs are automatically fixable: #{fixable_mis.keys.size}"
puts "Number of colony_names whose MIS all non-emma and only one is active: #{all_non_emma_but_one_active_mis.keys.size}"
puts "Number of colony_names whose MIs are all inactive: #{all_inactive_mis.keys.size}"
puts "Number of colony_names whose MIs are unfixable: #{unfixable_mis.keys.size}"

puts "Unfixable colony_names:", (unfixable_mis.keys + all_inactive_mis.keys + all_non_emma_but_one_active_mis.keys).sort
