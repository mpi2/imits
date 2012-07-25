#!/usr/bin/env ruby

ApplicationModel.audited_transaction do

  #Selects all phenotype ids that have a phenotype completed but missing the phenotype started status
  sql = "SELECT phenotype_attempt_status_stamps.id, phenotype_attempt_status_stamps.phenotype_attempt_id, phenotype_attempt_status_stamps.status_id, phenotype_attempt_status_stamps.created_at, phenotype_attempt_status_stamps.updated_at FROM phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id LEFT OUTER JOIN (SELECT phenotype_attempt_status_stamps.phenotype_attempt_id AS id FROM (phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id) WHERE phenotype_attempt_statuses.name = 'Phenotyping Started') a ON a.id = phenotype_attempt_status_stamps.phenotype_attempt_id WHERE a.id IS NULL AND  phenotype_attempt_statuses.name = 'Phenotyping Complete'"
  a=PhenotypeAttempt::StatusStamp.find_by_sql(sql)
  puts "#{a.count} Phenotype started status missing ..."
  a.each do |record|
      rec = PhenotypeAttempt::StatusStamp.new(:phenotype_attempt_id=> record.phenotype_attempt_id, :created_at => record.created_at, :status_id=>PhenotypeAttempt::Status.find_by_name!("Phenotyping Started").id)
      rec.save!
  end
  puts "... #{a.count} Phenotype started status added"

  #Selects all phenotype ids that have a phenotype started but missing the Cre completed status
  sql = "SELECT phenotype_attempt_status_stamps.id, phenotype_attempt_status_stamps.phenotype_attempt_id, phenotype_attempt_status_stamps.status_id, phenotype_attempt_status_stamps.created_at, phenotype_attempt_status_stamps.updated_at FROM phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id LEFT OUTER JOIN (SELECT phenotype_attempt_status_stamps.phenotype_attempt_id AS id FROM (phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id) WHERE phenotype_attempt_statuses.name = 'Cre Excision Complete') a ON a.id = phenotype_attempt_status_stamps.phenotype_attempt_id WHERE a.id IS NULL AND  phenotype_attempt_statuses.name = 'Phenotyping Started'"
  a=PhenotypeAttempt::StatusStamp.find_by_sql(sql)
  puts "#{a.count} Cre completed status missing ..."
  a.each do |record|
      rec = PhenotypeAttempt::StatusStamp.new(:phenotype_attempt_id=> record.phenotype_attempt_id, :created_at => record.created_at, :status_id=>PhenotypeAttempt::Status.find_by_name!("Cre Excision Complete").id)
      rec.save!
  end
  puts "... #{a.count} Cre completed status added"

  #Selects all phenotype ids that have a Cre completed but missing the Cre started status
  sql = "SELECT phenotype_attempt_status_stamps.id, phenotype_attempt_status_stamps.phenotype_attempt_id, phenotype_attempt_status_stamps.status_id, phenotype_attempt_status_stamps.created_at, phenotype_attempt_status_stamps.updated_at FROM phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id LEFT OUTER JOIN (SELECT phenotype_attempt_status_stamps.phenotype_attempt_id AS id FROM (phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id) WHERE phenotype_attempt_statuses.name = 'Cre Excision Started') a ON a.id = phenotype_attempt_status_stamps.phenotype_attempt_id WHERE a.id IS NULL AND  phenotype_attempt_statuses.name = 'Cre Excision Complete'"
  a=PhenotypeAttempt::StatusStamp.find_by_sql(sql)
  puts "#{a.count} Cre started status missing ..."
  a.each do |record|
      rec = PhenotypeAttempt::StatusStamp.new(:phenotype_attempt_id=> record.phenotype_attempt_id, :created_at => record.created_at, :status_id=>PhenotypeAttempt::Status.find_by_name!("Cre Excision Started").id)
      rec.save!
  end
  puts "... #{a.count} Cre started status added"

  #Selects all phenotype ids that have a Rederivation Complete but missing the Rederivation Started status
  sql = "SELECT phenotype_attempt_status_stamps.id, phenotype_attempt_status_stamps.phenotype_attempt_id, phenotype_attempt_status_stamps.status_id, phenotype_attempt_status_stamps.created_at, phenotype_attempt_status_stamps.updated_at FROM phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id LEFT OUTER JOIN (SELECT phenotype_attempt_status_stamps.phenotype_attempt_id AS id FROM (phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id) WHERE phenotype_attempt_statuses.name = 'Rederivation Started') a ON a.id = phenotype_attempt_status_stamps.phenotype_attempt_id WHERE a.id IS NULL AND  phenotype_attempt_statuses.name = 'Rederivation Complete'"
  a=PhenotypeAttempt::StatusStamp.find_by_sql(sql)
  puts "#{a.count} Redeivation Started status missing ..."
  a.each do |record|
      rec = PhenotypeAttempt::StatusStamp.new(:phenotype_attempt_id=> record.phenotype_attempt_id, :created_at => record.created_at, :status_id=>PhenotypeAttempt::Status.find_by_name!("Rederivation Started").id)
      rec.save!
  end
  puts "... #{a.count} Redeivation Started status added"

  #Selects all phenotype ids that have Cre Excision Started but missing the Phenotype Attempt Registered status
  sql = "SELECT phenotype_attempt_status_stamps.id, phenotype_attempt_status_stamps.phenotype_attempt_id, phenotype_attempt_status_stamps.status_id, phenotype_attempt_status_stamps.created_at, phenotype_attempt_status_stamps.updated_at FROM phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id LEFT OUTER JOIN (SELECT phenotype_attempt_status_stamps.phenotype_attempt_id AS id FROM (phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id) WHERE phenotype_attempt_statuses.name = 'Phenotype Attempt Registered') a ON a.id = phenotype_attempt_status_stamps.phenotype_attempt_id WHERE a.id IS NULL AND  phenotype_attempt_statuses.name = 'Cre Excision Started'"
  a=PhenotypeAttempt::StatusStamp.find_by_sql(sql)
  puts "#{a.count} Phenotype Attempt Registered status missing ..."
  a.each do |record|
      rec = PhenotypeAttempt::StatusStamp.new(:phenotype_attempt_id=> record.phenotype_attempt_id, :created_at => record.created_at, :status_id=>PhenotypeAttempt::Status.find_by_name!("Phenotype Attempt Registered").id)
      rec.save!
  end
  puts "... #{a.count} Phenotype Registered status added"

  #Selects all phenotype ids that have Rederivation Started but missing the Phenotype Attempt Registered status
  sql = "SELECT phenotype_attempt_status_stamps.id, phenotype_attempt_status_stamps.phenotype_attempt_id, phenotype_attempt_status_stamps.status_id, phenotype_attempt_status_stamps.created_at, phenotype_attempt_status_stamps.updated_at FROM phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id LEFT OUTER JOIN (SELECT phenotype_attempt_status_stamps.phenotype_attempt_id AS id FROM (phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id) WHERE phenotype_attempt_statuses.name = 'Phenotype Attempt Registered') a ON a.id = phenotype_attempt_status_stamps.phenotype_attempt_id WHERE a.id IS NULL AND  phenotype_attempt_statuses.name = 'Rederivation Started'"
  a=PhenotypeAttempt::StatusStamp.find_by_sql(sql)
  puts "#{a.count} Phenotype Attempt Registered status missing ..."
  a.each do |record|
      rec = PhenotypeAttempt::StatusStamp.new(:phenotype_attempt_id=> record.phenotype_attempt_id, :created_at => record.created_at, :status_id=>PhenotypeAttempt::Status.find_by_name!("Phenotype Attempt Registered").id)
      rec.save!
  end
  puts "... #{a.count} Phenotype Registered status added"


  #Selects all phenotype ids that are aborted and have a status that is older than the aborted date
  sql = "SELECT DISTINCT phenotype_attempt_status_stamps.id, s1.name FROM ((phenotype_attempt_status_stamps INNER JOIN phenotype_attempt_statuses s1 ON phenotype_attempt_status_stamps.status_id = s1.id) INNER JOIN phenotype_attempts ON phenotype_attempt_status_stamps.phenotype_attempt_id = phenotype_attempts.id) INNER JOIN  phenotype_attempt_statuses s2 ON phenotype_attempts.status_id = s2.id WHERE s1.name = 'Phenotype Attempt Aborted' AND s2.name != 'Phenotype Attempt Aborted'"
  a=PhenotypeAttempt::StatusStamp.find_by_sql(sql)
  puts "#{a.count} incorrect Aborted status ..."
  a.each do |record|
      rec = PhenotypeAttempt::StatusStamp.find_by_id!(record.id).destroy
  end
  puts "... #{a.count} Aborted status deleted"


"SELECT mi_plan_status_stamps.id, s1.name FROM ((mi_plan_status_stamps INNER JOIN mi_plan_statuses s1 ON mi_plan_status_stamps.status_id = s1.id) INNER JOIN mi_plans ON mi_plan_status_stamps.mi_plan_id = mi_plans.id) INNER JOIN  mi_plan_statuses s2 ON mi_plans.status_id = s2.id WHERE s1.name = 'Aborted - ES Cell QC Failed' AND s2.name != 'Aborted - ES Cell QC Failed'"






  #Selects all mi attempt ids that have Genotype confirmed but missing the chimeras obtained status
  sql = "SELECT mi_attempt_status_stamps.id ,mi_attempt_status_stamps.mi_attempt_id, mi_attempt_status_stamps.mi_attempt_status_id, mi_attempt_status_stamps.created_at, mi_attempt_status_stamps.updated_at FROM mi_attempt_status_stamps INNER JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempt_status_stamps.mi_attempt_status_id LEFT OUTER JOIN (SELECT mi_attempt_status_stamps.mi_attempt_id AS id FROM (mi_attempt_status_stamps INNER JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempt_status_stamps.mi_attempt_status_id) WHERE mi_attempt_statuses.description= 'Chimeras obtained') a ON a.id = mi_attempt_status_stamps.mi_attempt_id WHERE a.id IS NULL AND mi_attempt_statuses.description = 'Genotype confirmed'"
  a=MiAttempt::StatusStamp.find_by_sql(sql)
  puts "#{a.count} chimeras obtained status missing ..."
  a.each do |record|
      rec = MiAttempt::StatusStamp.new(:mi_attempt_id=> record.mi_attempt_id, :created_at => record.created_at, :mi_attempt_status_id=> MiAttemptStatus.find_by_description!("Chimeras obtained").id)
      rec.save!
  end
  puts "... #{a.count} chimeras obtained status added"

  #Selects all mi attempt ids that have Genotype confirmed but missing the Micro_injection in progress status
  sql = "SELECT mi_attempt_status_stamps.id ,mi_attempt_status_stamps.mi_attempt_id, mi_attempt_status_stamps.mi_attempt_status_id, mi_attempt_status_stamps.created_at, mi_attempt_status_stamps.updated_at FROM mi_attempt_status_stamps INNER JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempt_status_stamps.mi_attempt_status_id LEFT OUTER JOIN (SELECT mi_attempt_status_stamps.mi_attempt_id AS id FROM (mi_attempt_status_stamps INNER JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempt_status_stamps.mi_attempt_status_id) WHERE mi_attempt_statuses.description= 'Micro-injection in progress') a ON a.id = mi_attempt_status_stamps.mi_attempt_id WHERE a.id IS NULL AND mi_attempt_statuses.description = 'Genotype confirmed'"
  a=MiAttempt::StatusStamp.find_by_sql(sql)
  puts "#{a.count} Micro_injection in progress status missing ..."
  a.each do |record|
      rec = MiAttempt::StatusStamp.new(:mi_attempt_id=> record.mi_attempt_id, :created_at => record.created_at, :mi_attempt_status_id=> MiAttemptStatus.find_by_description!("Micro-injection in progress").id)
      rec.save!
  end
  puts "... #{a.count} Micro_injection in progress status added"

  #Selects all miPlan ids that are aborted and have a status that is older than the aborted date
  sql = "SELECT DISTINCT mi_attempt_status_stamps.id FROM ((mi_attempt_status_stamps INNER JOIN mi_attempt_statuses s1 ON mi_attempt_status_stamps.mi_attempt_status_id = s1.id) INNER JOIN mi_attempts ON mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id) INNER JOIN  mi_attempt_statuses s2 ON mi_attempts.mi_attempt_status_id = s2.id WHERE s1.description = 'Micro-injection aborted' AND s2.description != 'Micro-injection aborted'"
  a=MiAttempt::StatusStamp.find_by_sql(sql)
  puts "#{a.count} incorrect Aborted status ..."
  a.each do |record|
      rec = MiAttempt::StatusStamp.find_by_id!(record.id).destroy
  end
  puts "... #{a.count} Aborted status deleted"










  #Selects all mi plan ids that have Assigned - ES Cell QC Complete but missing the Assigned - ES Cell QC In Progress status
  sql = "SELECT mi_plan_status_stamps.id, mi_plan_status_stamps.mi_plan_id, mi_plan_status_stamps.status_id, mi_plan_status_stamps.created_at, mi_plan_status_stamps.updated_at FROM mi_plan_status_stamps INNER JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plan_status_stamps.status_id LEFT OUTER JOIN (SELECT mi_plan_status_stamps.mi_plan_id AS id FROM (mi_plan_status_stamps INNER JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plan_status_stamps.status_id) WHERE mi_plan_statuses.name = 'Assigned - ES Cell QC In Progress') a ON a.id = mi_plan_status_stamps.mi_plan_id WHERE a.id IS NULL AND mi_plan_statuses.name = 'Assigned - ES Cell QC Complete'"
  a=MiPlan::StatusStamp.find_by_sql(sql)
  puts "#{a.count} Assigned - ES Cell QC In Progress status missing ..."
  a.each do |record|
      rec = MiPlan::StatusStamp.new(:mi_plan_id=> record.mi_plan_id, :created_at => record.created_at, :status_id=> MiPlan::Status.find_by_name!("Assigned - ES Cell QC In Progress").id)
      rec.save!
  end
  puts "... #{a.count} Assigned - ES Cell QC In Progress status added"

  #Selects all mi attempt ids that have Es cell in progress but missing the Assigned status
  sql = "SELECT mi_plan_status_stamps.id, mi_plan_status_stamps.mi_plan_id, mi_plan_status_stamps.status_id, mi_plan_status_stamps.created_at, mi_plan_status_stamps.updated_at FROM mi_plan_status_stamps INNER JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plan_status_stamps.status_id LEFT OUTER JOIN (SELECT mi_plan_status_stamps.mi_plan_id AS id FROM (mi_plan_status_stamps INNER JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plan_status_stamps.status_id) WHERE mi_plan_statuses.name = 'Assigned') a ON a.id = mi_plan_status_stamps.mi_plan_id WHERE a.id IS NULL AND mi_plan_statuses.name = 'Assigned - ES Cell QC In Progress'"
  a=MiPlan::StatusStamp.find_by_sql(sql)
  puts "#{a.count} Assigned status missing ..."
  a.each do |record|
      rec = MiPlan::StatusStamp.new(:mi_plan_id=> record.mi_plan_id, :created_at => record.created_at, :status_id=> MiPlan::Status.find_by_name!("Assigned").id)
      rec.save!
  end
  puts "... #{a.count} Assigned status added"

  #Selects all mi attempt ids that have Es cell Aborted but missing the Assigned status
  sql = "SELECT mi_plan_status_stamps.id, mi_plan_status_stamps.mi_plan_id, mi_plan_status_stamps.status_id, mi_plan_status_stamps.created_at, mi_plan_status_stamps.updated_at FROM mi_plan_status_stamps INNER JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plan_status_stamps.status_id LEFT OUTER JOIN (SELECT mi_plan_status_stamps.mi_plan_id AS id FROM (mi_plan_status_stamps INNER JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plan_status_stamps.status_id) WHERE mi_plan_statuses.name = 'Assigned') a ON a.id = mi_plan_status_stamps.mi_plan_id WHERE a.id IS NULL AND mi_plan_statuses.name = 'Aborted - ES Cell QC Failed'"
  a=MiPlan::StatusStamp.find_by_sql(sql)
  puts "#{a.count} Assigned status missing ..."
  a.each do |record|
      rec = MiPlan::StatusStamp.new(:mi_plan_id=> record.mi_plan_id, :created_at => record.created_at, :status_id=> MiPlan::Status.find_by_name!("Assigned").id)
      rec.save!
  end
  puts "... #{a.count} Assigned status added"



  #Selects all miPlan ids that are aborted and have a status that is older than the aborted date
  sql = "SELECT mi_plan_status_stamps.id, s1.name FROM ((mi_plan_status_stamps INNER JOIN mi_plan_statuses s1 ON mi_plan_status_stamps.status_id = s1.id) INNER JOIN mi_plans ON mi_plan_status_stamps.mi_plan_id = mi_plans.id) INNER JOIN  mi_plan_statuses s2 ON mi_plans.status_id = s2.id WHERE s1.name = 'Aborted - ES Cell QC Failed' AND s2.name != 'Aborted - ES Cell QC Failed'"
  a=MiPlan::StatusStamp.find_by_sql(sql)
  puts "#{a.count} incorrect Aborted status ..."
  a.each do |record|
      rec = MiPlan::StatusStamp.find_by_id!(record.id).destroy
  end
  puts "... #{a.count} Aborted status deleted"

#raise 'TEST'
end







