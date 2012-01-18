#dodgy_mis_copy = dodgy_mis.dup

gc = MiAttemptStatus.genotype_confirmed
ip = MiAttemptStatus.micro_injection_in_progress

ActiveRecord::Base.transaction do
  mi = MiAttempt.find_by_colony_name!('MBJC')
  mi.status_stamps.reverse[0..1].each {|i| i.destroy}

  mi = MiAttempt.find_by_colony_name!('MAIG')
  mi.status_stamps.find_by_mi_attempt_status_id(ip.id).update_attributes!(:created_at => '2007-06-20 12:00:00 UTC')

  mi = MiAttempt.find_by_colony_name!('MAYU')
  mi.status_stamps.reverse[0..1].each {|i| i.destroy}

  mi = MiAttempt.find_by_colony_name!('MCZX')
  ss = mi.status_stamps.all.reverse.find {|i| i.mi_attempt_status_id == gc.id}
  ss.created_at += 1.second
  ss.save!

  mi = MiAttempt.find_by_colony_name!('MDQY')
  mi.status_stamps.find_by_mi_attempt_status_id!(gc.id).destroy

  mi = MiAttempt.find_by_colony_name!('UCD-EPD0413_5_E10-1')
  mi.status_stamps.find_by_mi_attempt_status_id!(ip.id).update_attributes(:created_at => '2010-10-11 12:00:00 UTC')
  mi.mi_plan.status_stamps.find_by_status_id!(MiPlan::Status['Assigned'].id).update_attributes(:created_at => '2010-10-11 06:00:00 UTC')

  mi = MiAttempt.find_by_colony_name!('UCD-DEPD00514_4_H02-1')
  mi.status_stamps.find_by_mi_attempt_status_id!(ip.id).update_attributes(:created_at => '2011-01-05 12:00:00 UTC')
  mi.mi_plan.status_stamps.find_by_status_id!(MiPlan::Status['Assigned'].id).update_attributes(:created_at => '2011-01-05 06:00:00 UTC')

  all_dodgy_mis = MiAttempt.all.to_a.find_all {|i| i.status_stamps.last.mi_attempt_status_id != i.mi_attempt_status_id }

  last_ss_same_times, dodgy_mis = all_dodgy_mis.partition {|i| i.status_stamps[-1].created_at.to_s == i.status_stamps[-2].created_at.to_s}

  last_ss_same_times.each do |mi|
    problem_time = mi.status_stamps.last.created_at
    problems = mi.status_stamps.reverse.find_all {|i| i.created_at == problem_time}
    ss = problems.first
    ss.created_at += 1.hour
    ss.save!
  end
end
