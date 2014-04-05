#!/usr/bin/env ruby

require 'pp'

# get hash of genes
# get counts for each status

SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")
puts "#### index: #{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}"

proxy = SolrBulk::Proxy.new(SOLR_UPDATE[Rails.env]['index_proxy']['ck'])
json = { :q => '*:*' }
docs = proxy.search(json)

#pp docs.first

genes_hash = {}
status_hash = {}
final_status_hash = {}

docs.each do |doc|
  genes_hash[doc['marker_symbol']] ||= []
  genes_hash[doc['marker_symbol']].push doc
end

genes_hash.keys.each do |marker_symbol|
  status_hash[marker_symbol] = genes_hash[marker_symbol].first['latest_project_status']
end

status_hash.keys.each do |marker_symbol|
  final_status_hash[status_hash[marker_symbol]] ||= 0
  final_status_hash[status_hash[marker_symbol]] += 1
end

pp final_status_hash

#{"Genotype confirmed"=>2340,
# "Phenotyping Started"=>683,
# "ES Cell Targeting Confirmed"=>8898,
# "ES Cell Production in Progress"=>3145,
# "Chimeras obtained"=>1049,
# "Phenotype Attempt Registered"=>108,
# ""=>51,
# "Micro-injection in progress"=>287,
# "Cre Excision Started"=>2,
# "No ES Cell Production"=>43378}

def get_count sql
  rows = ActiveRecord::Base.connection.execute(sql)

  count = 0
  rows.each do |row|
    count = row['count']
  end

  count
end

# "ES Cell Targeting Confirmed"=>8898,
# "ES Cell Production in Progress"=>3145,
# ""=>51,
# "No ES Cell Production"=>43378

pa_statuses = ['Phenotyping Started', 'Phenotype Attempt Registered', "Cre Excision Started"]

pa_statuses.each do |status|
  sql = "select count(*) as count from phenotype_attempts where report_to_public is true and status_id in (select id from phenotype_attempt_statuses where name = '#{status}')"
  count = get_count sql
  puts "#### #{status}: db/index: #{count}/#{final_status_hash[status]}"
end

mi_statuses = ['Genotype confirmed', "Chimeras obtained", "Micro-injection in progress"]

mi_statuses.each do |status|
  sql = "select count(*) as count from mi_attempts where report_to_public is true and status_id in (select id from mi_attempt_statuses where name = '#{status}')"
  count = get_count sql
  puts "#### #{status}: db/index: #{count}/#{final_status_hash[status]}"
end

exit





#sql = "select count(*) as count from phenotype_attempts where report_to_public is true and status_id in (select id from phenotype_attempt_statuses where name = 'Phenotyping Started')"
#count = get_count sql
#puts "#### Phenotyping Started: db/index: #{count}/#{final_status_hash['Phenotyping Started']}"
#
#sql = "select count(*) as count from phenotype_attempts where report_to_public is true and status_id in (select id from phenotype_attempt_statuses where name = 'Phenotype Attempt Registered')"
#count = get_count sql
#puts "#### Phenotype Attempt Registered: db/index: #{count}/#{final_status_hash['Phenotype Attempt Registered']}"

sql = <<END
select distinct
targ_rep_alleles.id as targ_rep_alleles_id,

genes.marker_symbol, genes.marker_type, genes.mgi_accession_id,

CASE WHEN (targ_rep_targeting_vectors.allele_id IS NOT NULL) THEN true else false END AS does_a_targ_vec_exist,
CASE WHEN (targ_rep_es_cells.allele_id IS NOT NULL) THEN true else false END AS does_an_es_cell_exist,

targ_rep_es_cells.mgi_allele_symbol_superscript,
targ_rep_es_cells.allele_symbol_superscript_template,
miapc.name miacentre_name,
mi_attempt_statuses.name as mi_attempt_status,
mi_attempts.mouse_allele_type as mi_mouse_allele_type,
phenotype_attempts.mouse_allele_type as phenotype_attempt_mouse_allele_type,
phenotype_attempts.cre_excision_required,
pacentres.name pacentre_name,
phenotype_attempt_statuses.name as phenotype_attempt_status,
phenotype_attempts.id as phenotype_attempts_id
from genes
left outer join targ_rep_alleles on genes.id = targ_rep_alleles.gene_id
left outer join targ_rep_targeting_vectors on targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id    and targ_rep_targeting_vectors.report_to_public is true
left outer join targ_rep_es_cells on targ_rep_alleles.id = targ_rep_es_cells.allele_id                      and targ_rep_es_cells.report_to_public is true
left outer join mi_attempts on mi_attempts.es_cell_id = targ_rep_es_cells.id                                and mi_attempts.report_to_public is true
left outer join mi_attempt_statuses on mi_attempt_statuses.id = mi_attempts.status_id
left join mi_plans mi_attempt_plan on mi_attempts.mi_plan_id = mi_attempt_plan.id                           and mi_attempt_plan.report_to_public is true
left join centres miapc on mi_attempt_plan.production_centre_id = miapc.id
left outer join phenotype_attempts on phenotype_attempts.mi_attempt_id = mi_attempts.id                     and phenotype_attempts.report_to_public is true
left outer join mi_plans paplan on phenotype_attempts.mi_plan_id = paplan.id                                and paplan.report_to_public is true
left outer join centres pacentres on pacentres.id = paplan.production_centre_id
left outer join phenotype_attempt_statuses on phenotype_attempt_statuses.id = phenotype_attempts.status_id
END

old_phenotype_attempts = []
new_phenotype_attempts = []
new_phenotype_attempts_hash = {}

rows = ActiveRecord::Base.connection.execute(sql)

rows.each do |row|
  next if ! row['phenotype_attempts_id']
  next if row['phenotype_attempt_status'] != 'Phenotyping Started'
  new_phenotype_attempts_hash[row['phenotype_attempts_id']] = 1
end

#PhenotypeAttempt.all.each do |pa|
#  next if pa.has_status?(:abt)
#end

new_phenotype_attempts_hash.keys.each do |id|
  new_phenotype_attempts.push id
end

sql = "select id from phenotype_attempts where report_to_public is true and status_id in (select id from phenotype_attempt_statuses where name = 'Phenotyping Started')"
rows = ActiveRecord::Base.connection.execute(sql)

rows.each do |row|
  old_phenotype_attempts.push row['id']
end

diffs = new_phenotype_attempts - old_phenotype_attempts

puts "#### Phenotyping Started 2: db/index: #{old_phenotype_attempts.size}/#{new_phenotype_attempts.size}"

#pp diffs
puts "#### diffs.size: #{diffs.size}"
