#!/usr/bin/env ruby

require 'pp'

#mi_attempt_id
#
#mi_attempt_distribution_centres
#mi_attempt_status_stamps
#new_consortia_intermediate_report
#new_gene_intermediate_report
#phenotype_attempts
#solr_update_queue_items
#
#
#
#phenotype_attempt_id
#
#new_consortia_intermediate_report
#new_gene_intermediate_report
#phenotype_attempt_distribution_centres
#phenotype_attempt_status_stamps
#solr_update_queue_items
#

##template = "select mi_attempt_id from TABLE where not exists (select id from mi_attempts where TABLE.mi_attempt_id = mi_attempts.id)"
#hash = {}
#
#tables = %w{mi_attempt_distribution_centres mi_attempt_status_stamps new_consortia_intermediate_report new_gene_intermediate_report phenotype_attempts solr_update_queue_items}
#
#tables.each do |table|
#  hash[table] = []
#  rows = ActiveRecord::Base.connection.execute("select mi_attempt_id from #{table} where not exists (select id from mi_attempts where #{table}.mi_attempt_id = mi_attempts.id)")
#
#  rows.each do |row|
#    next if row['mi_attempt_id'].nil?
#    hash[table].push row['mi_attempt_id']
#  end
#end
#
#pp hash

def check_orphans tables, target
 puts "#### checking #{target}s"
  hash = {}
  tables.each do |table|
    hash[table] = []
    rows = ActiveRecord::Base.connection.execute("select #{target}_id from #{table} where not exists (select id from #{target}s where #{table}.#{target}_id = #{target}s.id)")
    rows.each do |row|
      next if row['mi_attempt_id'].nil?
      hash[table].push row['mi_attempt_id']
    end
  end

  pp hash
end

tables = %w{mi_attempt_distribution_centres mi_attempt_status_stamps new_consortia_intermediate_report new_gene_intermediate_report phenotype_attempts solr_update_queue_items}
check_orphans tables, 'mi_attempt'

tables = %w{new_consortia_intermediate_report new_gene_intermediate_report phenotype_attempt_distribution_centres phenotype_attempt_status_stamps solr_update_queue_items}
check_orphans tables, 'phenotype_attempt'

#### checking mi_attempts
{"mi_attempt_distribution_centres"=>[],
 "mi_attempt_status_stamps"=>["8836", "8836", "8836"],
 "new_consortia_intermediate_report"=>[],
 "new_gene_intermediate_report"=>[],
 "phenotype_attempts"=>[],
 "solr_update_queue_items"=>[]}
#### checking phenotype_attempts
{"new_consortia_intermediate_report"=>[],
 "new_gene_intermediate_report"=>[],
 "phenotype_attempt_distribution_centres"=>[],
 "phenotype_attempt_status_stamps"=>[],
 "solr_update_queue_items"=>[]}
