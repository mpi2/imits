#!/usr/bin/env ruby

ApplicationModel.audited_transaction do


  consortium_id = Consortium.find_by_name('MGP Legacy').id
  centre_id = Centre.find_by_name('WTSI').id
  sql = "SELECT mi_attempts.* FROM mi_attempts INNER JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id INNER JOIN consortia ON consortia.id = mi_plans.consortium_id WHERE consortia.name = 'MGP' AND mi_attempts.mi_date < '2011/6/1'"
  a = MiAttempt.find_by_sql(sql)
  puts " #{a.count} mi attempts to correct"
  a.each do |mi_attempt|
    plan = mi_attempt.mi_plan
    if !MiPlan.find_by_gene_id_and_consortium_id_and_production_centre_id(plan.gene_id, consortium_id, centre_id).nil?
      newplan = MiPlan.find_by_gene_id_and_consortium_id_and_production_centre_id(plan.gene_id, consortium_id, centre_id)
    else
      newplan = MiPlan.new({
                        :gene_id => plan.gene_id,
                        :consortium_id => consortium_id,
                        :status_id => plan.status_id,
                        :priority_id => plan.priority_id,
                        :production_centre_id => centre_id,
                        :created_at => plan.created_at,
                        :updated_at => plan.updated_at,
                        :number_of_es_cells_starting_qc => plan.number_of_es_cells_starting_qc,
                        :number_of_es_cells_passing_qc => plan.number_of_es_cells_passing_qc,
                        :sub_project_id => plan.sub_project_id,
                        :is_active => plan.is_active,
                        :is_bespoke_allele => plan.is_bespoke_allele,
                        :is_conditional_allele => plan.is_conditional_allele,
                        :is_deletion_allele => plan.is_deletion_allele,
                        :is_cre_knock_in_allele => plan.is_cre_knock_in_allele,
                        :is_cre_bac_allele => plan.is_cre_bac_allele,
                        :comment => plan.comment,
                        :withdrawn  => plan.withdrawn
                        })
      if newplan.valid?
        newplan.save!
        puts "mi plan: #{mi_attempt.id} #{mi_attempt.mi_plan.id} #{mi_attempt.mi_plan.consortium.name}"
        puts "mi plan successfully created: #{mi_attempt.id} #{mi_attempt.mi_plan.id} #{mi_attempt.mi_plan.consortium.name}"
        puts ''
      else
        puts "mi plan failed: #{newplan.errors}"
      end
    end
    puts 'attached mi_attempt to new MGP Legacy plan'
    mi_attempt.mi_plan_id = newplan.id
    if mi_attempt.valid?
      puts "#{mi_attempt.id}"
      mi_attempt.save!
      puts '    reassigned mi_plan'
    else
      puts '     unsuccessful re asignment of mi_plan'
    end
  end

  raise 'TEST'
end