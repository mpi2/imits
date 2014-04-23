#!/usr/bin/env ruby

require 'pp'
require "digest/md5"

class BuildAllele2

  def initialize
    config = YAML.load_file("#{Rails.root}/script/build_ck.yml")

    @save_as_csv = config['options']['@save_as_csv']
    @use_id = config['options']['@use_id']
    @use_ids = config['options']['@use_ids']
    @user_order = config['options']['@user_order']
    @use_report_to_public = config['options']['@use_report_to_public']
    @use_alleles = config['options']['@use_alleles']
    @use_genes = config['options']['@use_genes']
    @marker_symbol = config['options']['@marker_symbol']
    @detect_gene_dups = config['options']['@detect_gene_dups']
    @use_replacement = config['options']['@use_replacement']

    @statuses = config['statuses']
    @legacy_statuses_map = config['legacy_statuses_map']
    @es_cell_statuses = config['es_cell_statuses']

    pp config['options']

    puts "#### loading alleles!" if @use_alleles
    puts "#### loading genes!" if @use_genes

    sql_template = config['sql_template']
    @sql = config['@sql']

    @sql.gsub!(/SUBS_TEMPLATE3/, "where marker_symbol = '#{@marker_symbol}'") if ! @marker_symbol.empty?
    @sql.gsub!(/SUBS_TEMPLATE3/, '') if @marker_symbol.empty?

    @sql.gsub!(/SUBS_TEMPLATE2/, '-- ') if ! @use_report_to_public
    @sql.gsub!(/SUBS_TEMPLATE2/, '') if @use_report_to_public

    @sql.gsub!(/SUBS_TEMPLATE/, sql_template) if @use_ids
    @sql.gsub!(/SUBS_TEMPLATE/, '') if ! @use_ids

    @processed_rows = []
    @remainder_rows = []

    @failures = []
    @mark_hash = {}
  end

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

  def get_phenotype_attempt_statuses
    hash = {}
    @sql = 'select * from phenotype_attempt_statuses order by order_by;'
    rows = ActiveRecord::Base.connection.execute(@sql)
    rows.each do |row|
      hash[row['name']] = row['order_by']
    end
    hash
  end

  def get_mi_attempt_statuses
    hash = {}
    @sql = 'select * from mi_attempt_statuses order by order_by;'
    rows = ActiveRecord::Base.connection.execute(@sql)
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

  def delete_index
    proxy = SolrBulk::Proxy.new(SOLR_UPDATE[Rails.env]['index_proxy']['ck'])
    proxy.update({'delete' => {'query' => '*:*'}}.to_json)
    proxy.update({'commit' => {}}.to_json)
  end

  def send_to_index data
    proxy = SolrBulk::Proxy.new(SOLR_UPDATE[Rails.env]['index_proxy']['ck'])
    proxy.update(data.join)
    proxy.update({'commit' => {}}.to_json)
  end

  def build_json data
    list = []
    data.each do |row|
      hash = nil
      if @user_order
        hash = ActiveSupport::OrderedHash.new
        row.keys.sort.each { |key| hash[key] = row[key] }
      else
        hash = row
      end

      item = {'add' => {'doc' => hash }}
      list.push item.to_json
    end
    list
  end

  # pass 1/3

  def run

    puts "#### index: #{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}"
    puts "#### select..."

    rows = ActiveRecord::Base.connection.execute(@sql)

    puts "#### step 1..."

    rows.each do |row1|

      prepare_allele_symbol row1, 'phenotype_attempt_mouse_allele_type'

      if row1['allele_symbol'].to_s.empty?
        row1['failed'] = 'pass 1'
        @failures.push row1
        next
      end

      next if row1['phenotype_attempt_status'].to_s.empty?
      next if row1['phenotype_attempt_status'] == 'Phenotype Attempt Aborted'

      if row1['cre_excision_required'] == 't'

        row = deep_copy row1

        # B1

        row['allele_type'] = row['phenotype_attempt_mouse_allele_type'].to_s

        row['es_cell_status'] = @statuses['ES_CELL_TARGETING_CONFIRMED']

        if EARLY_PHENOTYPE_ATTEMPT_STATUSES.include?(row['phenotype_attempt_status'])
          row['mouse_status'] = row['phenotype_attempt_status']
          row['phenotype_status'] = ''
        else
          row['mouse_status'] = @statuses['CRE_EXCISION_COMPLETE']
          row['phenotype_status'] = row['phenotype_attempt_status']
        end

        row['phenotyping_centre'] = row['pacentre_name']
        row['production_centre'] = row['pacentre_name']

        row['allele_type'] = row['phenotype_attempt_mouse_allele_type'].to_s

        @processed_rows.push row

        row = deep_copy row1

        mark row
      end

      if row1['cre_excision_required'] == 'f'

        row = deep_copy row1

        # B3

        row['es_cell_status'] = @statuses['ES_CELL_TARGETING_CONFIRMED']
        row['mouse_status'] = @statuses['GENOTYPE_CONFIRMED']
        row['phenotype_status'] = row['phenotype_attempt_status']
        row['production_centre'] = row['miacentre_name']
        row['phenotyping_centre'] = row['pacentre_name']

        row['allele_type'] = row['phenotype_attempt_mouse_allele_type'].to_s

        @processed_rows.push row

        mark row
      end
    end

    puts "#### step 2..."

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
        row['es_cell_status'] = @statuses['ES_CELL_TARGETING_CONFIRMED']
        row['mouse_status'] = row['mi_attempt_status']
        row['phenotype_status'] = ''
        row['production_centre'] = row['miacentre_name']

        row['allele_type'] = row['mi_mouse_allele_type'].to_s

        @processed_rows.push row

        mark row
      end
    end

    puts "#### step 3..."

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
          row['es_cell_status'] = @statuses['ES_CELL_TARGETING_CONFIRMED']
        elsif row1['does_a_targ_vec_exist'] == 't'
          row['es_cell_status'] = @statuses['ES_CELL_PRODUCTION_IN_PROGRESS']
        else
          row['es_cell_status'] = @statuses['NO_ES_CELL_PRODUCTION']
        end

        row['mouse_status'] = ''
        row['phenotype_status'] = ''
        row['production_centre'] = ''

        row['allele_type'] = row1['mi_mouse_allele_type'].to_s

        @processed_rows.push row

      end
    end

    key_count = 0
    target = nil

    new_processed_allele_rows = []
    new_processed_gene_rows = []
    new_processed_rows_hash = {}

    puts "#### step 4..."

    genes_hash = {}

    @processed_rows.each do |row|
      target = row if key_count < row.keys.size
      key_count = row.keys.size if key_count < row.keys.size

      hash = {}
      hash['marker_symbol'] = row['marker_symbol']

      hash['marker_type'] = row['marker_type']
      hash['feature_type'] = row['feature_type']

      hash['mgi_accession_id'] = row['mgi_accession_id']
      hash['es_cell_status'] = row['es_cell_status'].to_s
      hash['mouse_status'] = row['mouse_status']
      hash['phenotype_status'] = row['phenotype_status'].to_s
      hash['production_centre'] = row['production_centre'].to_s
      hash['phenotyping_centre'] = row['phenotyping_centre'].to_s
      hash['allele_name'] = ''
      hash['allele_name'] = row['allele_symbol'] if row['allele_symbol'].to_s !~ /DUMMY_/
      hash['allele_type'] = row['allele_type']

      hash['type'] = 'allele'

      digest = Digest::MD5.hexdigest(row['mgi_accession_id'].to_s + '-' + row['allele_symbol'].to_s)

      hash['id'] = digest if @use_id

      if @use_ids
        notes = []
        notes.push "GENE: #{row['genes_id'].to_s}" if row['genes_id']
        notes.push "MI: #{row['mi_attempts_id'].to_s}" if row['mi_attempts_id']
        notes.push "PA: #{row['phenotype_attempts_id'].to_s}" if row['phenotype_attempts_id']
        notes.push "ALELE: #{row['targ_rep_alleles_id'].to_s}" if row['targ_rep_alleles_id']
        notes.push "ESCELL: #{row['targ_rep_es_cells_id'].to_s}" if row['targ_rep_es_cells_id']

        hash['notes'] = notes.join ' - '
      end

      new_processed_allele_rows.push hash if ! new_processed_rows_hash.has_key? digest.to_s   #hash.values.to_s

      if ! new_processed_rows_hash.has_key? digest.to_s
        genes_hash[hash['marker_symbol']] ||= []
        genes_hash[hash['marker_symbol']].push hash

        if @use_replacement
          config['replacements'].each do |allele|

            if allele.has_key?(hash['marker_symbol'])

              next if allele[hash['marker_symbol']]['allele']['done']

              hash2 = deep_copy hash

              allele[hash['marker_symbol']]['allele'].keys.each do |kk|
                hash2[kk] = allele[hash['marker_symbol']]['allele'][kk]
              end

              hash2['notes'] = 'dummy allele'

              new_processed_allele_rows.push hash2

              allele[hash['marker_symbol']]['allele']['done'] = true

              break
            end
          end
        end
      end

      new_processed_rows_hash[digest.to_s] = true
    end

    puts "#### step 5..."

    count = Gene.count
    counter = 0

    rows = ActiveRecord::Base.connection.execute('select marker_symbol, mgi_accession_id, marker_type, feature_type, synonyms from genes') if @marker_symbol.empty?
    rows = ActiveRecord::Base.connection.execute("select marker_symbol, mgi_accession_id, marker_type, feature_type, synonyms from genes where marker_symbol = '#{@marker_symbol}'") if ! @marker_symbol.empty?

    rows.each do |row1|
      counter += 1

      marker_symbol = row1['marker_symbol']

      if ! genes_hash.has_key?(marker_symbol)
        hash = {}
        hash['synonym'] = ''
        hash['feature_type'] = ''

        hash['marker_symbol'] = row1['marker_symbol']
        hash['mgi_accession_id'] = row1['mgi_accession_id']

        hash['marker_type'] = row1['marker_type']
        hash['feature_type'] = row1['feature_type']

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
        hash['synonym'] = row1['synonyms']
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

          if best_status.to_i < @es_cell_statuses[row['es_cell_status']].to_i
            best_status = @es_cell_statuses[row['es_cell_status']].to_i
            best_status_string = row['es_cell_status']
            latest_es_cell_status = row['es_cell_status']
            best_production_centre = row['production_centre']
          end

        end
      end

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
      row['synonym'] = row1['synonyms'].to_s.split '|'
      row['feature_type'] = row1['feature_type']

      row['type'] = 'gene'

      @legacy_statuses_map.keys.each do |status|
        if @legacy_statuses_map[status].include?(row['latest_project_status'])
          row['latest_project_status_legacy'] = status
          break
        end
      end

      if @use_replacement
        config['replacements'].each do |allele|
          if allele.has_key?(row['marker_symbol'])

            next if allele[row['marker_symbol']]['gene']['done']

            row = deep_copy row

            allele[row['marker_symbol']]['gene'].keys.each do |kk|
              row[kk] = allele[row['marker_symbol']]['gene'][kk]
            end

            row['notes'] = 'dummy gene'

            allele[row['marker_symbol']]['gene']['done'] = true

            break
          end
        end
      end

      new_processed_gene_rows.push row
    end

    if @detect_gene_dups
      puts "#### check gene duplicates!"

      summary_gene_dups = {}
      gene_dups = {}
      new_processed_gene_rows.each do |gene|
        gene_dups[gene['marker_symbol']] ||= 0
        gene_dups[gene['marker_symbol']] += 1

        if gene_dups[gene['marker_symbol']] > 1
          summary_gene_dups[gene['marker_symbol']] = gene_dups[gene['marker_symbol']]
        end
      end

      if ! summary_gene_dups.empty?
        puts "#### gene duplicates detected!"
        pp summary_gene_dups
      else
        puts "#### no gene duplicates detected!"
      end
    end

    puts "#### step 6..."

    new_processed_list = build_json new_processed_allele_rows
    new_processed_list2 = build_json new_processed_gene_rows

    if @save_as_csv
      puts "#### save csv..."

      home = Dir.home
      filename = "#{home}/Desktop/build_ck.csv"
      save_csv filename, new_processed_allele_rows
    end

    puts "#### send to index - #{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}"

    delete_index

    send_to_index new_processed_list if @use_alleles
    new_processed_list = []

    send_to_index new_processed_list2 if @use_genes
    new_processed_list2 = []

    if ! @failures.empty?
      puts "#### write failures..."
      home = Dir.home
      filename = "#{home}/Desktop/build_ck_failures.csv"
      save_csv filename, @failures
    end

    puts "done (#{new_processed_allele_rows.size}/#{new_processed_gene_rows.size}/#{new_processed_allele_rows.size + new_processed_gene_rows.size})!"
  end
end

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  BuildAllele2.new.run
end
