#!/usr/bin/env ruby

require 'pp'
require "digest/md5"
require 'sqlite3'

sql_template = <<END
genes.id as genes_id,
phenotype_attempts.id as phenotype_attempts_id,
mi_attempts.id as mi_attempts_id,
targ_rep_es_cells.id as targ_rep_es_cells_id,
END

sql = <<END
create temp table solr_ck_tmp as
select distinct
SUBS_TEMPLATE

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
phenotype_attempt_statuses.name as phenotype_attempt_status
from genes
left outer join targ_rep_alleles on genes.id = targ_rep_alleles.gene_id
left outer join targ_rep_targeting_vectors on targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id    SUBS_TEMPLATE2 and targ_rep_targeting_vectors.report_to_public is true
left outer join targ_rep_es_cells on targ_rep_alleles.id = targ_rep_es_cells.allele_id                      SUBS_TEMPLATE2 and targ_rep_es_cells.report_to_public is true
left outer join mi_attempts on mi_attempts.es_cell_id = targ_rep_es_cells.id                                SUBS_TEMPLATE2 and mi_attempts.report_to_public is true
left outer join mi_attempt_statuses on mi_attempt_statuses.id = mi_attempts.status_id
left join mi_plans mi_attempt_plan on mi_attempts.mi_plan_id = mi_attempt_plan.id                           SUBS_TEMPLATE2 and mi_attempt_plan.report_to_public is true
left join centres miapc on mi_attempt_plan.production_centre_id = miapc.id
left outer join phenotype_attempts on phenotype_attempts.mi_attempt_id = mi_attempts.id                     SUBS_TEMPLATE2 and phenotype_attempts.report_to_public is true
left outer join mi_plans paplan on phenotype_attempts.mi_plan_id = paplan.id                                SUBS_TEMPLATE2 and paplan.report_to_public is true
left outer join centres pacentres on pacentres.id = paplan.production_centre_id
left outer join phenotype_attempt_statuses on phenotype_attempt_statuses.id = phenotype_attempts.status_id
SUBS_TEMPLATE3 ;

select * from solr_ck_tmp
END

sql.gsub!(/SUBS_TEMPLATE3/, "where marker_symbol = '#{MARKER_SYMBOL}'") if ! MARKER_SYMBOL.empty?
sql.gsub!(/SUBS_TEMPLATE3/, '') if MARKER_SYMBOL.empty?

sql.gsub!(/SUBS_TEMPLATE2/, '-- ') if ! USE_REPORT_TO_PUBLIC
sql.gsub!(/SUBS_TEMPLATE2/, '') if USE_REPORT_TO_PUBLIC

sql.gsub!(/SUBS_TEMPLATE/, sql_template) if USE_IDS
sql.gsub!(/SUBS_TEMPLATE/, '') if ! USE_IDS

@db = SQLite3::Database.new( "build_ck.db" )

rows = ActiveRecord::Base.connection.execute(sql)

rows.each do |row1|
  pp row1
  exit
end