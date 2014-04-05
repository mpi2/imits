#!/usr/bin/env ruby

require 'pp'

sql = <<END

select distinct genes.id , marker_symbol
from
genes join mi_plans on genes.id = mi_plans.gene_id
join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
where
phenotype_attempts.status_id in (2)
and genes.id not in (
select distinct gene_id from mi_plans join phenotype_attempts on mi_plans.id = phenotype_attempts.mi_plan_id
where phenotype_attempts.status_id in (1,3,4,5,6,7,8)
) order by marker_symbol;

END

rows = ActiveRecord::Base.connection.execute(sql)

hash = {}

rows.each do |row|
  hash[row['marker_symbol']] = row
end


SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")
puts "#### index: #{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}"

proxy = SolrBulk::Proxy.new(SOLR_UPDATE[Rails.env]['index_proxy']['ck'])
json = { :q => '*:*' }
docs = proxy.search(json)

hash2 = {}

docs.each do |doc|
  next if doc['latest_project_status'] != 'Phenotype Attempt Registered'
  hash2['marker_symbol'] = doc
end

puts "#### old/new: #{hash.keys.size}/#{hash2.keys.size}"

