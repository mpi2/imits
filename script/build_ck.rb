#!/usr/bin/env ruby

require 'pp'
require "digest/md5"

SAVE_AS_CSV = false
USE_ID = false
USE_TYPE = false
USE_IDS = false

sql_template = <<END
  genes.id as genes_id,
  phenotype_attempts.id as phenotype_attempts_id,
  mi_attempts.id as mi_attempts_id,
  targ_rep_es_cells.id as targ_rep_es_cells_id,
END

sql = <<END
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
--  where marker_symbol = 'Ino80'
END

sql.gsub!(/SUBS_TEMPLATE/, sql_template) if USE_IDS
sql.gsub!(/SUBS_TEMPLATE/, '') if ! USE_IDS

#Cib2 Ell2 Zranb1 Pet2 Ino80

processed_rows = []
remainder_rows = []

@failures = []
@mark_hash = {}

STATUSES = {
  'ES_CELL_TARGETING_CONFIRMED' => 'ES Cell Targeting Confirmed',
  'CRE_EXCISION_COMPLETE' => 'Cre Excision Complete',
  'GENOTYPE_CONFIRMED' => 'Genotype confirmed',
  'ES_CELL_PRODUCTION_IN_PROGRESS' => 'ES Cell Production in Progress',
  'NO_ES_CELL_PRODUCTION' => 'No ES Cell Production'
}

def mark row
  pp row if row['allele_symbol'].to_s.empty?
  raise "#### Must have allele_symbol!" if row['allele_symbol'].to_s.empty?
  @mark_hash[row['mgi_accession_id'].to_s + row['allele_symbol'].to_s] = true
end

def mark? row
  @mark_hash.has_key?(row['mgi_accession_id'].to_s + row['allele_symbol'].to_s) &&
  @mark_hash[row['mgi_accession_id'].to_s + row['allele_symbol'].to_s] == true
end

def save_csv filename, data
  CSV.open(filename, "wb") do |csv|
    csv << data.first.keys
    data.each do |hash|
      csv << hash.values
    end
  end
end

# see http://ruby.about.com/od/advancedruby/a/deepcopy.htm

def deep_copy object
  Marshal.load( Marshal.dump(object) )
end

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

def get_phenotype_attempt_statuses
  hash = {}
  sql = 'select * from phenotype_attempt_statuses order by order_by;'
  rows = ActiveRecord::Base.connection.execute(sql)
  rows.each do |row|
    hash[row['name']] = row['order_by']
  end
  hash
end

#  5 | Cre Excision Started         | 2011-12-19 13:38:41.186843 | 2012-07-26 13:38:08.67926  |      350 | ces
#  6 | Cre Excision Complete        | 2011-12-19 13:38:41.19204  | 2012-07-26 13:38:08.681483 |      360 | cec

def get_mi_attempt_statuses
  hash = {}
  sql = 'select * from mi_attempt_statuses order by order_by;'
  rows = ActiveRecord::Base.connection.execute(sql)
  rows.each do |row|
    hash[row['name']] = row['order_by']
  end

  hash['Cre Excision Started'] = 350
  hash['Cre Excision Complete'] = 360

  hash
end

def prepare_allele_symbol row1, type
  row1['allele_symbol'] = 'None'
  row1['allele_symbol'] = row1['targ_rep_alleles_id'] if ! row1['targ_rep_alleles_id'].to_s.empty?
  row1['allele_symbol'] = row1['mgi_allele_symbol_superscript'] if ! row1['mgi_allele_symbol_superscript'].to_s.empty?
  row1['allele_symbol'] = row1['allele_symbol_superscript_template'].to_s.gsub(/\@/, row1[type].to_s) if ! row1[type].to_s.empty? && ! row1['allele_symbol_superscript_template'].to_s.empty?
  row1
end

PHENOTYPE_ATTEMPT_STATUSES = get_phenotype_attempt_statuses
MI_ATTEMPT_STATUSES = get_mi_attempt_statuses
ES_CELL_STATUSES = {
  STATUSES['ES_CELL_TARGETING_CONFIRMED'] => 30,
  STATUSES['ES_CELL_PRODUCTION_IN_PROGRESS'] => 20,
  STATUSES['NO_ES_CELL_PRODUCTION'] => 10
}

LEGIT_PHENOTYPE_ATTEMPT_STATUSES = ['Phenotype Attempt Aborted', 'Cre Excision Started', 'Rederivation Complete', 'Rederivation Started', 'Phenotype Attempt Registered', 'Cre Excision Complete']

SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")

puts "#### index: #{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}"

# pass 1/3

puts "#### select..."

rows = ActiveRecord::Base.connection.execute(sql)

puts "#### pass 1..."

rows.each do |row1|

  prepare_allele_symbol row1, 'phenotype_attempt_mouse_allele_type'

  #row1['allele_symbol'] = 'None'
  #row1['allele_symbol'] = row1['targ_rep_alleles_id'] if ! row1['targ_rep_alleles_id'].to_s.empty?
  #row1['allele_symbol'] = row1['mgi_allele_symbol_superscript'] if ! row1['mgi_allele_symbol_superscript'].to_s.empty?
  #row1['allele_symbol'] = row1['allele_symbol_superscript_template'].to_s.gsub(/\@/, row1['phenotype_attempt_mouse_allele_type'].to_s) if ! row1['phenotype_attempt_mouse_allele_type'].to_s.empty? && ! row1['allele_symbol_superscript_template'].to_s.empty?

  if row1['allele_symbol'].to_s.empty?
    row1['failed'] = 'pass 1'
    @failures.push row1
    next
  end

  next if row1['pacentre_name'].to_s.empty?
  next if row1['phenotype_attempt_status'] == 'Phenotype Attempt Aborted'

  if row1['cre_excision_required'] == 't'

    row = deep_copy row1

    # B1
    #row['allele_symbol'] = row['allele_symbol_superscript_template'].gsub(/\@/, row['phenotype_attempt_mouse_allele_type'].to_s) if ! row['phenotype_attempt_mouse_allele_type'].to_s.empty? && ! row['allele_symbol_superscript_template'].to_s.empty?

    row['allele_type'] = row['phenotype_attempt_mouse_allele_type'].to_s

    row['es_cell_status'] = STATUSES['ES_CELL_TARGETING_CONFIRMED']

    if LEGIT_PHENOTYPE_ATTEMPT_STATUSES.include?(row['phenotype_attempt_status'])
      row['mouse_status'] = row['phenotype_attempt_status']
      row['phenotype_status'] = ''
    else
      row['mouse_status'] = STATUSES['CRE_EXCISION_COMPLETE']
      row['phenotype_status'] = row['phenotype_attempt_status']
    end

    row['phenotyping_centre'] = row['pacentre_name']
    row['production_centre'] = row['pacentre_name']

    row['allele_type'] = row['phenotype_attempt_mouse_allele_type'].to_s

    row['type'] = 'B1'

    processed_rows.push row

    row = deep_copy row1

    mark row
  end

  if row1['cre_excision_required'] == 'f'

    row = deep_copy row1

    # B3
   # row['allele_symbol'] = row['allele_symbol_superscript_template'].gsub(/\@/, row['mi_mouse_allele_type'].to_s) if ! row['mi_mouse_allele_type'].to_s.empty? && ! row['allele_symbol_superscript_template'].to_s.empty?

    row['es_cell_status'] = STATUSES['ES_CELL_TARGETING_CONFIRMED']
    row['mouse_status'] = STATUSES['GENOTYPE_CONFIRMED']
    row['phenotype_status'] = row['phenotype_attempt_status']
    row['production_centre'] = row['miacentre_name']
    row['phenotyping_centre'] = row['pacentre_name']

    row['allele_type'] = row['phenotype_attempt_mouse_allele_type'].to_s

    row['type'] = 'B3'

    processed_rows.push row

    mark row
  end
end

puts "#### pass 2..."

# pass 2/3

rows.each do |row1|

  next if row1['mi_attempt_status'] == 'Micro-injection aborted'

  prepare_allele_symbol row1, 'mi_mouse_allele_type'

  #row1['allele_symbol'] = 'None'
  #row1['allele_symbol'] = row1['targ_rep_alleles_id'] if ! row1['targ_rep_alleles_id'].to_s.empty?
  #row1['allele_symbol'] = row1['mgi_allele_symbol_superscript'] if ! row1['mgi_allele_symbol_superscript'].to_s.empty?
  #row1['allele_symbol'] = row1['allele_symbol_superscript_template'].to_s.gsub(/\@/, row1['mi_mouse_allele_type'].to_s) if ! row1['mi_mouse_allele_type'].to_s.empty? && ! row1['allele_symbol_superscript_template'].to_s.empty?

  if row1['allele_symbol'].to_s.empty?
    row1['failed'] = 'pass 2'
    @failures.push row1
    next
  end

  if ! row1['mi_attempt_status'].to_s.empty? && ! mark?(row1)

    row = deep_copy row1

    # B4
    row['es_cell_status'] = STATUSES['ES_CELL_TARGETING_CONFIRMED']
    row['mouse_status'] = row['mi_attempt_status']
    row['phenotype_status'] = ''
    row['production_centre'] = row['miacentre_name']

    row['allele_type'] = row['mi_mouse_allele_type'].to_s

    row['type'] = 'B4'

    processed_rows.push row

    mark row
  end
end

puts "#### pass 3..."

# pass 3/3

rows.each do |row1|

  prepare_allele_symbol row1, 'mi_mouse_allele_type'

  #row1['allele_symbol'] = 'None'
  #row1['allele_symbol'] = row1['targ_rep_alleles_id'] if ! row1['targ_rep_alleles_id'].to_s.empty?
  #row1['allele_symbol'] = row1['mgi_allele_symbol_superscript'] if ! row1['mgi_allele_symbol_superscript'].to_s.empty?
  #row1['allele_symbol'] = row1['allele_symbol_superscript_template'].to_s.gsub(/\@/, row1['mi_mouse_allele_type'].to_s) if ! row1['mi_mouse_allele_type'].to_s.empty? && ! row1['allele_symbol_superscript_template'].to_s.empty?

  if row1['allele_symbol'].to_s.empty?
    row1['failed'] = 'pass 3'
    @failures.push row1
    next
  end

  # B5

  if ! mark?(row1)

    row = deep_copy row1

    if row1['does_an_es_cell_exist'] == 't'
      row['es_cell_status'] = STATUSES['ES_CELL_TARGETING_CONFIRMED']
    elsif row1['does_a_targ_vec_exist'] == 't'
      row['es_cell_status'] = STATUSES['ES_CELL_PRODUCTION_IN_PROGRESS']
    else
      row['es_cell_status'] = STATUSES['NO_ES_CELL_PRODUCTION']
    end

    row['mouse_status'] = ''
    row['phenotype_status'] = ''
    row['production_centre'] = ''

    row['allele_type'] = row1['mi_mouse_allele_type'].to_s

    row['type'] = 'B5'

    processed_rows.push row

  end
end

key_count = 0
target = nil

new_processed_rows = []
new_processed_rows_hash = {}
new_processed_list = []

puts "#### pass 4..."

genes_hash = {}

processed_rows.each do |row|
  target = row if key_count < row.keys.size
  key_count = row.keys.size if key_count < row.keys.size

  hash = {}
  hash['marker_symbol'] = row['marker_symbol']
  hash['marker_type'] = row['marker_type']
  hash['mgi_accession_id'] = row['mgi_accession_id']
  hash['es_cell_status'] = row['es_cell_status']
  hash['mouse_status'] = row['mouse_status']
  hash['phenotype_status'] = row['phenotype_status']
  hash['production_centre'] = row['production_centre']
  hash['phenotyping_centre'] = row['phenotyping_centre']
  hash['phenotype_status'] = row['phenotype_status']
  hash['allele_name'] = row['allele_symbol']
  hash['allele_type'] = row['allele_type']

  hash['type'] = row['type'] if USE_TYPE

  digest = Digest::MD5.hexdigest(row['mgi_accession_id'].to_s + '-' + row['allele_symbol'].to_s)

  hash['id'] = digest if USE_ID

  if USE_IDS
    notes = []
    notes.push "GENE: #{row['genes_id'].to_s}" if row['genes_id']
    notes.push "MI: #{row['mi_attempts_id'].to_s}" if row['mi_attempts_id']
    notes.push "PA: #{row['phenotype_attempts_id'].to_s}" if row['phenotype_attempts_id']
    notes.push "ALELE: #{row['targ_rep_alleles_id'].to_s}" if row['targ_rep_alleles_id']
    notes.push "ESCELL: #{row['targ_rep_es_cells_id'].to_s}" if row['targ_rep_es_cells_id']

    hash['notes'] = notes.join ' - '
  end

  #genes.id as genes_id,
  #phenotype_attempts.id as phenotype_attempts_id,
  #mi_attempts.id as mi_attempts_id,

  new_processed_rows.push hash if ! new_processed_rows_hash.has_key? digest.to_s   #hash.values.to_s

  if ! new_processed_rows_hash.has_key? digest.to_s
    genes_hash[hash['marker_symbol']] ||= []
    genes_hash[hash['marker_symbol']].push hash
  end

  new_processed_rows_hash[digest.to_s] = true
end

puts "#### pass 5..."

genes_hash.keys.each do |key|

  best_status = 0
  best_status_string = ''
  best_production_centre = ''
  best_phenotyping_centre = ''

  imits_phenotype_started = false
  imits_phenotype_complete = false
  imits_phenotype_status = ''

  genes_hash[key].each do |row|
    if ! row['phenotype_status'].to_s.empty?

      imits_phenotype_started = true if row['phenotype_status'] == 'Phenotyping Started' || row['phenotype_status'] == 'Phenotyping Complete'

      imits_phenotype_complete = true if row['phenotype_status'] == 'Phenotyping Complete'

      if best_status.to_i < PHENOTYPE_ATTEMPT_STATUSES[row['phenotype_status']].to_i
        best_status = PHENOTYPE_ATTEMPT_STATUSES[row['phenotype_status']].to_i
        best_status_string = row['phenotype_status']
        imits_phenotype_status = row['phenotype_status']
        best_phenotyping_centre = row['phenotyping_centre']
      end

    elsif ! row['mouse_status'].to_s.empty?

      if best_status.to_i < MI_ATTEMPT_STATUSES[row['mouse_status']].to_i &&
        (MI_ATTEMPT_STATUSES[row['mouse_status']].to_i == 350 || MI_ATTEMPT_STATUSES[row['mouse_status']].to_i == 360)
          imits_phenotype_status = row['mouse_status']
      end

      if best_status.to_i < MI_ATTEMPT_STATUSES[row['mouse_status']].to_i
        best_status = MI_ATTEMPT_STATUSES[row['mouse_status']].to_i
        best_status_string = row['mouse_status']
        best_production_centre = row['production_centre']
      end

    elsif ! row['es_cell_status'].to_s.empty? && (best_status == 0)

      if best_status.to_i < ES_CELL_STATUSES[row['es_cell_status']].to_i
        best_status = ES_CELL_STATUSES[row['es_cell_status']].to_i
        best_status_string = row['es_cell_status']
      end

    end
  end

  genes_hash[key].each do |row|
    row['latest_project_status'] = best_status_string
    row['latest_production_centre'] = best_production_centre
    row['latest_phenotyping_centre'] = best_phenotyping_centre
    row['latest_phenotype_started'] = imits_phenotype_started ? '1' : '0'
    row['latest_phenotype_complete'] = imits_phenotype_complete ? '1' : '0'
    row['latest_phenotype_status'] = imits_phenotype_status
    row['latest_gene_project_status_str'] = row['marker_symbol'].to_s + "-" + row['latest_project_status'].to_s
  end

end

puts "#### pass 6..."

new_processed_rows.each do |row|
  ohash = ActiveSupport::OrderedHash.new

  row.keys.sort.each do |key|
    ohash[key] = row[key]
  end

  item = {'add' => {'doc' => ohash }}
  new_processed_list.push item.to_json
end

if SAVE_AS_CSV
  puts "#### save csv..."

  home = Dir.home
  filename = "#{home}/Desktop/build_ck.csv"
  save_csv filename, new_processed_rows
end

puts "#### send to index - #{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}"

proxy = SolrBulk::Proxy.new(SOLR_UPDATE[Rails.env]['index_proxy']['ck'])
proxy.update({'delete' => {'query' => '*:*'}}.to_json)
proxy.update(new_processed_list.join)
proxy.update({'commit' => {}}.to_json)

if ! @failures.empty?
  puts "#### write failures..."
  home = Dir.home
  filename = "#{home}/Desktop/build_ck_failures.csv"
  save_csv filename, @failures
end

puts "done (#{new_processed_rows.size})!"

#gene level:
#
#  mouse production center (latest project status) - hold off for a minute
#  phenotyping center (latest project status) - hold off for a minute
#  marker_symbol - done
#  marker_name  - forget
#  marker_synonym - forget
#  marker_type - done
#  mgi_accession_id - done
#  latest_project_status' - hold off
#
#  // the following 3 are use to make the IMPC Phenotyping Status facet on search page
#  imits_phenotype_started (from gene core) - wait
#  imits_phenotype_complete (from gene core)  - wait
#  imits_phenotype_status (from gene core)  - wait
#
#allele level (each allele)
#  es cell status ==> does_an_es_cell_exist || does a targeting_vector_exist
#  mice status => mi attempt status
#  phenotyping status => pa status
#  allele name (tm1a/tm1b…) => either the mi_attempt allele name OR the PA allele name depending on whether you're writing the Mi attempt row or the PA row
#  allele_type: (mi/pa) => either Cell or MI (if it exists) or PA (if you're writing out the second row)
#
#  mouse production center = > in select; either the MI centre or PA centre depending on which mI or PA row you're spitting out
#  phenotyping center = > the PA centre IF you're spitting out the PA row
