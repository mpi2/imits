#!/usr/bin/env ruby

require 'pp'

DEBUG = false
MISSING = [859]

counter = 0

MiAttempt.transaction do

  MiAttempt.all.each do |mi|
    status_stamp = mi.status_stamps.find_by_status_id(mi.status.id)
    if ! status_stamp
      puts "#### Missing: mi.id: #{mi.id} - mi.status.id: #{mi.status.id}"

      raise "Illegal id found: #{mi.id}!" if ! MISSING.include? mi.id

      pp mi.status_stamps if DEBUG

      #[#<MiAttempt::StatusStamp id: 8037, mi_attempt_id: 859, status_id: 1,
      #   created_at: "2009-02-11 00:00:00", updated_at: "2011-11-17 12:15:18">]

      stamp = mi.status_stamps.first

      mi.status_stamps.create!(:created_at => stamp.created_at, :updated_at => stamp.updated_at, :status_id => mi.status.id)

      puts "#### after:" if DEBUG
      pp mi.status_stamps if DEBUG

      if DEBUG
        puts "#### audits:"
        mi.status_stamps.each do |status_stamp|
          pp status_stamp.audits
        end
      end

      counter += 1

    end
  end

  raise "Rollback!" if DEBUG
  raise "Invalid count detected (#{counter})!" if counter != 1

  #raise "Rollback!"

end

puts "done!"