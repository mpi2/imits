legacy_mis = []
dtcc_consortium = Consortium.find_by_name!('DTCC')
legacy_consortium = Consortium.find_by_name!('DTCC-Legacy')
ucd = Centre.find_by_name!('UCD')
assigned = MiPlan::Status.find_by_name!('Assigned')

File.open("mis_to_move_to_dtcc_legacy.csv").each do |line|
  line.chomp!
  legacy_mis << line
  #break
end

MiPlan.transaction do
  Audit.as_user(User.find_by_email!("vvi@sanger.ac.uk")) do
    legacy_mis.each do |id|
      
      mi = MiAttempt.find_by_id(id)
      if(mi)
        puts "plan: #{mi.id} cons #{mi.mi_plan.consortium.name}"
      else
        raise "no mi for id: #{id}"
      end
      
      old_plan = mi.mi_plan
      gene = old_plan.gene
      if(old_plan.consortium.name == 'DTCC-Legacy')
        puts "mi #{mi.id} has already moved to legacy consortium"
      else
        existing_legacy_plans = MiPlan.where({:consortium_id=>legacy_consortium.id, :gene_id=>gene.id})
        new_plan = nil
        if(existing_legacy_plans.empty?)
          new_plan = old_plan.clone()
          new_plan.consortium = legacy_consortium
          new_plan.save!
          new_plan.status = assigned
        else
          new_plan = existing_legacy_plans.first
        end
        mi.mi_plan = new_plan
        mi.save!
        puts "Saved new legacy plan (#{new_plan.id}) for #{old_plan.consortium.name} and transferred MI"
      end
    end
  #raise "ROLLBACK"
  end
end