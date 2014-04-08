#!/usr/bin/env ruby

require 'pp'

#imits_development=# select * from mi_attempt_statuses order by order_by;
# id |            name             |         created_at         |         updated_at         | order_by | code
#----+-----------------------------+----------------------------+----------------------------+----------+------
#  3 | Micro-injection aborted     | 2011-07-26 15:21:59.156245 | 2012-07-26 13:38:08.365281 |      210 | abt
#  1 | Micro-injection in progress | 2011-07-13 11:10:01.227023 | 2012-07-26 13:38:08.357856 |      220 | mip
#  4 | Chimeras obtained           | 2012-03-23 12:00:44.693233 | 2012-07-26 13:38:08.368332 |      230 | chr
#  2 | Genotype confirmed          | 2011-07-13 11:10:01.260259 | 2012-07-26 13:38:08.361959 |      240 | gtc
#(4 rows)

#imits_development=# select * from phenotype_attempt_statuses order by order_by;
# id |             name             |         created_at         |         updated_at         | order_by | code
#----+------------------------------+----------------------------+----------------------------+----------+------
#  1 | Phenotype Attempt Aborted    | 2011-12-19 13:38:41.161482 | 2012-08-23 15:38:16.852707 |      310 | abt
#  2 | Phenotype Attempt Registered | 2011-12-19 13:38:41.172022 | 2012-07-26 13:38:08.670883 |      320 | par
#  3 | Rederivation Started         | 2011-12-19 13:38:41.176757 | 2012-07-26 13:38:08.674262 |      330 | res
#  4 | Rederivation Complete        | 2011-12-19 13:38:41.181782 | 2012-07-26 13:38:08.676625 |      340 | rec
#  5 | Cre Excision Started         | 2011-12-19 13:38:41.186843 | 2012-07-26 13:38:08.67926  |      350 | ces
#  6 | Cre Excision Complete        | 2011-12-19 13:38:41.19204  | 2012-07-26 13:38:08.681483 |      360 | cec
#  7 | Phenotyping Started          | 2011-12-19 13:38:41.197146 | 2012-07-26 13:38:08.683849 |      370 | pds
#  8 | Phenotyping Complete         | 2011-12-19 13:38:41.201884 | 2012-07-26 13:38:08.686295 |      380 | pdc
#(8 rows)

sql = <<END

select count(distinct gene_id) as count from phenotype_attempts, mi_plans, genes
where phenotype_attempts.mi_plan_id = mi_plans.id and
genes.id = mi_plans.gene_id and
phenotype_attempts.status_id = (select id from phenotype_attempt_statuses where name = 'SUBS_TEMPLATE')
--and phenotype_attempts.report_to_public is true
--and mi_plans.report_to_public is true;

END

sql = <<END
select count(distinct gene_id) as count from mi_attempts, mi_plans, genes
where mi_attempts.mi_plan_id = mi_plans.id and
genes.id = mi_plans.gene_id and
mi_attempts.status_id = (select id from mi_attempt_statuses where name = 'SUBS_TEMPLATE')
and mi_attempts.report_to_public is true
and mi_plans.report_to_public is true;
END

sql = <<END
select count(distinct genes.id)
from
genes join mi_plans on genes.id = mi_plans.gene_id
join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
where
phenotype_attempts.status_id in (2)
and phenotype_attempts.report_to_public is true
and genes.id not in (
select distinct gene_id from mi_plans join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
where phenotype_attempts.status_id in (1,3,4,5,6,7,8)
) --order by marker_symbol;
END

sql = <<END
select count(distinct genes.id)
from
genes join mi_plans on genes.id = mi_plans.gene_id
join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
where
phenotype_attempts.status_id in (select id from phenotype_attempt_statuses where name = 'SUBS_TEMPLATE')
--and phenotype_attempts.report_to_public is true
and phenotype_attempts.cre_excision_required is not true
and genes.id not in (
select distinct gene_id from mi_plans join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
where phenotype_attempts.status_id in (select id from phenotype_attempt_statuses where name <> 'SUBS_TEMPLATE')
and phenotype_attempts.cre_excision_required is not true
--and phenotype_attempts.report_to_public is true
)
END

#{"Phenotyping Started"=>"699",
# "Cre Excision Complete"=>"685",
# "Cre Excision Started"=>"243",
# "Phenotype Attempt Registered"=>"422"}

#{"Phenotyping Started"=>"702",
# "Cre Excision Complete"=>"701",
# "Cre Excision Started"=>"246",
# "Phenotype Attempt Registered"=>"439"}

#{"Genotype confirmed"=>"3553",
# "Chimeras obtained"=>"1103",
# "Micro-injection in progress"=>"396"}

#{"Genotype confirmed"=>"3635",
# "Chimeras obtained"=>"1259",
# "Micro-injection in progress"=>"437"}

#{"Phenotyping Started"=>"609",
# "Cre Excision Complete"=>"597",
# "Cre Excision Started"=>"207",
# "Phenotype Attempt Registered"=>"382"
# }

PA_STATUSES = ["Phenotyping Started","Cre Excision Complete","Cre Excision Started"]    #,"Phenotype Attempt Registered"]
#PA_STATUSES = ["Phenotype Attempt Registered"]
MI_STATUSES = ["Genotype confirmed","Chimeras obtained","Micro-injection in progress"]

hash = {}

PA_STATUSES.each do |status|
  tsql = sql.gsub(/SUBS_TEMPLATE/, status)
  rows = ActiveRecord::Base.connection.execute(tsql)
  rows.each do |row|
    hash[status] = row['count']
  end
end

pp hash

# WITH REPORT_TO_PUBLIC

#{
#  "responseHeader":{
#    "status":0,
#    "QTime":39,
#    "params":{
#      "facet":"true",
#      "indent":"on",
#      "q":"*:*",
#      "facet.field":"latest_project_status_str",
#      "wt":"json",
#      "rows":"0"}},
#  "response":{"numFound":145551,"start":0,"docs":[]
#  },
#  "facet_counts":{
#    "facet_queries":{},
#    "facet_fields":{
#      "latest_project_status_str":[
#        "No ES Cell Production",43378,
#        "ES Cell Targeting Confirmed",8800,
#        "ES Cell Production in Progress",3111,
#        "Genotype confirmed",1683,
#        "Chimeras obtained",1036,
#        "Phenotyping Started",683,
#        "Cre Excision Complete",622,
#        "Micro-injection in progress",286,
#        "Cre Excision Started",210,
#        "Phenotype Attempt Registered",97,
#        "",35]},
#    "facet_dates":{},
#    "facet_ranges":{}}}

# WITHOUT REPORT_TO_PUBLIC

#{
#  "responseHeader":{
#    "status":0,
#    "QTime":67,
#    "params":{
#      "facet":"true",
#      "indent":"on",
#      "q":"*:*",
#      "facet.field":"latest_project_status_str",
#      "wt":"json",
#      "rows":"0"}},
#  "response":{"numFound":145682,"start":0,"docs":[]
#  },
#  "facet_counts":{
#    "facet_queries":{},
#    "facet_fields":{
#      "latest_project_status_str":[
#        "No ES Cell Production",43218,
#        "ES Cell Targeting Confirmed",8716,
#        "ES Cell Production in Progress",3101,
#        "Genotype confirmed",1687,
#        "Chimeras obtained",1183,
#        "Phenotyping Started",691,
#        "Cre Excision Complete",668,
#        "Micro-injection in progress",321,
#        "Cre Excision Started",219,
#        "Phenotype Attempt Registered",97,
#        "",40]},
#    "facet_dates":{},
#    "facet_ranges":{}}}
