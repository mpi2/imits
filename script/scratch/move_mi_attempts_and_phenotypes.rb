questions = {}

sql= <<-EOF
SELECT DISTINCT mi_plans.*
  FROM mi_plans
  JOIN consortia ON consortia.id = mi_plans.consortium_id
  JOIN centres ON centres.id = mi_plans.production_centre_id
  JOIN mi_attempts ON mi_attempts.mi_plan_id = mi_plans.id
  WHERE consortia.name = 'DTCC' AND mi_attempts.mi_date < '2011/06/01'
EOF

mi_plans_with_incorrect_mis = MiPlan.find_by_sql(sql);nil

#does DTCC plan have any other mouse production or phenotype production.
mi_plans_with_incorrect_mis.each do |plan|
  questions[plan.id] = {'plan has other mouse production' => {'result'=>0},
                        'plan has phenotype_attempts' => {'result'=>0},
                        'mis to change' => {'result'=>0},
                        'error' => {'result'=>0},
                        'existing plan for ucd komp' => {'result'=>0},
                        'phenotype only plan' => {'result' => 0}
                       }

  mis_to_change = plan.mi_attempts.where("mi_date <'2011/06/01'")
  if mis_to_change.count > 0
    questions[plan.id]['mis to change']['result'] = 1
    questions[plan.id]['mis to change']['mi_ids'] = mis_to_change.map{|a| a.id}
  end

  other_mis = plan.mi_attempts.where("mi_date >='2011/06/01'")
  if other_mis.count > 0
    questions[plan.id]['plan has other mouse production']['result'] = 1
    questions[plan.id]['plan has other mouse production']['mi_ids'] = other_mis.map{|a| a.id}
  end

  other_pas = plan.phenotype_attempts
  if other_pas.count > 0
    questions[plan.id]['plan has phenotype_attempts']['result'] = 1
    questions[plan.id]['plan has phenotype_attempts']['pa_ids'] = other_pas.map{|a| a.id}
  end
  sql= <<-EOF
    SELECT mi_plans.*
      FROM mi_plans
      JOIN consortia ON consortia.id = mi_plans.consortium_id
      WHERE consortia.name = 'UCD-KOMP' AND mi_plans.gene_id = #{plan.gene_id} AND mi_plans.production_centre_id = #{plan.production_centre_id}
  EOF
  ucd_komp_plan = MiPlan.find_by_sql(sql);nil
  if ucd_komp_plan.count > 1
    questions[plan.id]['error']['result'] = 1
    questions[plan.id]['error']['message'] = "many ucd-komp plans for gene (#{plan.gene.marker_symbol})"
  elsif ucd_komp_plan.count == 1
    ucd_komp_plan = ucd_komp_plan.first
    questions[plan.id]['existing plan for ucd komp']['result'] = 1
    questions[plan.id]['existing plan for ucd komp']['mi_plan_id'] = ucd_komp_plan.id
    questions[plan.id]['existing plan for ucd komp']['mouse production'] = {'result' => 0}
    questions[plan.id]['existing plan for ucd komp']['phenotype production'] = {'result' => 0}

    ucd_komp_mi = ucd_komp_plan.mi_attempts
    if ucd_komp_mi.count > 0
      questions[plan.id]['existing plan for ucd komp']['mouse production']['result'] = 1
      questions[plan.id]['existing plan for ucd komp']['mouse production']['mi_ids'] = ucd_komp_mi.map{|a| a.id}
    end

    ucd_komp_pa = ucd_komp_plan.phenotype_attempts
    if ucd_komp_pa.count > 0
      questions[plan.id]['existing plan for ucd komp']['phenotype production']['result'] = 1
      questions[plan.id]['existing plan for ucd komp']['phenotype production']['pa_ids'] = ucd_komp_pa.map{|a| a.id}
    end
  else
    questions[plan.id]['existing plan for ucd komp']['result'] = 0
  end

  sql= <<-EOF
    SELECT mi_plans.*
      FROM mi_plans
      JOIN consortia ON consortia.id = mi_plans.consortium_id
      WHERE consortia.name = 'DTCC' AND mi_plans.gene_id = #{plan.gene_id} AND mi_plans.production_centre_id = #{plan.production_centre_id} AND mi_plans.phenotype_only = true
  EOF
  dtcc_plan_phenotype_only = MiPlan.find_by_sql(sql);nil
  if dtcc_plan_phenotype_only.count > 1
    questions[plan.id]['error']['result'] = 1
    questions[plan.id]['error']['message'] = "many phenotype only plans for DTCC (#{plan.gene.marker_symbol})"
  elsif dtcc_plan_phenotype_only.count == 1
    dtcc_plan_phenotype_only = dtcc_plan_phenotype_only.first
    questions[plan.id]['phenotype only plan']['result'] = 1
    questions[plan.id]['phenotype only plan']['mi_plan_id'] = dtcc_plan_phenotype_only.id
  end
end; nil


ApplicationModel.audited_transaction do
  questions.each do |key, data|

    ##if phenotype_attempt belongs to mi_attempt < june 2011 move to phenotype_only plan

   if data['plan has other mouse production']['result'] == 0 and data['plan has phenotype_attempts']['result'] == 0 and data['existing plan for ucd komp']['result'] == 0
     # change consortia
     mi_plan = MiPlan.find(key)
     mi_plan.consortium = Consortium.find_by_name('UCD-KOMP')
     if mi_plan.valid?
       mi_plan.save
     else
       puts "ERROR: Could not save #{mi_plan.id} plan. #{mi_plan.errors.messages}"
     end

    elsif data['plan has other mouse production']['result'] == 0 and data['plan has phenotype_attempts']['result'] == 0 and data['existing plan for ucd komp']['result'] == 1
      ## re-assign phenotype_attempts to either an existing DTCC plan or a new DTCC plan (phenotype_only)
      if data['existing plan for ucd komp']['phenotype production']['result'] == 1
        if data['phenotype only plan']['result'] == 1
          puts 'Hello'
          puts data
          data['existing plan for ucd komp']['phenotype production']['pa_ids'].each do |pa_id|
            pa_to_reassign_to_dtcc = Public::PhenotypeAttempt.find(pa_id)
            pa_to_reassign_to_dtcc.mi_plan_id = data['phenotype only plan']['mi_plan_id']
            if pa_to_reassign_to_dtcc.valid?
              pa_to_reassign_to_dtcc.save
            else
              puts "ERROR: Could not re-assign phenotype_attempt to DTCC phenotype_only plan (#{data['phenotype only plan']['mi_plan_id']}). #{pa_to_reassign_to_dtcc.errors.messages}"
            end
          end
        else
          current_mi_plan = MiPlan.find(key)
          new_plan = MiPlan.new
          new_plan.consortium_id = current_mi_plan.consortium_id
          new_plan.production_centre_id = current_mi_plan.production_centre_id
          new_plan.gene_id = current_mi_plan.gene_id
          new_plan.priority_id = current_mi_plan.priority_id
          new_plan.phenotype_only = true
          if new_plan.valid?
            new_plan.save
            data['existing plan for ucd komp']['phenotype production']['pa_ids'].each do |pa_id|
              pa_to_reassign_to_dtcc = Public::PhenotypeAttempt.find(pa_id)
              pa_to_reassign_to_dtcc.mi_plan = new_plan
              if pa_to_reassign_to_dtcc.valid?
                pa_to_reassign_to_dtcc.save
              else
                puts "ERROR: Could not re-assign phenotype_attempt to DTCC phenotype_only plan (#{new_plan.id}). #{pa_to_reassign_to_dtcc.errors.messages}"
              end
            end
          else
            puts "ERROR: Could not create new DTCC phenotype_only plan (#{key}). #{new_plan.errors.messages}"
          end
        end
      end

      ## re-assign mi_attempts to existing DTCC mi_plan
      if data['existing plan for ucd komp']['mouse production']['result'] == 1
        data['existing plan for ucd komp']['mouse production']['mi_ids'].each do |mi_key|
          mi_attempt_re_assign_to_dtcc_plan = Public::MiAttempt.find(mi_key)
          dtcc_plan = MiPlan.find(key)
          dtcc_plan_is_active = dtcc_plan.is_active
          dtcc_plan.is_active = true
          dtcc_plan.save
          mi_attempt_re_assign_to_dtcc_plan.mi_plan = dtcc_plan
          if mi_attempt_re_assign_to_dtcc_plan.valid?
            mi_attempt_re_assign_to_dtcc_plan.save
          else
            puts "ERROR: Could not re-assign mi_attempt to DTCC plan (#{mi_attempt_re_assign_to_dtcc_plan.mi_plan.id}). #{mi_attempt_re_assign_to_dtcc_plan.errors.messages}"
          end
          dtcc_plan.is_active = dtcc_plan_is_active
          dtcc_plan.save
        end
      end

      #delete UCD-KOMP plans
      mi_plan = MiPlan.find(data['existing plan for ucd komp']['mi_plan_id'])
      if mi_plan.destroy
        puts "plan deleted."
      else
        puts "ERROR: Could not delete #{mi_plan.id} plan. #{mi_plan.errors.messages}"
      end

      #change consortia after mi_attempts and phenotype attempts on exisiting UCD-KOMP have been reassigned to dtcc plan
      mi_plan = MiPlan.find(key)
      mi_plan.reload
      mi_plan.consortium = Consortium.find_by_name('UCD-KOMP')
      if mi_plan.valid?
        mi_plan.save
      else
        puts "ERROR: Could not save #{mi_plan.id} plan. #{mi_plan.errors.messages}"
      end

    elsif data['plan has other mouse production']['result'] == 1 or data['plan has phenotype_attempts']['result'] == 1
      if data['existing plan for ucd komp']['result'] == 1
        data['mis to change']['mi_ids'].each do |mis|
          mi_attempt_to_reassign_to_ucd_komp = Public::MiAttempt.find(mis)
          mi_attempt_to_reassign_to_ucd_komp.mi_plan = MiPlan.find(data['existing plan for ucd komp']['mi_plan_id'])
          if mi_attempt_to_reassign_to_ucd_komp.valid?
            mi_attempt_to_reassign_to_ucd_komp.save
          else
            puts "ERROR: Could not re-assign mi_attempt to plan #{mi_attempt_to_reassign_to_ucd_komp.mi_plan_id}. #{mi_attempt_to_reassign_to_ucd_komp.errors.messages}"
          end
        end
      else
        current_mi_plan = MiPlan.find(key)
        new_plan = MiPlan.new
        new_plan.consortium = Consortium.find_by_name('UCD-KOMP')
        new_plan.production_centre_id = current_mi_plan.production_centre_id
        new_plan.gene_id = current_mi_plan.gene_id
        new_plan.priority_id = current_mi_plan.priority_id
        if new_plan.valid?
          new_plan.save

          data['mis to change']['mi_ids'].each do |mi_id|
            mi_to_reassign = Public::MiAttempt.find(mi_id)
            mi_to_reassign.mi_plan = new_plan
            if mi_to_reassign.valid?
              mi_to_reassign.save
            else
              puts "ERROR: Could not re-assign mi_attempt(#{mi_to_reassign.mi_plan_id}). #{mi_to_reassign.errors.messages}"
            end
          end
        else
          puts "ERROR: Could not create new UCD-KOMP plan (#{key}). #{new_plan.errors.messages}"
        end
      end

      #check DTCC plan does not need to be changed to phenotype_only
      pao_plan = MiPlan.find(key)
      pa = pao_plan.phenotype_attempts
      pa_only = []
      if pa.count >0
        pa.each do |phenotype|
          if phenotype.mi_plan != phenotype.mi_attempt.mi_plan
            pa_only << phenotype.id
          end
        end
      end

      ma = pao_plan.mi_attempts
      new_pa_only_plan = false
      if ma.count>0
        new_pa_only_plan = true
      end

      #change plan to phenotype_only
      if new_pa_only_plan == false and pa_only.count > 0
        pao_plan.phenotype_only = true
        if pao_plan.valid?
          pao_plan.save
        else
          puts "ERROR: Could not change plan to phenotype_only (#{pao_plan.id}). #{pao_plan.errors.messages}"
        end

      elsif new_pa_only_plan == true and pa_only.count > 0

        new_plan = MiPlan.new
        new_plan.consortium_id = pao_plan.consortium_id
        new_plan.production_centre_id = pao_plan.production_centre_id
        new_plan.gene_id = pao_plan.gene_id
        new_plan.priority_id = pao_plan.priority_id
        new_plan.phenotype_only = true
        if new_plan.valid?
          new_plan.save
          pa_only.each do |pa_id|
            pa_to_reassign_to_dtcc = Public::PhenotypeAttempt.find(pa_id)
            pa_to_reassign_to_dtcc.mi_plan = new_plan
            if pa_to_reassign_to_dtcc.valid?
              pa_to_reassign_to_dtcc.save
            else
              puts "ERROR: Could not re-assign phenotype_attempt to DTCC phenotype_only plan (#{new_plan.id}). #{pa_to_reassign_to_dtcc.errors.messages}"
            end
          end
        else
          puts "ERROR: Could not create new DTCC phenotype_only plan (#{pao_plan.id}). #{new_plan.errors.messages}"
        end
      end
    end
  end

end; nil

