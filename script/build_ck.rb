#!/usr/bin/env ruby

require 'pp'

sql = <<END
  select distinct
    genes.marker_symbol, genes.marker_type, genes.mgi_accession_id,

    --targ_rep_targeting_vectors.allele_id does_a_targ_vec_exist,
    --targ_rep_es_cells.allele_id does_an_es_cell_exist,

    CASE WHEN (targ_rep_targeting_vectors.allele_id IS NOT NULL) THEN true else false END AS does_a_targ_vec_exist,
    CASE WHEN (targ_rep_es_cells.allele_id IS NOT NULL) THEN true else false END AS does_an_es_cell_exist,

    targ_rep_es_cells.mgi_allele_symbol_superscript,
    targ_rep_es_cells.allele_symbol_superscript_template,
    miapc.name miacentre_name,
    mi_attempt_statuses.name,
    mi_attempts.mouse_allele_type as mi_mouse_allele_type,
    phenotype_attempts.mouse_allele_type as phenotype_attempt_mouse_allele_type,
    phenotype_attempts.cre_excision_required,
    pacentres.name pacentre_name,
    phenotype_attempt_statuses.name
  from
    genes
    left outer join targ_rep_alleles on genes.id = targ_rep_alleles.gene_id
    left outer join targ_rep_targeting_vectors on targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id
    left outer join targ_rep_es_cells on targ_rep_alleles.id = targ_rep_es_cells.allele_id
    left outer join mi_attempts on mi_attempts.es_cell_id = targ_rep_es_cells.id
    left outer join mi_attempt_statuses on mi_attempt_statuses.id = mi_attempts.status_id
    left join mi_plans mi_attempt_plan on mi_attempts.mi_plan_id = mi_attempt_plan.id
    left join centres miapc on mi_attempt_plan.production_centre_id = miapc.id
    left outer join phenotype_attempts on phenotype_attempts.mi_attempt_id = mi_attempts.id
    left outer join mi_plans paplan on phenotype_attempts.mi_plan_id = paplan.id
    left outer join centres pacentres on pacentres.id = paplan.production_centre_id
    left outer join phenotype_attempt_statuses on phenotype_attempt_statuses.id = phenotype_attempts.status_id
  where marker_symbol = 'Cib2'
END

rows = ActiveRecord::Base.connection.execute(sql)

#count = 0
#columns = []

processed_rows = []
remainder_rows = []

#phenotype_hash = {}
#mi_hash = {}

@mark_hash = {}

def mark type, row
  @mark_hash[type] ||= {}
  @mark_hash[type][row['mgi_accession_id'].to_s + row['mgi_allele_symbol_superscript'].to_s] = true
end

def mark? type, row
  return false if ! @mark_hash.has_key?(type) || ! @mark_hash[type].has_key?(row['mgi_accession_id'].to_s + row['mgi_allele_symbol_superscript'].to_s)
  @mark_hash[type][row['mgi_accession_id'].to_s + row['mgi_allele_symbol_superscript'].to_s]
end

# pass 1/3

rows.each do |row|
 # columns = row.keys

  if row['cre_excision_required'] == 't'

    # B1
    row['allele_symbol'] = row['allele_symbol_superscript_template'].gsub(/\@/, 'a')
    processed_rows.push row.clone

    # B2
    row['allele_symbol'] = row['allele_symbol_superscript_template'].gsub(/\@/, 'b')
    processed_rows.push row.clone

   # phenotype_hash[row['mgi_accession_id'].to_s + row['mgi_allele_symbol_superscript'].to_s] = 1

    mark 'phenotype', row
  end

  if row['cre_excision_required'] == 'f'

    # B3
    row['allele_symbol'] = row['allele_symbol_superscript_template'].gsub(/\@/, 'a')
    processed_rows.push row.clone

    #phenotype_hash[row['mgi_accession_id'].to_s + row['mgi_allele_symbol_superscript'].to_s] = 1

    mark 'phenotype', row
  end

  #count += 1
end





# pass 2/3

rows.each do |row|
  #if ! row['mi_mouse_allele_type'].to_s.empty? && ! phenotype_hash.hash_key?(row['mgi_accession_id'].to_s + row['mgi_allele_symbol_superscript'].to_s)
  if ! row['mi_mouse_allele_type'].to_s.empty? && ! mark?('phenotype', row)

    # B4
    row['allele_symbol'] = row['allele_symbol_superscript_template'].gsub(/\@/, 'a')
    processed_rows.push row.clone

    #mi_hash[row['mgi_accession_id'].to_s + row['mgi_allele_symbol_superscript'].to_s] = 1

    mark 'mi', row
  end
end






# pass 3/3

rows.each do |row|

  # B5
#  if ! phenotype_hash.hash_key?(row['mgi_accession_id'].to_s + row['mgi_allele_symbol_superscript'].to_s) && ! mi_hash.hash_key?(row['mgi_accession_id'].to_s + row['mgi_allele_symbol_superscript'].to_s)

    if ! mark?('phenotype', row) && ! mark?('mi', row)

    row['allele_symbol'] = row['allele_symbol_superscript_template'].gsub(/\@/, 'a')
    processed_rows.push row.clone

    row['allele_symbol'] = row['allele_symbol_superscript_template'].gsub(/\@/, 'e')
    processed_rows.push row.clone

  end
end



#puts "#### count: #{count}"
pp processed_rows
