#!/usr/bin/env ruby

require 'pp'
require "digest/md5"

module SolrConnect
  class Error < RuntimeError; end

  class NetHttpProxy
    def self.should_use_proxy_for?(host)
      ENV['NO_PROXY'].to_s.delete(' ').split(',').each do |no_proxy_host_part|
        if host.include?(no_proxy_host_part)
          return false
        end
      end

      return true
    end

    def initialize(solr_uri)
      if ENV['HTTP_PROXY'].present? and self.class.should_use_proxy_for?(solr_uri.host)
        proxy_uri = URI.parse(ENV['HTTP_PROXY'])
        @http = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
      else
        @http = Net::HTTP
      end
    end

    def start(*args, &block)
      @http.start(*args, &block)
    end
  end

  class Proxy
    def initialize(uri)
      @solr_uri = URI.parse(uri)
      @http = NetHttpProxy.new(@solr_uri)
    end

    def update(commands_packet, user = nil, password = nil)
      uri = @solr_uri.dup
      uri.path = uri.path + '/update/json'
      @http.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Post.new uri.request_uri

        #TODO: enable the following when the /update route is secure
        #request.basic_auth(user, password) if user && password

        request.content_type = 'application/json'
        request.body = commands_packet
        http_response = http.request(request)
        handle_http_response_error(http_response, request)
      end
    end

    def handle_http_response_error(http_response, request = nil)
      if ! http_response.kind_of? Net::HTTPSuccess
        raise SolrConnect::Error, "Error during update_json: #{http_response.message}\n#{http_response.body}\n\nRequest body:#{request.body}"
      end
    end

    protected :handle_http_response_error
  end
end

class BuildAllele2

  def initialize
    @config = YAML.load_file("#{Rails.root}/script/build_allele2_v2.yml")

    @solr_update = YAML.load_file("#{Rails.root}/config/solr_update.yml")

    @save_as_csv = @config['options']['SAVE_AS_CSV']
    @use_id = @config['options']['USE_ID']
    @use_ids = @config['options']['USE_IDS']
    @user_order = @config['options']['USE_ORDER']
    @use_report_to_public = @config['options']['USE_REPORT_TO_PUBLIC']
    @use_alleles = @config['options']['USE_ALLELES']
    @use_genes = @config['options']['USE_GENES']
    @marker_symbol = @config['options']['MARKER_SYMBOL'].to_s.split '|'
    @detect_gene_dups = @config['options']['DETECT_GENE_DUPS']
    @use_replacement = @config['options']['USE_REPLACEMENT']
    #@default_fields = @config['options']['DEFAULT_FIELDS']
    @filter_target = @config['options']['FILTER_TARGET'].to_s

    @statuses = @config['statuses']
    @legacy_statuses_map = @config['legacy_statuses_map']
    @es_cell_statuses = @config['es_cell_statuses']

    @pa_statuses = get_phenotype_attempt_statuses
    @mi_statuses = get_mi_attempt_statuses
    @early_pa_statuses = ['Phenotype Attempt Aborted', 'Cre Excision Started', 'Rederivation Complete', 'Rederivation Started', 'Phenotype Attempt Registered', 'Cre Excision Complete']

    @marker_filters = @config['marker_filters']

    @create_files = @config['options']['CREATE_FILES']
    @use_files = @config['options']['USE_FILES']

    @solr_user = @config['options']['SOLR_USER']
    @solr_password = @config['options']['SOLR_PASSWORD']

    pp @config['options']

    puts "#### loading alleles!" if @use_alleles
    puts "#### loading genes!" if @use_genes

    sql_template = @config['sql_template']
    @sql = @config['sql']
    marker_symbols = @marker_symbol.to_a.map {|ms| "'#{ms}'" }.join ','

    @sql.gsub!(/SUBS_TEMPLATE3/, "where marker_symbol in (#{marker_symbols})") if ! @marker_symbol.empty?
    @sql.gsub!(/SUBS_TEMPLATE3/, '') if @marker_symbol.empty?

    @sql.gsub!(/SUBS_TEMPLATE2/, '-- ') if ! @use_report_to_public
    @sql.gsub!(/SUBS_TEMPLATE2/, '') if @use_report_to_public

    @sql.gsub!(/SUBS_TEMPLATE/, sql_template) if @use_ids
    @sql.gsub!(/SUBS_TEMPLATE/, '') if ! @use_ids

    @processed_rows = []
    @remainder_rows = []

    @failures = []
    @mark_hash = {}

    home = Dir.home
    #@root = "#{home}/Desktop"
    @root = "#{Rails.root}/script"

    @solr_url = @solr_update[Rails.env]['index_proxy']['allele2']

    @guess_mapping = {'a'                        => 'b',
                      'e'                        => 'e.1',
                      ''                         => '.1',
                      'Conditional Ready'        => 'a',
                      'Targeted Non Conditional' => 'e',
                      'Deletion'                 => '',
                      'Cre Knock In'             => '',
                      'Gene Trap'                => 'Gene Trap'
                     }

    @genbank_file_transformations = {'a'   => '',
                                     'e'   => '',
                                     ''    => '',
                                     'b'   => 'cre',
                                     'e.1' => 'cre',
                                     '.1'  => 'cre',
                                     'c'   => 'flp',
                                     'd'   => 'flp_cre'
                                     }

    puts "#### #{@solr_url}/admin/"
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
    row1['allele_symbol'] = 'tm1' + row1['allele_type'] if ! row1['allele_type'].blank? && row1['allele_type'] != 'None'
    row1['allele_symbol'] = row1['mgi_allele_symbol_superscript'] if ! row1['mgi_allele_symbol_superscript'].to_s.empty?
    row1['allele_symbol'] = row1['allele_symbol_superscript_template'].to_s.gsub(/\@/, row1['allele_type'].to_s) if ! row1['allele_type'].nil? && ! row1['allele_symbol_superscript_template'].to_s.empty?

  end

  def process_allele_type row1, type
    row1['allele_type'] = 'None'
    row1['allele_type'] = @guess_mapping[ row1['mutation_type'] ] if (!row1['mutation_type'].blank?) && @guess_mapping.has_key?(row1['mutation_type'])
    row1['allele_type'] = row1['es_cell_allele_type'] if !row1['es_cell_allele_type'].nil?
    row1['allele_type'] = row1['mi_mouse_allele_type'] if !row1['mi_mouse_allele_type'].blank? && type != 'Allele'
    guess_allele_type(row1) if type == 'MouseAlleleModification'

    prepare_allele_symbol(row1, type)
  end

  def guess_allele_type row1
    if !row1['mouse_allele_mod_mouse_allele_type'].blank? and !['a', 'e', ''].include?(row1['mouse_allele_mod_mouse_allele_type'])
      row1['allele_type'] =  row1['mouse_allele_mod_mouse_allele_type']
    else
      # cre version of the mi_attempt allele
      row1['allele_type'] =  @guess_mapping[row1['allele_type']] if @guess_mapping.has_key?(row1['allele_type'])
    end
  end

  def genbank_file row1
    row1['genbank_file_url'] = ""
    row1['allele_image'] = ""

    return if row1['targ_rep_alleles_id'].blank?

    transformation = @genbank_file_transformations[row1['allele_type']]
    row1['genbank_file_url'] = "https://www.mousephenotype.org/imits/targ_rep/alleles/#{row1['targ_rep_alleles_id']}/escell-clone_#{!transformation.blank? ? transformation + '-' : ''}genbank_file"
    row1['allele_image'] = "https://www.mousephenotype.org/imits/targ_rep/alleles/#{row1['targ_rep_alleles_id']}/allele-image#{!transformation.blank? ? '-' + transformation : ''}"
  end

  def delete_index
    proxy = SolrConnect::Proxy.new(@solr_url)

    if @marker_symbol.empty?
      proxy.update({'delete' => {'query' => '*:*'}}.to_json, @solr_user, @solr_password)
    else
      #marker_symbols = @marker_symbol.to_s.split ','

      @marker_symbol.each do |marker_symbol|
        #puts "#### @marker_symbol: #{@marker_symbol}"
        #puts "#### marker_symbol_str:\/#{marker_symbol}\/"
        ##proxy.update({'delete' => {'query' => "marker_symbol_str:\/#{marker_symbol}\/"}}.to_json)
        proxy.update({'delete' => {'query' => "marker_symbol_str:#{marker_symbol}"}}.to_json, @solr_user, @solr_password)
      end
    end

    proxy.update({'commit' => {}}.to_json, @solr_user, @solr_password)
  end

  def send_to_index data
    #pp data
    proxy = SolrConnect::Proxy.new(@solr_url)
    proxy.update(data.join, @solr_user, @solr_password)
    proxy.update({'commit' => {}}.to_json, @solr_user, @solr_password)
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
    return list
  end

  def send_to_index2 filename
    if File.file?(filename)
      file = File.open(filename, "r")
      contents = file.read
      list = JSON.parse(contents)
      send_to_index list
    end
  end

  # pass 1/3

  def run
    puts "#### index: #{@solr_url}"

    if @use_files
      filename = "#{@root}/alleles.json"
      filename2 = "#{@root}/genes.json"

      puts "#### trying to use files..."

      if File.file?(filename) && File.file?(filename2)
        puts "#### using files..."
        delete_index

        send_to_index2 filename
        send_to_index2 filename2

        return
      end
    end

    puts "#### select..."

    rows = ActiveRecord::Base.connection.execute(@sql)

    puts "#### step 1..."

    rows.each do |row1|
      puts "PROCESSING ROW #{row1['marker_symbol']}"
      #pp row1

      if ! @filter_target.empty?
        if ! @marker_filters.include? row1[@filter_target]
          # puts "#### ignoring #{row1['marker_symbol']}: #{row1['feature_type']}"
          next
        end
      end

      next if row1['mouse_allele_mod_status'].to_s.empty?
      next if row1['mouse_allele_mod_status'] == 'Mouse Allele Modification Aborted'

      if row1['cre_excision_required'] == 't'

        row = deep_copy row1

        process_allele_type(row, 'MouseAlleleModification')

        if row['allele_symbol'].to_s.empty?
          row['failed'] = 'pass 1'
          @failures.push row
          next
        end
        next if mark?(row)

        genbank_file(row)
        row['mouse_status'] = row['mouse_allele_mod_status']
        row['phenotype_status'] = row['phenotyping_status']

        row['es_cell_status'] = ''

        row['phenotyping_centre'] = row['phenotyping_centre_name']
        row['production_centre'] = row['pacentre_name']

        @processed_rows.push row

        mark row
      end

      if row1['cre_excision_required'] == 'f'

        row = deep_copy row1

        process_allele_type(row, 'MiAttempt')

        if row['allele_symbol'].to_s.empty?
          row['failed'] = 'pass 1'
          @failures.push row
          next
        end
        next if mark?(row)

        genbank_file(row)
        row['es_cell_status'] = @statuses['ES_CELL_TARGETING_CONFIRMED']
        row['mouse_status'] = @statuses['GENOTYPE_CONFIRMED']
        row['phenotype_status'] = row['phenotyping_status']
        row['production_centre'] = row['miacentre_name']
        row['phenotyping_centre'] = row['phenotyping_centre_name']

        @processed_rows.push row

        mark row
      end
    end

    puts "#### step 2..."

    # pass 2/3

    rows.each do |row1|

      #if ! @filter_target.empty?
      #  if ! @marker_filters.include? row1[@filter_target]
      #    # puts "#### ignoring #{row1['marker_symbol']}: #{row1['feature_type']}"
      #    next
      #  end
      #end

      next if row1['mi_attempt_status'] == 'Micro-injection aborted'

      if ! row1['mi_attempt_status'].to_s.empty?

        row = deep_copy row1

        process_allele_type(row, 'MiAttempt')

        if row['allele_symbol'].to_s.empty?
          row['failed'] = 'pass 2'
          @failures.push row
          next
        end
        next if mark?(row)

        # B4
        genbank_file(row)
        row['es_cell_status'] = @statuses['ES_CELL_TARGETING_CONFIRMED']
        row['mouse_status'] = row['mi_attempt_status']
        row['phenotype_status'] = ''
        row['production_centre'] = row['miacentre_name']

        @processed_rows.push row

        mark row
      end
    end

    puts "#### step 3..."

    # pass 3/3

    rows.each do |row1|

      #if ! @filter_target.empty?
      #  if ! @marker_filters.include? row1[@filter_target]
      #    # puts "#### ignoring #{row1['marker_symbol']}: #{row1['feature_type']}"
      #    next
      #  end
      #end

      # B5

      row = deep_copy row1

      process_allele_type(row, 'Allele')

      if row['allele_symbol'].to_s.empty?
        row['failed'] = 'pass 3'
        @failures.push row
        next
      end
      next if mark?(row)

      if row['does_an_es_cell_exist'] == 't'
        row['es_cell_status'] = @statuses['ES_CELL_TARGETING_CONFIRMED']
      elsif row['does_a_targ_vec_exist'] == 't'
        row['es_cell_status'] = @statuses['ES_CELL_PRODUCTION_IN_PROGRESS']
      else
        row['es_cell_status'] = @statuses['NO_ES_CELL_PRODUCTION']
      end

      genbank_file(row)
      row['mouse_status'] = ''
      row['phenotype_status'] = ''
      row['production_centre'] = ''

      @processed_rows.push row
    end

    key_count = 0
    target = nil

    new_processed_allele_rows = []
    @new_processed_gene_rows = []
    new_processed_rows_hash = {}

    puts "#### step 4..."

    @genes_hash = {}

    @processed_rows.each do |row|

      next if row['marker_symbol'] =~ /cgi_/i

      target = row if key_count < row.keys.size
      key_count = row.keys.size if key_count < row.keys.size

      hash = {}
      hash['marker_symbol'] = row['marker_symbol']

      hash['marker_type'] = row['marker_type']
      hash['feature_type'] = row['feature_type']

      hash['mgi_accession_id'] = row['mgi_accession_id'].to_s
      hash['mgi_accession_id'] = hash['mgi_accession_id'].strip || hash['mgi_accession_id']

      hash['es_cell_status'] = row['es_cell_status'].to_s
      hash['mouse_status'] = row['mouse_status']
      hash['phenotype_status'] = row['phenotype_status'].to_s
      hash['production_centre'] = row['production_centre'].to_s
      hash['phenotyping_centre'] = row['phenotyping_centre'].to_s
      hash['allele_name'] = ''
      hash['allele_name'] = row['allele_symbol'] if row['allele_symbol'].to_s !~ /DUMMY_/
      hash['allele_type'] = row['allele_type']
      hash['genbank_file'] = row['genbank_file_url']
      hash['allele_image'] = row['allele_image']
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
        @genes_hash[hash['marker_symbol']] ||= []
        @genes_hash[hash['marker_symbol']].push hash

        if @use_replacement
          @config['replacements'].each do |allele|

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

    manage_genes2

    if @detect_gene_dups
      #puts "#### check gene duplicates!"

      summary_gene_dups = {}
      gene_dups = {}
      @new_processed_gene_rows.each do |gene|
        gene_dups[gene['marker_symbol']] ||= 0
        gene_dups[gene['marker_symbol']] += 1

        if gene_dups[gene['marker_symbol']] > 1
          summary_gene_dups[gene['marker_symbol']] = gene_dups[gene['marker_symbol']]
        end
      end

      if ! summary_gene_dups.empty?
        puts "#### gene duplicates detected!"
        pp summary_gene_dups
        #else
        #  puts "#### no gene duplicates detected!"
      end
    end

    puts "#### step 6..."

    new_processed_list = build_json new_processed_allele_rows
    new_processed_list2 = build_json @new_processed_gene_rows

    if @create_files
      puts "#### writing files..."
      File.open("#{@root}/alleles.json", 'w') {|f| f.write(new_processed_list.to_json) }
      File.open("#{@root}/genes.json", 'w') {|f| f.write(new_processed_list2.to_json) }
      puts "#### done!"
    end

    if @save_as_csv
      puts "#### save csv..."

      filename = "#{@root}/build_allele2.csv"
      save_csv filename, new_processed_allele_rows
    end

    puts "#### send to index - #{@solr_url}"

    delete_index

    send_to_index new_processed_list if @use_alleles
    new_processed_list = []

    send_to_index new_processed_list2 if @use_genes
    new_processed_list2 = []

    if ! @failures.empty?
      puts "#### write failures..."
      filename = "#{@root}/build_allele2_failures.csv"
      save_csv filename, @failures
    end

    puts "done: alleles/genes/total: #{new_processed_allele_rows.size}/#{@new_processed_gene_rows.size}/#{new_processed_allele_rows.size + @new_processed_gene_rows.size}"
  end

  #def should_include row
  #  return true if @filter_target.empty?
  #  return false if ! @marker_filters.include? row[@filter_target]
  #  return true
  #end

  def manage_genes2
    count = Gene.count
    counter = 0

    rows = ActiveRecord::Base.connection.execute('select marker_symbol, mgi_accession_id, marker_type, feature_type, synonyms from genes') if @marker_symbol.empty?
    marker_symbols = @marker_symbol.to_a.map {|ms| "'#{ms}'" }.join ','
    rows = ActiveRecord::Base.connection.execute("select marker_symbol, mgi_accession_id, marker_type, feature_type, synonyms from genes where marker_symbol in (#{marker_symbols})") if ! @marker_symbol.empty?

    rows.each do |row1|

      next if row1['marker_symbol'] =~ /cgi_/i

      if ! @filter_target.empty?
        if ! @marker_filters.include? row1[@filter_target]
          # puts "#### ignoring #{row1['marker_symbol']}: #{row1['feature_type']}"

          next if ! @genes_hash.has_key?(row1['marker_symbol'])

          empty = true

          @genes_hash[row1['marker_symbol']].each do |row2|
            if ! row2['phenotype_status'].to_s.empty? || ! row2['mouse_status'].to_s.empty? || (! row2['es_cell_status'].to_s.empty? && row2['es_cell_status'].to_s != @statuses['NO_ES_CELL_PRODUCTION'])
              empty = false
              break
            end
          end

          next if empty

          #next if row1['phenotype_status'].to_s.empty? && row1['mouse_status'].to_s.empty? && row1['es_cell_status'].to_s.empty?

          #next
        end
      end

      counter += 1

      #pp row1

      marker_symbol = row1['marker_symbol']

      if ! @genes_hash.has_key?(marker_symbol)
        hash = {}
        hash['synonym'] = ''
        hash['feature_type'] = ''

        hash['marker_symbol'] = row1['marker_symbol']
        hash['mgi_accession_id'] = row1['mgi_accession_id'].to_s
        hash['mgi_accession_id'] = hash['mgi_accession_id'].strip || hash['mgi_accession_id']

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
        hash['synonym'] = row1['synonyms'].to_s.split '|'
        @new_processed_gene_rows.push hash
        next
      end

      #pp @genes_hash[marker_symbol]

      status_hash = {}

      status_hash[:best_phenotype_status] = 0
      status_hash[:best_mouse_status] = 0
      status_hash[:best_es_cell_status] = 0

      status_hash[:phenotype_centre] = []
      status_hash[:mouse_production_centre] = []
      status_hash[:es_cell_production_centre] = ''
      status_hash[:phenotype_started] = false
      status_hash[:phenotype_complete] = false
      status_hash[:phenotype_status] = ''
      status_hash[:es_cell_status] = ''
      status_hash[:mouse_status] = ''

      @genes_hash[marker_symbol].each do |row|
        if ! row['phenotype_status'].to_s.empty?

         # pp row

          status_hash[:phenotype_started] = true if row['phenotype_status'] == 'Phenotyping Started' || row['phenotype_status'] == 'Phenotyping Complete'

          status_hash[:phenotype_complete] = true if row['phenotype_status'] == 'Phenotyping Complete'

          if status_hash[:best_phenotype_status].to_i < @pa_statuses[row['phenotype_status']].to_i
            status_hash[:best_phenotype_status] = @pa_statuses[row['phenotype_status']].to_i
            status_hash[:phenotype_status] = row['phenotype_status']
            status_hash[:phenotype_centre].push row['phenotyping_centre'] if row['phenotyping_centre']
          end
        end

        if ! row['mouse_status'].to_s.empty?

          if status_hash[:best_mouse_status].to_i < @mi_statuses[row['mouse_status']].to_i && (@mi_statuses[row['mouse_status']].to_i == 350 || @mi_statuses[row['mouse_status']].to_i == 360)
            status_hash[:best_phenotype_status] = @pa_statuses[row['mouse_status']].to_i
            status_hash[:best_mouse_status] = @mi_statuses[row['mouse_status']].to_i
            #status_hash[:phenotype_status] = row['mouse_status']
            status_hash[:mouse_status] = row['mouse_status']
            status_hash[:mouse_production_centre].push row['production_centre'] if row['production_centre']
            status_hash[:phenotype_centre].push row['production_centre'] if row['production_centre']

            #status_hash[:phenotype_started] = true if row['phenotype_status'] == 'Phenotyping Started' || row['phenotype_status'] == 'Phenotyping Complete'
          end

          if status_hash[:best_mouse_status].to_i < @mi_statuses[row['mouse_status']].to_i
            status_hash[:best_mouse_status] = @mi_statuses[row['mouse_status']].to_i
            status_hash[:mouse_status] = row['mouse_status']
            status_hash[:mouse_production_centre].push row['production_centre'] if row['production_centre']
          end
        end

        if ! row['es_cell_status'].to_s.empty?

          if status_hash[:best_es_cell_status].to_i < @es_cell_statuses[row['es_cell_status']].to_i
            status_hash[:best_es_cell_status] = @es_cell_statuses[row['es_cell_status']].to_i
            status_hash[:es_cell_status] = row['es_cell_status']
            status_hash[:es_cell_production_centre] = row['production_centre']
          end

        end
      end

      exclude_keys = %W{es_cell_status mouse_status phenotype_status production_centre allele_name allele_type phenotyping_centre}

      row = deep_copy @genes_hash[marker_symbol].first

      exclude_keys.each {|ekey| row.delete(ekey) }

      row['latest_project_status'] = status_hash[:phenotype_status] if ! status_hash[:phenotype_status].empty?
      row['latest_project_status'] = status_hash[:mouse_status] if row['latest_project_status'].to_s.empty? && ! status_hash[:mouse_status].empty?
      row['latest_project_status'] = status_hash[:es_cell_status] if row['latest_project_status'].to_s.empty? && ! status_hash[:es_cell_status].empty?

      row['latest_production_centre'] = status_hash[:phenotype_centre].to_a.uniq if ! status_hash[:phenotype_centre].empty?
      row['latest_production_centre'] = status_hash[:mouse_production_centre].to_a.uniq if row['latest_production_centre'].to_s.empty? && ! status_hash[:mouse_production_centre].empty?
      row['latest_production_centre'] = status_hash[:es_cell_production_centre] if row['latest_production_centre'].to_s.empty? && ! status_hash[:es_cell_production_centre].empty?

      row['latest_phenotyping_centre'] = status_hash[:phenotype_centre].to_a.uniq

      row['latest_phenotype_started'] = status_hash[:phenotype_started] ? '1' : '0'
      row['latest_phenotype_complete'] = status_hash[:phenotype_complete] ? '1' : '0'
      row['latest_phenotype_status'] = status_hash[:phenotype_status]
      row['latest_es_cell_status'] = status_hash[:es_cell_status]
      row['latest_mouse_status'] = status_hash[:mouse_status]
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
        @config['replacements'].each do |allele|
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

      @new_processed_gene_rows.push row
    end

  end

end

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  BuildAllele2.new.run
end