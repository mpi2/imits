#!/usr/bin/env ruby

ApplicationModel.audited_transaction do


  consortium = Consortium.find_by_name('MGP Legacy')
  centre = Centre.find_by_name('WTSI')
  sql = "SELECT mi_attempts.* FROM mi_attempts INNER JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id INNER JOIN consortia ON consortia.id = mi_plans.consortium_id WHERE consortia.name = 'MGP' AND mi_attempts.mi_date < '2011/6/1'"
  a = MiAttempt.find_by_sql(sql)
  puts " #{a.count} mi attempts to correct"
  a.each do |mi_attempt|
    mi_attempt.consortium_name = 'MGP Legacy'
    mi_attempt.production_centre_name = 'WTSI'
    puts mi_attempt.id
    mi_attempt.save!
  end

  consortium = Consortium.find_by_name('MGP Legacy')
  centre = Centre.find_by_name('WTSI')
  sql = "SELECT mi_attempts.* FROM mi_attempts INNER JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id INNER JOIN consortia ON consortia.id = mi_plans.consortium_id WHERE consortia.name = 'MGP Legacy' AND mi_attempts.mi_date > '2011/6/1'"
  a = MiAttempt.find_by_sql(sql)
  puts " #{a.count} mi attempts to correct"
  a.each do |mi_attempt|
    mi_attempt.consortium_name = 'MGP'
    mi_attempt.production_centre_name = 'WTSI'
    puts mi_attempt.id
    mi_attempt.save!
  end

 # raise 'TEST'
end