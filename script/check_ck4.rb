#!/usr/bin/env ruby

require 'pp'

sql = <<END
select count(distinct genes.id) as count
from
genes
  join mi_plans on genes.id = mi_plans.gene_id
  join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
where
  phenotype_attempts.status_id in (select id from phenotype_attempt_statuses where name = 'SUBS_TEMPLATE')
  --and phenotype_attempts.report_to_public is true
  --and mi_plans.report_to_public is true
  and phenotype_attempts.cre_excision_required is not true and genes.id not in (
    select distinct gene_id
    from mi_plans
      join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
    where phenotype_attempts.status_id in (select id from phenotype_attempt_statuses where name <> 'SUBS_TEMPLATE') and phenotype_attempts.cre_excision_required is not true
    --and phenotype_attempts.report_to_public is true
  )
END

sql2 = <<END
select count(distinct genes.id)
from
genes join mi_plans on genes.id = mi_plans.gene_id
join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
where
phenotype_attempts.status_id in (select id from phenotype_attempt_statuses where name = 'SUBS_TEMPLATE')
--and phenotype_attempts.report_to_public is true
--and phenotype_attempts.cre_excision_required is not true
and genes.id not in (
select distinct gene_id from mi_plans join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
where phenotype_attempts.status_id in (select id from phenotype_attempt_statuses where name <> 'SUBS_TEMPLATE')
--and phenotype_attempts.cre_excision_required is not true
--and phenotype_attempts.report_to_public is true
)
END

sql3 = <<END
select count(distinct genes.id)
from
genes join mi_plans on genes.id = mi_plans.gene_id
join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
where
phenotype_attempts.status_id in (2)
-and phenotype_attempts.cre_excision_required is not true
--and phenotype_attempts.report_to_public is true
and genes.id not in (
select distinct gene_id from mi_plans join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
where phenotype_attempts.status_id in (3,4,5,6,7,8)
)
END

sql4 = <<END
  select count(distinct genes.id)
  from
  genes join mi_plans on genes.id = mi_plans.gene_id
  join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
  where
  phenotype_attempts.status_id in (2)
  and phenotype_attempts.is_active is true
  and genes.id not in (
  select distinct gene_id from mi_plans join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
  where phenotype_attempts.status_id in (3,4,5,6,7,8)
  )
END

sql5 = <<END
  select count(distinct genes.id)
  from
    genes join mi_plans on genes.id = mi_plans.gene_id
    join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
  where
    phenotype_attempts.status_id in (7)
    and phenotype_attempts.is_active is true
    and genes.id not in (
    select distinct gene_id from mi_plans join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id where phenotype_attempts.status_id in (8)
    )
END

#def get_phenotype_attempt_statuses
#  hash = {}
#  sql = 'select * from phenotype_attempt_statuses order by order_by;'
#  rows = ActiveRecord::Base.connection.execute(sql)
#  rows.each do |row|
#    hash[row['name']] = row['id']
#  end
#
#  hash2 = {}
#  hash.keys.each do |key|
#  end
#
#  hash
#end

# if cre_excision_required is true AND phenotype_status is early then doc's phenotype_status blanked-out

TARGETS = {
  "Phenotype Attempt Registered" => sql4,
  "Phenotyping Started" => sql5,
  #"Phenotype Attempt Registered" => sql,
  #"Phenotyping Started" => sql2,
  #"Cre Excision Complete" => sql2,
  #"Cre Excision Started" => sql2
}

hash = {}

TARGETS.keys.each do |status|
  tsql = sql.gsub(/SUBS_TEMPLATE/, status)
  rows = ActiveRecord::Base.connection.execute(tsql)
  rows.each do |row|
    hash[status] = row['count']
  end
end

pp hash

#        "Phenotype Attempt Registered",97,

#{"Phenotype Attempt Registered"=>"108"}
