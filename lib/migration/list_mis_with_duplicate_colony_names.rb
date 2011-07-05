#!/usr/bin/env ruby
#encoding: utf-8

mis = Old::MiAttempt.all

mis.delete_if {|i| Kermits2::Migration::EXCLUDE_LIST.include? i.id.to_i }

mis = mis.group_by {|mi| cn = mi.colony_name; cn = nil if cn.blank?; next cn }

mis.delete nil

bad_mis = {}
mis.each {|colony_name, mis| bad_mis[colony_name] = mis if mis.size != 1 }

puts "Number of colony_names that have more than one MI: #{bad_mis.keys.size}"

puts 'Colony names with duplicate MIs:', bad_mis.keys
