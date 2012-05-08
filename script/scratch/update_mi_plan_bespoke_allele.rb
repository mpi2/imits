bespoke_sub_project = MiPlan::SubProject.find_by_name("WTSI_Bespoke_A")
mi_plans = MiPlan.where(:sub_project_id => bespoke_sub_project.id)
count = 0
MiPlan.transaction do
  Audit.as_user(User.find_by_email!("gj2@sanger.ac.uk")) do

    mi_plans.each do |this_mi_plan|
      this_mi_plan.is_bespoke_allele = true
      if this_mi_plan.save!
         count = count + 1
      end
    end

  end
end
  puts count
