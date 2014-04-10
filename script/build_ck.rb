#!/usr/bin/env ruby

require 'pp'
require "digest/md5"

config = YAML.load_file("#{Rails.root}/script/build_ck.yml")

#pp config

SAVE_AS_CSV = config['options']['SAVE_AS_CSV']
USE_ID = config['options']['USE_ID']
USE_IDS = config['options']['USE_IDS']
USE_ORDER = config['options']['USE_ORDER']
USE_REPORT_TO_PUBLIC = config['options']['USE_REPORT_TO_PUBLIC']
USE_ALLELES = config['options']['USE_ALLELES']
USE_GENES = config['options']['USE_GENES']
MARKER_SYMBOL = config['options']['MARKER_SYMBOL']
USE_SYNONYMS = config['options']['USE_SYNONYMS']

STATUSES = config['statuses']
LEGACY_STATUSES_MAP = config['legacy_statuses_map']
ES_CELL_STATUSES = config['es_cell_statuses']

#puts config.to_yaml
#exit

sql_template = config['sql_template']
sql = config['sql']

sql.gsub!(/SUBS_TEMPLATE3/, "where marker_symbol = '#{MARKER_SYMBOL}'") if ! MARKER_SYMBOL.empty?
sql.gsub!(/SUBS_TEMPLATE3/, '') if MARKER_SYMBOL.empty?

sql.gsub!(/SUBS_TEMPLATE2/, '-- ') if ! USE_REPORT_TO_PUBLIC
sql.gsub!(/SUBS_TEMPLATE2/, '') if USE_REPORT_TO_PUBLIC

sql.gsub!(/SUBS_TEMPLATE/, sql_template) if USE_IDS
sql.gsub!(/SUBS_TEMPLATE/, '') if ! USE_IDS

#Cib2 Ell2 Zranb1 Pet2 Ino80 Gsdma2
#'Gsdma2'    #'Pira11'    #'Gja8'    #   #'Akt2'

processed_rows = []
remainder_rows = []

@failures = []
@mark_hash = {}

#config = {'config' => {'LEGACY_STATUSES_MAP' => LEGACY_STATUSES_MAP, 'statuses' => STATUSES, 'sql' => sql, 'sql_template' => sql_template, 'options' => {
#      'SAVE_AS_CSV' => SAVE_AS_CSV,
#      'USE_ID' => USE_ID,
#      'USE_IDS' => USE_IDS,
#      'USE_ORDER' => USE_ORDER,
#      'USE_REPORT_TO_PUBLIC' => USE_REPORT_TO_PUBLIC,
#      'USE_ALLELES' => USE_ALLELES,
#      'USE_GENES' => USE_GENES,
#      'MARKER_SYMBOL' => MARKER_SYMBOL,
#      'USE_SYNONYMS' => USE_SYNONYMS
#      }}}
#
#puts config.to_yaml
#exit


#@db = nil
#
#def build_sqlite_db
#  @db = SQLite3::Database.new( "build_ck.db" )
#  #rows = db.execute( "select * from test" )
#end

#LEGACY_STATUSES = [
#  'Not Assigned for ES Cell Production',
#  'Assigned for ES Cell Production',
#  'ES Cells Produced',
#  'Assigned for Mouse Production and Phenotyping',
#  'Mice Produced'
#  ]

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
  #Marshal.load( Marshal.dump(object) )
  object
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
  row1['allele_symbol'] = 'DUMMY_' + row1['targ_rep_alleles_id'] if ! row1['targ_rep_alleles_id'].to_s.empty?
  row1['allele_symbol'] = row1['mgi_allele_symbol_superscript'] if ! row1['mgi_allele_symbol_superscript'].to_s.empty?
  row1['allele_symbol'] = row1['allele_symbol_superscript_template'].to_s.gsub(/\@/, row1[type].to_s) if ! row1[type].to_s.empty? && ! row1['allele_symbol_superscript_template'].to_s.empty?
  row1
end

def send_to_index data, delete = false
  proxy = SolrBulk::Proxy.new(SOLR_UPDATE[Rails.env]['index_proxy']['ck'])
  puts "#### delete!" if delete
  proxy.update({'delete' => {'query' => '*:*'}}.to_json) if delete
  proxy.update(data.join)
  proxy.update({'commit' => {}}.to_json)
end

def build_json data
  list = []
  data.each do |row|
    hash = nil
    if USE_ORDER
      hash = ActiveSupport::OrderedHash.new
      row.keys.sort.each { |key| ohash[key] = row[key] }
    else
      hash = row
    end

    item = {'add' => {'doc' => hash }}
    list.push item.to_json
  end
  list
end

@synonyms = {}

def load_synonyms
  # load from csv
  # build marker_symbol keyed hash

  CSV.foreach("gene_association.mgi.processed.csv", :headers => true, :header_converters => :symbol, :converters => :all) do |row|
    @synonyms[row.fields[0]] = Hash[row.headers[0..-1].zip(row.fields[0..-1])]
  end
end

PHENOTYPE_ATTEMPT_STATUSES = get_phenotype_attempt_statuses
MI_ATTEMPT_STATUSES = get_mi_attempt_statuses

EARLY_PHENOTYPE_ATTEMPT_STATUSES = ['Phenotype Attempt Aborted', 'Cre Excision Started', 'Rederivation Complete', 'Rederivation Started', 'Phenotype Attempt Registered', 'Cre Excision Complete']

SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")

puts "#### index: #{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}"

# pass 1/3

puts "#### select..."

rows = ActiveRecord::Base.connection.execute(sql)


#build_sqlite_db




puts "#### pass 1..."

rows.each do |row1|

  prepare_allele_symbol row1, 'phenotype_attempt_mouse_allele_type'

  if row1['allele_symbol'].to_s.empty?
    row1['failed'] = 'pass 1'
    @failures.push row1
    next
  end

  #next if row1['pacentre_name'].to_s.empty?
  next if row1['phenotype_attempt_status'].to_s.empty?
  next if row1['phenotype_attempt_status'] == 'Phenotype Attempt Aborted'

  if row1['cre_excision_required'] == 't'

    row = deep_copy row1

    # B1

    row['allele_type'] = row['phenotype_attempt_mouse_allele_type'].to_s

    row['es_cell_status'] = STATUSES['ES_CELL_TARGETING_CONFIRMED']

    if EARLY_PHENOTYPE_ATTEMPT_STATUSES.include?(row['phenotype_attempt_status'])
      row['mouse_status'] = row['phenotype_attempt_status']
      row['phenotype_status'] = ''
    else
      row['mouse_status'] = STATUSES['CRE_EXCISION_COMPLETE']
      row['phenotype_status'] = row['phenotype_attempt_status']
    end

    row['phenotyping_centre'] = row['pacentre_name']
    row['production_centre'] = row['pacentre_name']

    row['allele_type'] = row['phenotype_attempt_mouse_allele_type'].to_s

    #puts "#### add 1"

    processed_rows.push row

    row = deep_copy row1

    mark row
  end

  if row1['cre_excision_required'] == 'f'

    row = deep_copy row1

    # B3

    row['es_cell_status'] = STATUSES['ES_CELL_TARGETING_CONFIRMED']
    row['mouse_status'] = STATUSES['GENOTYPE_CONFIRMED']
    row['phenotype_status'] = row['phenotype_attempt_status']
    row['production_centre'] = row['miacentre_name']
    row['phenotyping_centre'] = row['pacentre_name']

    row['allele_type'] = row['phenotype_attempt_mouse_allele_type'].to_s

    #puts "#### add 2"

    processed_rows.push row

    mark row
  end
end

puts "#### pass 2..."

# pass 2/3

rows.each do |row1|

  next if row1['mi_attempt_status'] == 'Micro-injection aborted'

  prepare_allele_symbol row1, 'mi_mouse_allele_type'

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

    #puts "#### add 3"

    processed_rows.push row

    mark row
  end
end

puts "#### pass 3..."

# pass 3/3

rows.each do |row1|

  prepare_allele_symbol row1, 'mi_mouse_allele_type'

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

    #puts "#### add 4"

    processed_rows.push row

  end
end

key_count = 0
target = nil

new_processed_allele_rows = []
new_processed_gene_rows = []
new_processed_rows_hash = {}

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
  hash['phenotype_status'] = row['phenotype_status'].to_s
  hash['production_centre'] = row['production_centre'].to_s
  hash['phenotyping_centre'] = row['phenotyping_centre'].to_s
  hash['allele_name'] = ''
  hash['allele_name'] = row['allele_symbol'] if row['allele_symbol'].to_s !~ /DUMMY_/
  hash['allele_type'] = row['allele_type']

  hash['type'] = 'allele'

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

  new_processed_allele_rows.push hash if ! new_processed_rows_hash.has_key? digest.to_s   #hash.values.to_s

  if ! new_processed_rows_hash.has_key? digest.to_s
    genes_hash[hash['marker_symbol']] ||= []
    genes_hash[hash['marker_symbol']].push hash
  end

  new_processed_rows_hash[digest.to_s] = true
end

puts "#### pass 5..."

load_synonyms if USE_SYNONYMS

puts "#### pass 5.1..."

count = Gene.count
counter = 0

rows = ActiveRecord::Base.connection.execute('select marker_symbol, mgi_accession_id, marker_type from genes') if MARKER_SYMBOL.empty?
rows = ActiveRecord::Base.connection.execute("select marker_symbol, mgi_accession_id, marker_type from genes where marker_symbol = '#{MARKER_SYMBOL}'") if ! MARKER_SYMBOL.empty?

rows.each do |row1|
 # puts "#### #{counter}/#{count}" if counter % 1000 == 0
  counter += 1

  marker_symbol = row1['marker_symbol']

  if ! genes_hash.has_key?(marker_symbol)
    hash = {}
    hash['marker_symbol'] = row1['marker_symbol']
    hash['mgi_accession_id'] = row1['mgi_accession_id']
    hash['marker_type'] = row1['marker_type']
    hash['latest_project_status'] = ''
    hash['latest_project_status'] = ''
    hash['latest_production_centre'] = ''
    hash['latest_phenotyping_centre'] = ''
    hash['latest_phenotype_started'] = '0'
    hash['latest_phenotype_complete'] = '0'
    hash['latest_phenotype_status'] = ''
    hash['type'] = 'gene'
    hash['latest_es_cell_status'] = ''
    hash['latest_mouse_status'] = ''
    hash['synonym'] = @synonyms[hash['mgi_accession_id']][:db_object_synonym].to_s.split '|' if USE_SYNONYMS && @synonyms[hash['mgi_accession_id']] && @synonyms[hash['mgi_accession_id']].has_key?(:db_object_synonym)
    new_processed_gene_rows.push hash
    next
  end

  best_status = 0
  best_status_string = ''
  best_production_centre = ''
  best_phenotyping_centre = ''

  imits_phenotype_started = false
  imits_phenotype_complete = false
  imits_phenotype_status = ''
  latest_es_cell_status = ''
  latest_mouse_status = ''

  #puts "#### #{counter}/#{count}" if counter % 1000 == 0
  #counter += 1

  #count = Gene.count
  #counter = 0

  #  rows = ActiveRecord::Base.connection.execute('select marker_symbol, mgi_accession_id, marker_type from genes') if MARKER_SYMBOL.empty?
  #  rows = ActiveRecord::Base.connection.execute("select marker_symbol, mgi_accession_id, marker_type from genes where marker_symbol = '#{MARKER_SYMBOL}'") if ! MARKER_SYMBOL.empty?
  #
  #  rows.each do |row1|
  #
  #    puts "#### #{counter}/#{count}" if counter % 1000 == 0
  #    counter += 1
  #next
  #
  #    marker_symbol = row1['marker_symbol']
  #
  #    if ! genes_hash.has_key?(marker_symbol)
  #      hash = {}
  #      hash['marker_symbol'] = row1['marker_symbol']
  #      hash['mgi_accession_id'] = row1['mgi_accession_id']
  #      hash['marker_type'] = row1['marker_type']
  #      hash['latest_project_status'] = ''
  #      hash['latest_project_status'] = ''
  #      hash['latest_production_centre'] = ''
  #      hash['latest_phenotyping_centre'] = ''
  #      hash['latest_phenotype_started'] = '0'
  #      hash['latest_phenotype_complete'] = '0'
  #      hash['latest_phenotype_status'] = ''
  #      hash['type'] = 'gene'
  #      hash['latest_es_cell_status'] = ''
  #      hash['latest_mouse_status'] = ''
  #      hash['synonym'] = @synonyms[hash['mgi_accession_id']][:db_object_synonym].to_s.split '|' if USE_SYNONYMS && @synonyms[hash['mgi_accession_id']] && @synonyms[hash['mgi_accession_id']].has_key?(:db_object_synonym)
  #      new_processed_gene_rows.push hash #if MARKER_SYMBOL.empty?
  #      next
  #    end

  genes_hash[marker_symbol].each do |row|
    if ! row['phenotype_status'].to_s.empty?

      imits_phenotype_started = true if row['phenotype_status'] == 'Phenotyping Started' || row['phenotype_status'] == 'Phenotyping Complete'

      imits_phenotype_complete = true if row['phenotype_status'] == 'Phenotyping Complete'

      if best_status.to_i < PHENOTYPE_ATTEMPT_STATUSES[row['phenotype_status']].to_i
        best_status = PHENOTYPE_ATTEMPT_STATUSES[row['phenotype_status']].to_i
        best_status_string = row['phenotype_status']
        imits_phenotype_status = row['phenotype_status']
        best_phenotyping_centre = row['phenotyping_centre']
        best_production_centre = row['production_centre']
      end

    elsif ! row['mouse_status'].to_s.empty?

      if best_status.to_i < MI_ATTEMPT_STATUSES[row['mouse_status']].to_i &&
        (MI_ATTEMPT_STATUSES[row['mouse_status']].to_i == 350 || MI_ATTEMPT_STATUSES[row['mouse_status']].to_i == 360)
        imits_phenotype_status = row['mouse_status']
        latest_mouse_status = row['mouse_status']
        best_production_centre = row['production_centre']
      end

      if best_status.to_i < MI_ATTEMPT_STATUSES[row['mouse_status']].to_i
        best_status = MI_ATTEMPT_STATUSES[row['mouse_status']].to_i
        best_status_string = row['mouse_status']
        best_production_centre = row['production_centre']
        latest_mouse_status = row['mouse_status']
      end

    elsif ! row['es_cell_status'].to_s.empty? && (best_status == 0)

      if best_status.to_i < ES_CELL_STATUSES[row['es_cell_status']].to_i
        best_status = ES_CELL_STATUSES[row['es_cell_status']].to_i
        best_status_string = row['es_cell_status']
        latest_es_cell_status = row['es_cell_status']
        best_production_centre = row['production_centre']
      end

    end
    #   end

    #{
    #  "marker_symbol":"Pet2",
    #  "marker_type":"Gene",
    #  "mgi_accession_id":"MGI:101758",
    #  "es_cell_status":"ES Cell Production in Progress",
    #  "mouse_status":"",
    #  "phenotype_status":"",
    #  "production_centre":"",
    #  "allele_name":"139",
    #  "allele_type":"",
    #  "type":"gene",
    #  "latest_project_status":"ES Cell Production in Progress",
    #  "latest_production_centre":"",
    #  "latest_phenotyping_centre":"",
    #  "latest_phenotype_started":"0",
    #  "latest_phenotype_complete":"0",
    #  "latest_phenotype_status":"",
    #  "latest_project_status_str":["ES Cell Production in Progress"],
    #  "latest_production_centre_str":[""],
    #  "latest_phenotyping_centre_str":[""]
    #}

    # genes_hash[key].each do |row1|

    exclude_keys = %W{es_cell_status mouse_status phenotype_status production_centre allele_name allele_type phenotyping_centre}

    row = deep_copy genes_hash[marker_symbol].first

    exclude_keys.each {|ekey| row.delete(ekey) }

    row['latest_project_status'] = best_status_string
    row['latest_production_centre'] = best_production_centre
    row['latest_phenotyping_centre'] = best_phenotyping_centre
    row['latest_phenotype_started'] = imits_phenotype_started ? '1' : '0'
    row['latest_phenotype_complete'] = imits_phenotype_complete ? '1' : '0'
    row['latest_phenotype_status'] = imits_phenotype_status
    row['latest_es_cell_status'] = latest_es_cell_status
    row['latest_mouse_status'] = latest_mouse_status
    row['synonym'] = @synonyms[row['mgi_accession_id']][:db_object_synonym].to_s.split '|' if USE_SYNONYMS

    row['type'] = 'gene'

    LEGACY_STATUSES_MAP.keys.each do |status|
      if LEGACY_STATUSES_MAP[status].include?(row['latest_project_status'])
        row['latest_project_status_legacy'] = status
        break
      end
    end

    #pp row
    #exit
    #
    #if ! MARKER_SYMBOL.empty?
    #  if MARKER_SYMBOL == row['marker_symbol']
    #    new_processed_gene_rows.push row
    #    break
    #  end
    #  #next
    #else
    #  new_processed_gene_rows.push row
    #end

    new_processed_gene_rows.push row
  end

end



puts "#### pass 5.2..."

#count = Gene.count
#counter = 0
#
#rows = ActiveRecord::Base.connection.execute('select marker_symbol, mgi_accession_id, marker_type from genes') if MARKER_SYMBOL.empty?
#rows = ActiveRecord::Base.connection.execute("select marker_symbol, mgi_accession_id, marker_type from genes where marker_symbol = '#{MARKER_SYMBOL}'") if ! MARKER_SYMBOL.empty?
#
#rows.each do |row1|
#  puts "#### #{counter}/#{count}" if counter % 1000 == 0
#  counter += 1
#
#  marker_symbol = row1['marker_symbol']
#
#  next if genes_hash.has_key?(marker_symbol)
#
#  hash = {}
#  hash['marker_symbol'] = row1['marker_symbol']
#  hash['mgi_accession_id'] = row1['mgi_accession_id']
#  hash['marker_type'] = row1['marker_type']
#  hash['latest_project_status'] = ''
#  hash['latest_project_status'] = ''
#  hash['latest_production_centre'] = ''
#  hash['latest_phenotyping_centre'] = ''
#  hash['latest_phenotype_started'] = '0'
#  hash['latest_phenotype_complete'] = '0'
#  hash['latest_phenotype_status'] = ''
#  hash['type'] = 'gene'
#  hash['latest_es_cell_status'] = ''
#  hash['latest_mouse_status'] = ''
#  hash['synonym'] = @synonyms[hash['mgi_accession_id']][:db_object_synonym].to_s.split '|' if USE_SYNONYMS && @synonyms[hash['mgi_accession_id']] && @synonyms[hash['mgi_accession_id']].has_key?(:db_object_synonym)
#  new_processed_gene_rows.push hash
#end




if USE_SYNONYMS && MARKER_SYMBOL.empty?
  @synonyms.keys.each do |key|
    next if @synonyms[key][:used]
    hash = {}
    hash['marker_symbol'] = @synonyms[key][:db_object_symbol]
    hash['mgi_accession_id'] = @synonyms[key][:db_object_id]
    hash['marker_type'] = 'Unknown'
    hash['latest_project_status'] = ''
    hash['latest_project_status'] = ''
    hash['latest_production_centre'] = ''
    hash['latest_phenotyping_centre'] = ''
    hash['latest_phenotype_started'] = '0'
    hash['latest_phenotype_complete'] = '0'
    hash['latest_phenotype_status'] = ''
    hash['type'] = 'gene'
    hash['latest_es_cell_status'] = ''
    hash['latest_mouse_status'] = ''
    hash['synonym'] = @synonyms[key][:db_object_synonym].to_s.split '|' if USE_SYNONYMS
    new_processed_gene_rows.push row
  end
end

puts "#### pass 6..."

new_processed_list = build_json new_processed_allele_rows
new_processed_list2 = build_json new_processed_gene_rows

#new_processed_allele_rows.each do |row|
#
#  if USE_ORDER
#    ohash = ActiveSupport::OrderedHash.new
#    row.keys.sort.each { |key| ohash[key] = row[key] }
#  end
#
#  item = {'add' => {'doc' => ohash }}
#  new_processed_list.push item.to_json
#end
#
#new_processed_list2 = []
#
#new_processed_gene_rows.each do |row|
#
#  if USE_ORDER
#    ohash = ActiveSupport::OrderedHash.new
#    row.keys.sort.each { |key| ohash[key] = row[key] }
#  end
#
#  item = {'add' => {'doc' => ohash }}
#  new_processed_list2.push item.to_json
#end

if SAVE_AS_CSV
  puts "#### save csv..."

  home = Dir.home
  filename = "#{home}/Desktop/build_ck.csv"
  save_csv filename, new_processed_allele_rows
end

puts "#### send to index - #{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}"

#proxy = SolrBulk::Proxy.new(SOLR_UPDATE[Rails.env]['index_proxy']['ck'])
#proxy.update({'delete' => {'query' => '*:*'}}.to_json)
#proxy.update(new_processed_list.join)
#proxy.update({'commit' => {}}.to_json)

send_to_index new_processed_list, true if USE_ALLELES
new_processed_list = []

send_to_index new_processed_list2 if USE_GENES
new_processed_list2 = []

if ! @failures.empty?
  puts "#### write failures..."
  home = Dir.home
  filename = "#{home}/Desktop/build_ck_failures.csv"
  save_csv filename, @failures
end

puts "done (#{new_processed_allele_rows.size})!"

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

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
end
