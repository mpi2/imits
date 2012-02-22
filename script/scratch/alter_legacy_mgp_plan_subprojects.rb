nothing = MiPlan::SubProject.find_by_name!('')
legacy_eucomm = MiPlan::SubProject.find_by_name!('Legacy EUCOMM')
legacy_komp = MiPlan::SubProject.find_by_name!('Legacy KOMP')
mgp_interest = MiPlan::SubProject.find_by_name!('MGPinterest')
mgp_legacy = MiPlan::SubProject.find_by_name!('MGP Legacy')

puts "id of nothing subproject: #{nothing.id}"

mgp_consortium = Consortium.find_by_name("MGP")

MiPlan.transaction do
  Audit.as_user(User.find_by_email!("vvi@sanger.ac.uk")) do
    
    #Move all Legacy EUCOMM to MGP Legacy
    legacy_plans = MiPlan.where({:consortium_id => mgp_consortium.id, :sub_project_id => legacy_eucomm.id})
    puts "number of legacy eucomm plans #{legacy_plans.length}"
    legacy_plans.each do |plan|
      plan.sub_project = mgp_legacy
      plan.save!
    end
    
    legacy_plans = MiPlan.where({:consortium_id => mgp_consortium.id, :sub_project_id => legacy_komp.id})
    puts "number of legacy komp plans #{legacy_plans.length}"
    legacy_plans.each do |plan|
      plan.sub_project = mgp_legacy
      plan.save!
    end
    
    unset_plans = MiPlan.where({:consortium_id => mgp_consortium.id, :sub_project_id => nothing.id})
    puts "number of default plans #{unset_plans.length}"
    unset_plans.each do |plan|
      plan.sub_project = mgp_interest
      plan.save!
    end
    #raise "ROLLBACK"
  end
end
