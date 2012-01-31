#!/usr/bin/env ruby

ip_status = MiAttemptStatus.micro_injection_in_progress
gc_status = MiAttemptStatus.genotype_confirmed

MiAttempt.transaction do
  broken = MiAttempt.all.find_all do |mi|
    !mi.status_stamps.map(&:description).include?('Micro-injection in progress')
  end

  broken.each do |mi|
    ip_time = Time.parse("#{mi.mi_date} 00:00:00 UTC")
    duplicates = mi.status_stamps.all.find_all {|i| i.created_at == ip_time}
    if ! duplicates.empty?
      duplicates.each {|d| d.created_at += 1.second; d.save!}
      mi.status_stamps.create!(:mi_attempt_status => ip_status, :created_at => ip_time)

      mi.status_stamps.reload

      puts "#{mi.colony_name} now looks like:\n"
      puts "#{mi.reportable_statuses_with_latest_dates.map{|k,v| k + ": " + v.to_s}.join("\n")}"
      puts
    end
  end

  still_broken = MiAttempt.all.find_all do |mi|
    !mi.status_stamps.map(&:description).include?('Micro-injection in progress')
  end

  mi = MiAttempt.find_by_colony_name!('E227')
  mi.status_stamps.create!(:mi_attempt_status => ip_status,
    :created_at => '2011-10-25 01:00:00 UTC')

  mi = MiAttempt.find_by_colony_name!('E224')
  mi.status_stamps.create!(:mi_attempt_status => ip_status,
    :created_at => '2011-11-08 01:00:00 UTC')

  mi = MiAttempt.find_by_colony_name!('UCD-12535B-A6-1')
  mi.status_stamps.create!(:mi_attempt_status => ip_status,
    :created_at => '2012-01-06 01:00:00 UTC')

  mi = MiAttempt.find_by_colony_name!('UCD-EPD0296_1_A08-1')
  mi.status_stamps.create!(:mi_attempt_status => ip_status,
    :created_at => '2012-01-06 01:00:00 UTC')

  puts "Manual edits:\n"
  still_broken.each do |mi|
    mi.reload
    puts "#{mi.colony_name} now looks like:\n"
    puts "#{mi.status_stamps.map {|ss| ss.description + ": " + ss.created_at.to_s}.join("\n")}"
    puts
  end
end
