#### ES Cell lines

# 1- Check status stamps order

MiAttempt.where(is_active: true, status_id: 2).joins(:mi_plan).where(mi_plans: { mutagenesis_via_crispr_cas9: false }).each do |mi|
  ss = mi.status_stamps

  genotype_confirmed_stamp = ss.select { |stamp| stamp.status_id == 2 }.first
  chimeras_founders_stamp = ss.select { |stamp| stamp.status_id == 6 }.first

  if genotype_confirmed_stamp.created_at < chimeras_founders_stamp.created_at
    chimeras_founders_stamp.created_at = genotype_confirmed_stamp.created_at - 1.day
    chimeras_founders_stamp.updated_at = genotype_confirmed_stamp.updated_at - 1.day
    chimeras_founders_stamp.save!
  end
end

# 2- Abort plans and attempts that are older than one year

d =  Time.now() - 1.year

# check phenotyping_productions and mouse_allele_mods
pp_sql = "UPDATE phenotyping_productions SET is_active = false FROM phenotyping_productions pp LEFT JOIN mi_plans p ON pp.mi_plan_id = p.id WHERE pp.is_active = true AND pp.status_id = 1 AND p.mutagenesis_via_crispr_cas9 = false AND pp.updated_at < now() - INTERVAL '12 MONTHS';"

ActiveRecord::Base.connection.execute(pp_sql)

mam_sql = "UPDATE mouse_allele_mods SET is_active = false FROM mouse_allele_mods mam LEFT JOIN mi_plans p ON mam.mi_plan_id = p.id WHERE mam.is_active = true AND mam.status_id = 1 AND p.mutagenesis_via_crispr_cas9 = false AND mam.updated_at < now() - INTERVAL '12 MONTHS';"

ActiveRecord::Base.connection.execute(mam_sql)

# check mi_attempts

mi_sql = "UPDATE mi_attempts SET is_active = false FROM mi_attempts mi LEFT JOIN mi_plans p ON mi.mi_plan_id = p.id WHERE mi.is_active = true AND mi.status_id IN (1,4,5,6) AND p.mutagenesis_via_crispr_cas9 = false AND mi.updated_at < now() - INTERVAL '12 MONTHS';"

ActiveRecord::Base.connection.execute(mi_sql)

# check mi_plans (production and only phenotyping)

p_sql = "select p.id, ARRAY_AGG(mi.status_id) from mi_plans p left join mi_attempts mi on p.id = mi.mi_plan_id where p.mutagenesis_via_crispr_cas9 = false and p.is_active = true group by p.id order by p.id;"

results = ActiveRecord::Base.connection.execute(p_sql)

null_values = []
plan_aborted = []

results.each do |r|
  arr_uniq = r["array_agg"].tr('{}', '').split(',').map(&:to_i).uniq
  puts
  puts arr_uniq, arr_uniq.length
  puts
  if arr_uniq.length == 1
    if arr_uniq[0] == 3
      p = MiPlan.find(r['id'])
      if [1,2,3,4,5,6,8,12,13,14].include?(p.status_id) && p.updated_at < d
      	plan_aborted << p.id
      	p.is_active = false
      	p.save!
      end
    elsif arr_uniq[0] == 0
      null_values << r["id"]
    end
  elsif arr_uniq.length == 0
  	null_values << r["id"]
  end
end

plan_aborted = []
null_values.each do |id|
  p = MiPlan.find(id)

  if p.phenotype_only?
  	pps = p.phenotyping_productions
  	if pps.length == 0
  	  p.is_active = false
      p.save!
      plan_aborted << id
    else
      pp = pps.first
      if pp.is_active == false
      	p.is_active = false
        p.save!
        plan_aborted << id
      end
  	end
  else
  	mis = p.mi_attempts
  	if mis.length == 0
  	  p.is_active = false
      p.save!
      plan_aborted << id
  	end
  end
end













