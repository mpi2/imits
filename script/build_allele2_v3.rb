#!/usr/bin/env ruby

require 'pp'
require "digest/md5"
require "#{Rails.root}/script/solr_connect"

class BuildAllele2

  GENE_SQL = <<-EOF
    SELECT genes.* FROM genes;
  EOF


  MICE_ALLELE_SQL = <<-EOF
    WITH mutagenesis_factor_summary AS (

      SELECT mi_attempts.id AS mi_attempt_id, array_agg(mutagenesis_factors.id), array_agg('vector_name:' || CASE WHEN targ_rep_targeting_vectors.name IS NULL THEN '' ELSE  targ_rep_targeting_vectors.name END || ', ' || crispr_details) AS mutagenesis_details
        FROM mutagenesis_factors
          JOIN mi_attempts ON mi_attempts.mutagenesis_factor_id = mutagenesis_factors.id
          JOIN (SELECT targ_rep_crisprs.mutagenesis_factor_id AS mutagenesis_factor_id, string_agg('crispr_seq:' || targ_rep_crisprs.sequence || ', crispr_chromosome:' || targ_rep_crisprs.start || ', crispr_start_co_ordinate:' || targ_rep_crisprs.start || ', crispr_end_co_ordinate:' || targ_rep_crisprs.end, ',') AS crispr_details
                  FROM targ_rep_crisprs
                GROUP BY targ_rep_crisprs.mutagenesis_factor_id
               ) AS crispr_summary ON mutagenesis_factors.id = crispr_summary.mutagenesis_factor_id
          LEFT JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.id = mutagenesis_factors.vector_id
        GROUP BY mi_attempts.id
    ),

      mi_attempt_summary AS (
        SELECT mi_attempts.id AS mi_attempt_id, mi_attempts.external_ref AS mi_external_ref, mi_attempt_statuses.name AS mi_status_name, mi_attempts.report_to_public AS mi_report_to_public,
               blast_strain.name AS mi_blast_strain_name, test_cross_strain.name AS mi_test_cross_strain_name,
               targ_rep_es_cells.id AS es_cell_id, targ_rep_es_cells.name AS es_cell_name, targ_rep_es_cells.mgi_allele_symbol_superscript AS es_cell_mgi_allele_symbol_superscript, targ_rep_es_cells.allele_type AS es_cell_allele_type, targ_rep_es_cells.allele_symbol_superscript_template AS es_cell_allele_superscript_template,
               mutagenesis_factor_summary.mutagenesis_details AS mi_mutagenesis_factor_details,
               colonies.id AS mi_colony_id, colonies.name AS mi_colony_name, colonies.mgi_allele_id AS mi_colony_mgi_allele_id, colonies.allele_name AS mi_colony_allele_name, colonies.mgi_allele_symbol_superscript AS mi_colony_mgi_allele_symbol_superscript, colonies.allele_symbol_superscript_template AS mi_colony_allele_symbol_superscript_template, colonies.allele_type AS mi_colony_allele_type, colony_background_strain.name AS mi_colony_background_strain_name
          FROM mi_attempts
            LEFT JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id
            JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
            LEFT JOIN strains blast_strain ON blast_strain.id = mi_attempts.blast_strain_id
            LEFT JOIN strains test_cross_strain ON test_cross_strain.id = mi_attempts.test_cross_strain_id
            LEFT JOIN strains colony_background_strain ON colony_background_strain.id = colonies.background_strain_id
            LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
            LEFT JOIN mutagenesis_factor_summary ON mutagenesis_factor_summary.mi_attempt_id = mi_attempts.id
        WHERE mi_attempts.experimental = false AND mi_attempt_statuses.name != 'Micro-injection aborted'
    ),

      phenotyping_production_summary AS (
        SELECT parent_colony_id, (array_agg(phenotyping_production_statuses.name ORDER BY phenotyping_production_statuses.order_by DESC))[1] AS phenotyping_status_name, string_agg(centres.name, ',') AS phenotyping_centres
        FROM phenotyping_productions
          JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = phenotyping_productions.status_id
          JOIN mi_plans ON mi_plans.id = phenotyping_productions.mi_plan_id
          JOIN centres ON centres.id = mi_plans.production_centre_id
        WHERE phenotyping_production_statuses.name != 'Phenotype Production Aborted'
        GROUP BY parent_colony_id
      )


    -- Note! the colony data in colonies and mi_attempt_summary is the same when the colony was created via micro_injection.

    SELECT CASE WHEN colonies.mouse_allele_mod_id IS NOT NULL THEN 'MouseAlleleMod' ELSE 'MiAttempt' END AS colony_created_by,
           colonies.name AS colony_name, colonies.mgi_allele_id AS colony_mgi_allele_id, colonies.allele_name AS colony_allele_name, colonies.mgi_allele_symbol_superscript AS colony_mgi_allele_symbol_superscript, colonies.allele_symbol_superscript_template AS colony_allele_symbol_superscript_template, colonies.allele_type AS colony_allele_type, colony_background_strain.name AS colony_background_strain_name,
           mouse_allele_mod_statuses.name AS mouse_allele_status_name, deleter_strain.name AS mouse_allele_mod_deleter_strain,
           mi_attempt_summary.*,
           phenotyping_production_summary.phenotyping_status_name AS phenotyping_status_name, phenotyping_production_summary.phenotyping_centres AS phenotyping_centres
    FROM colonies
      JOIN strains colony_background_strain ON colony_background_strain.id = colonies.background_strain_id
      LEFT JOIN (mouse_allele_mods
                  LEFT JOIN strains deleter_strain ON deleter_strain.id = mouse_allele_mods.deleter_strain_id
                  JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
                ) ON mouse_allele_mods.id = colonies.mouse_allele_mod_id AND mouse_allele_mods.report_to_public = true
      JOIN mi_attempt_summary ON mi_attempt_summary.mi_colony_id = mouse_allele_mods.parent_colony_id OR (mi_attempt_summary.mi_colony_id = colonies.id AND mi_attempt_summary.mi_report_to_public = true)
      LEFT JOIN phenotyping_production_summary ON phenotyping_production_summary.parent_colony_id = colonies.id
    WHERE colonies.report_to_public = true OR mi_mutagenesis_factor_details IS NULL
  EOF

  ES_CELL_VECTOR_ALLELES_SQL = <<-EOF
  SELECT targ_rep_es_cells.mgi_allele_symbol_superscript, targ_rep_es_cells.allele_symbol_superscript_template, targ_rep_es_cells.allele_type, targ_rep_alleles.cassette AS cassette, targ_rep_alleles.project_design_id AS design_id,
  count(targ_rep_targeting_vectors.id) num_targeting_vectors, count(targ_rep_es_cells.id) num_es_cells, array_agg(es_ikmc_projects.name) AS es_ikmc_projects_not_distinct, array_agg(es_pipelines.name) AS es_pipelines_not_distinct, array_agg(tv_ikmc_projects.name) AS tv_ikmc_projects_not_distinct, array_agg(tv_pipelines.name) AS tv_pipelines_not_distinct
  FROM targ_rep_alleles
    LEFT JOIN targ_rep_es_cells ON targ_rep_alleles.id = targ_rep_es_cells.allele_id AND targ_rep_es_cells.report_to_public = true
    LEFT JOIN targ_rep_pipelines es_pipelines ON es_pipelines.id = targ_rep_es_cells.pipeline_id

    LEFT JOIN targ_rep_ikmc_projects es_ikmc_projects ON es_ikmc_projects.id = targ_rep_es_cells.ikmc_project_foreign_id

    LEFT JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id AND targ_rep_targeting_vectors.report_to_public = true
    LEFT JOIN targ_rep_pipelines tv_pipelines ON tv_pipelines.id = targ_rep_targeting_vectors.pipeline_id
    LEFT JOIN targ_rep_ikmc_projects tv_ikmc_projects ON tv_ikmc_projects.id = targ_rep_targeting_vectors.ikmc_project_foreign_id

  GROUP BY targ_rep_es_cells.mgi_allele_symbol_superscript, targ_rep_es_cells.allele_symbol_superscript_template, targ_rep_es_cells.allele_type, targ_rep_alleles.cassette, targ_rep_alleles.project_design_id
  EOF


  def initialize(show_eucommtoolscre = false)
    @show_eucommtoolscre = show_eucommtoolscre
    @config = YAML.load_file("#{Rails.root}/script/build_allele2_v2.yml")

    @solr_update = YAML.load_file("#{Rails.root}/config/solr_update.yml")

    @mouse_status_list = {}
    PhenotypingProduction::Status.all.each{|status| @status_list[status['name']] = status['order_by']}
    MouseAlleleMod::Status.all.each{|status| @status_list[status['name']] = status['order_by']}
    MiAttempt::Status.all.each{|status| @status_list[status['name']] = status['order_by']}


    @solr_user = @config['options']['SOLR_USER']
    @solr_password = @config['options']['SOLR_PASSWORD']

    pp @config['options']

    puts "#### loading alleles!" if @use_alleles
    puts "#### loading genes!" if @use_genes

    sql_template = @config['sql_template']
    @gene_sql = GENE_SQL
    @mouse_sql = MICE_ALLELE_SQL
    @es_cell_and_targeting_vector_sql = ES_CELL_VECTOR_ALLELES_SQL
    marker_symbols = @marker_symbol.to_a.map {|ms| "'#{ms}'" }.join ','

#    @mouse_sql.gsub!(/SUBS_TEMPLATE3/, "where marker_symbol in (#{marker_symbols})") if ! @marker_symbol.empty?
#    @mouse_sql.gsub!(/SUBS_TEMPLATE3/, '') if @marker_symbol.empty?

#    @es_cell_and_targeting_vector_sql.gsub!(/SUBS_TEMPLATE3/, "where marker_symbol in (#{marker_symbols})") if ! @marker_symbol.empty?
#    @es_cell_and_targeting_vector_sql.gsub!(/SUBS_TEMPLATE3/, '') if @marker_symbol.empty?


    if @show_eucommtoolscre
#      @mouse_sql.gsub!(/SUBS_EUCOMMTOOLSCRE_ID/, ' = 8 ')
#      @mouse_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " = 'EUCOMMToolsCre'")

#      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_EUCOMMTOOLSCRE_ID/, ' = 8 ')
#      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " = 'EUCOMMToolsCre'")

#      @solr_url = @solr_update[Rails.env]['index_proxy']['eucommtoolscre_allele2']
    else
#      @mouse_sql.gsub!(/SUBS_EUCOMMTOOLSCRE_ID/, ' != 8 ')
#      @mouse_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " != 'EUCOMMToolsCre'")

#      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_EUCOMMTOOLSCRE_ID/, ' != 8 ')
#      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " != 'EUCOMMToolsCre'")

#      @solr_url = @solr_update[Rails.env]['index_proxy']['allele2']
    end

    @allele_data = {}
    @gene_data = {}

    @genbank_file_transformations = {'a'   => '',
                                     'e'   => '',
                                     ''    => '',
                                     'b'   => 'cre',
                                     'e.1' => 'cre',
                                     '.1'  => 'cre',
                                     'c'   => 'flp',
                                     'd'   => 'flp-cre'
                                     }

    @mutation_types = {
                      'a' => 'Conditional Ready',
                      'e' => 'Targeted Non Conditional',
                      '' => 'Deletion'
                      }
    puts "#### #{@solr_url}/admin/"
  end




  def get_allele_doc(data_row, allele_details)
    return @allele_data[data_row['gene_mgi_accession_id'] + allele_details['allele_symbol']] || create_new_default_allele_doc(data_row, allele_details)
  end

  def get_gene_doc(row, allele_details)
    return @gene_data[data_row['gene_mgi_accession_id']
  end

  def create_new_default_allele_doc(data_row, allele_details)

    links = []
    links <<   "southern_tools:#{TargRep::Allele.southern_tools_url({'es_cell_name' => data_row['es_cell_name']})}"
    links <<   "lrpcr_genotype_primers:#{TargRep::Allele.southern_tools_url('mgi_gene_accession_id' => data_row['mgi_gene_accession_id'], 'allele_symbol' => allele_details['allele_symbol'])}"
    links <<   "genotype_primers:#{TargRep::Allele.genotype_primers_url('mgi_gene_accession_id' => data_row['mgi_gene_accession_id'], 'allele_symbol' => allele_details['allele_symbol'])}"
    links <<   "mutagenesis_url:#{TargRep::Allele.mutagenesis_url('mgi_gene_accession_id' => data_row['mgi_gene_accession_id'], 'allele_symbol' => allele_details['allele_symbol'])}"


    return {'marker_symbol' => data_row['gene_symbol'],
            'mgi_accession_id' => data_row['gene_mgi_accession_id'],
            'allele_symbol' => allele_details['allele_symbol'],
            'allele_mgi_accession_id' => allele_details['allele_mgi_accession_id'],
            'allele_type' => allele_details['allele_type'] ,
            'allele_description' => allele_details[''],
            'genbank_file' => allele_details['allele_id'].blank? ? '' : TargRep::Allele.genbank_file_url(allele_details['allele_id']),
            'allele_image' => allele_details['allele_id'].blank? ? '' : TargRep::Allele.simple_allele_image_url(allele_details['allele_id']),
            'allele_simple_image' => allele_details['allele_id'].blank? ? '' : TargRep::Allele.simple_allele_image_url(allele_details['allele_id']),
            'design_id' => '',
            'cassette' => '',
            'pipeline' => [],
            'ikmc_project' => [],
            'mouse_status' => '',
            'phenotype_status' => '',
            'es_cell_status' => '',
            'production_centre' => '',
            'phenotyping_centre' => '',
            'links' => links,
            'type' => 'Allele'}
  end

  def mouse_allele_update_doc(doc, data_row)

    mouse_status = data_row['mouse_allele_status_name'] || data_row['mi_attempt_status_name']

    doc['mouse_status'] = mouse_status if mouse_status_is_more_adavanced(mouse_status, doc['mouse_status'])
    doc['phenotype_status'] = data_row['phenotyping_status_name'] if mouse_status_is_more_adavanced(data_row['phenotyping_status_name'], doc['phenotype_status'])

    convert_to_array(data_row['phenotyping_centres']).each{|phenotyping_centre| doc['production_centres'] << phenotyping_centre} unless data_row['production_centres'].blank?
    convert_to_array(data_row['phenotyping_centres']).each{|phenotyping_centre| doc['phenotyping_centre'] << phenotyping_centre} unless data_row['phenotyping_centres'].blank?

    doc['production_centres'].uniq
    doc['phenotyping_centre'].uniq

    return true
  end

  def es_cell_allele_update_doc(doc, data_row)
    doc['design_id'] = data_row['design_id']
    doc['cassette'] = data_row['cassette']
    doc['links'] << "loa_link_id:#{row['targ_rep_alleles_id']}"

    # set ES Cell status
    if data_row['num_es_cells'] > 0 || doc['es_cell_status'] == 'ES Cell Targeting Confirmed'
      doc['es_cell_status'] = 'ES Cell Targeting Confirmed'
    elsif data_row['num_targeting_vectors'] > 0 || doc['es_cell_status'] == 'ES Cell Production in Progress'
      doc['es_cell_status'] = 'ES Cell Production in Progress'
    else
      doc['es_cell_status'] = 'No ES Cell Production'
    end

    convert_to_array(data_row['es_pipelines_not_distinct']).each{|phenotyping_centre| doc['pipeline'] << phenotyping_centre} unless data_row['es_pipelines_not_distinct'].blank?
    convert_to_array(data_row['tv_pipelines_not_distinct']).each{|phenotyping_centre| doc['pipeline'] << phenotyping_centre} unless data_row['tv_pipelines_not_distinct'].blank?

    convert_to_array(data_row['es_ikmc_projects_not_distinct']).each{|phenotyping_centre| doc['ikmc_project'] << phenotyping_centre} unless data_row['es_ikmc_projects_not_distinct'].blank?
    convert_to_array(data_row['tv_ikmc_projects_not_distinct']).each{|phenotyping_centre| doc['ikmc_project'] << phenotyping_centre} unless data_row['tv_ikmc_projects_not_distinct'].blank?

    doc['pipeline'].uniq
    doc['ikmc_project'].uniq
    doc['links'].uniq

    return true
  end

  def create_new_default_gene_doc(data_row)
    gene_doc =  {'marker_symbol' => data_row['marker_symbol'],
                 'mgi_accession_id' => data_row['mgi_accession_id'],
                 'marker_type' => data_row['marker_type'],
                 'marker_name' => data_row['marker_name'],
                 'synonym' => data_row['synonyms'],
                 'feature_type' => data_row['feature_type'],
                 'feature_chromosome' => data_row['chr'],
                 'feature_strand' => data_row['strand_name'],
                 'feature_coord_start' => data_row['start_coordinates'],
                 'feature_coord_end' => data_row['end_coordinates'],
                 'gene_model_ids' => ["ensembl_ids:#{data_row['ensembl_ids']}", "vega_ids:#{data_row['vega_ids']}", "ncbi_ids:#{data_row['ncbi_ids']}", "ccds_ids:#{data_row['ccds_ids']}"],
                  hash['genetic_map_links'] = [],
                  hash['sequence_map_links'] = [],
                 'pipeline' => [],
                 'ikmc_project' => [],
                 'mouse_status' => '',
                 'phenotype_status' => '',
                 'es_cell_status' => '',
                 'production_centre' => '',
                 'phenotyping_centre' => '',
                 'production_centres' => '',
                 'phenotyping_centres' => '',
                 'links' => [],
                 'type' => 'Gene'
                }

    unless  data_row['chr'].blank? || data_row['start_coordinates'].blank? || data_row['end_coordinates'].blank?
      hash['genetic_map_links'] = ["mgi:http://www.informatics.jax.org/searches/linkmap.cgi?chromosome=#{data_row['chr']}&midpoint=#{data_row['cm_position']}&cmrange=1.0&dsegments=1&syntenics=0"] if data_row['cm_position'].blank?
      vega_id = data_row['vega_ids'].blank? ? "" : "g=#{data_row['vega_ids'].split(',').sort{|s1, s2| s2 <=> s1}[0]};"
      ensum_id = data_row['ensembl_ids'].blank? ? "" :"g=#{data_row['ensembl_ids'].split(',').sort{|s1, s2| s2 <=> s1}[0]};"
      hash['sequence_map_links']  << "vega:http://vega.sanger.ac.uk/Mus_musculus/Location/View?#{vega_id}r=#{data_row['chr']}:#{data_row['start_coordinates']}-#{data_row['end_coordinates']}"
      hash['sequence_map_links']  << "ensembl:http://www.ensembl.org/Mus_musculus/Location/View?#{ensum_id}r=#{data_row['chr']}:#{data_row['start_coordinates']}-#{data_row['end_coordinates']}"
      hash['sequence_map_links']  << "ucsc:http://genome.ucsc.edu/cgi-bin/hgTracks?db=mm10&position=chr#{data_row['chr']}%3A#{data_row['start_coordinates']}-#{data_row['end_coordinates']}"
      hash['sequence_map_links']  << "ncbi:http://www.ncbi.nlm.nih.gov/mapview/maps.cgi?TAXID=10090&CHR=#{data_row['chr']}&MAPS=genes%5B#{data_row['start_coordinates']}:#{data_row['end_coordinates']}%5D"
    end

    return gene_doc
  end

  def mouse_gene_update_doc(doc, data_row)
            'mouse_status' => '',
            'phenotype_status' => '',
            'production_centre' => '',
            'phenotyping_centre' => '',
            'production_centres' => '',
            'phenotyping_centres' => '',
            'links' => [],
  end

  def es_cell_gene_update_doc(doc, data_row)
            'es_cell_status' => '',
            'links' => [],
  end

  def mouse_status_is_more_adavanced(status_challeger, doc_status)
    if @mouse_status_list[doc_status] < @mouse_status_list[status_challeger]
      return true
    else
      return false
    end
  end

  def generate_data
    puts "#### index: #{@solr_url}"

    puts "#### step 1 - Process Default Genes details..."

    puts "#### select..."
    #puts @sql
    rows = ActiveRecord::Base.connection.execute(@gene_sql)

    rows.each do |row|
      puts "PROCESSING ROW #{row['marker_symbol']}"
      #pp row
      create_new_default_gene_doc(row)
    end


    puts "#### step 2 - Process Mice Data..."

    puts "#### select..."
    #puts @sql
    rows = ActiveRecord::Base.connection.execute(@mouse_sql)

    rows.each do |row|
      #pp row

      # ignore if mouse status is aborted
      next if !row['mouse_allele_mod_status'].blank? && row['mouse_allele_mod_status'] == 'Mouse Allele Modification Aborted'
      next if !row['mi_status_name'].blank? && row['mi_status_name'] == 'Micro-injection aborted'

      # Update gene doc
      puts "Grab gene doc for #{row['marker_symbol']} and update mouse information"
      doc = get_gene_doc(row, allele_details)
      mouse_gene_update_doc(doc, row)

      puts "Calculating allele"
      allele_details = process_allele_type(row)

      # Update allele doc
      puts "Grab allele doc for #{allele_details['allele_symbol']} and update mouse information"
      doc = get_allele_doc(row, allele_details)
      mouse_allele_update_doc(doc, row)

    end



    puts "#### step 3 - Process ES Cell and Targeting Vector Data..."

    puts "#### select..."
    #puts @sql
    rows = ActiveRecord::Base.connection.execute(@es_cell_and_targeting_vector_sql)

    # pass 2/3

    rows.each do |row|
      #pp row

      # Update gene doc
      puts "Grab gene doc for #{row['marker_symbol']} and update ES Cell information"
      doc = get_gene_doc(row, allele_details)
      es_cell_gene_update_doc(doc, row)

      puts "Calculating allele"
      allele_details = process_allele_type(row)

      # Update allele doc
      puts "Grab allele doc for #{allele_details['allele_symbol']} and update ES Cell information"
      doc = get_allele_doc(row, allele_details)
      es_cell_allele_update_doc(doc, row)
    end

  end


  def save to_file
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

    CSV.open(filename, "wb") do |csv|
      csv << data.first.keys
      data.each do |hash|
        csv << hash.values
      end
    end


  end


  def load_from_file(file)

  end

  def update_solr

    if @allele_data.blank? && @gene_data.blank?
      return 'No data to update'
    elsif @allele_data.blank? || @gene_data.blank?
      raise 'Error. Inconsistent data.'
    end

  end







  def genbank_file row1
    row1['genbank_file_url'] = ""
    row1['allele_image'] = ""
    row1['allele_simple_image'] = ""

    row1['allele_simple_image'] = "https://www.i-dcc.org/imits/images/targ_rep/cripsr_map.jpg" if ! row1['mutagenesis_factor_id'].blank?

    return if row1['allele_type'] == 'em' || row1['targ_rep_alleles_id'].blank?

    if !row1['mi_mouse_allele_type'].blank? and row1['es_cell_allele_type'] != row1['mi_mouse_allele_type']
      return if try_to_find_correct_allele(row1)
    end
    transformation = @genbank_file_transformations[row1['allele_type']]
    row1['genbank_file_url'] = "https://www.i-dcc.org/imits/targ_rep/alleles/#{row1['targ_rep_alleles_id']}/escell-clone-#{!transformation.blank? ? transformation + '-' : ''}genbank-file"
    row1['allele_image'] = "https://www.i-dcc.org/imits/targ_rep/alleles/#{row1['targ_rep_alleles_id']}/allele-image#{!transformation.blank? ? '-' + transformation : ''}"
    row1['allele_simple_image'] = "https://www.i-dcc.org/imits/targ_rep/alleles/#{row1['targ_rep_alleles_id']}/allele-image#{!transformation.blank? ? '-' + transformation : ''}?simple=true.jpg"
  end

  def set_mutagenesis_factor row1
    allele_type = row1['allele_type']
    pipeline = row1['pipeline']

    return if allele_type.blank? || pipeline.blank?
    return if ['NorCOMM', 'EUCOMMToolsCre', 'Mirko', 'KOMP-Regeneron'].include?(pipeline)
    return unless ['a', 'c', 'e', ''].include?(allele_type)

    row1['links'] << "mutagenesis_url:https://www.mousephenotype.org/phenotype-archive/mutagenesis/#{row1['mgi_accession_id']}/#{row1['allele_symbol']}"
  end


  def try_to_find_correct_allele(row1)
    sql = <<-EOF
      SELECT a2.*
      FROM targ_rep_alleles AS a1
        JOIN targ_rep_alleles AS a2 ON
          a1.cassette = a2.cassette AND
          a1.homology_arm_start = a2.homology_arm_start AND
          a1.homology_arm_end = a2.homology_arm_end AND
          a1.cassette_start = a2.cassette_start AND
          a1.cassette_end = a2.cassette_end AND
          a1.id != a2.id
        JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = a2.mutation_type_id
      WHERE a1.id = #{row1['targ_rep_alleles_id']} AND targ_rep_mutation_types.name = '#{@mutation_types[row1['mi_mouse_allele_type']]}'
    EOF

    rows = ActiveRecord::Base.connection.execute(sql)
    if rows.count > 0
      row1['allele_mgi_accession_id'] = ""
      row1['targ_rep_alleles_id'] = rows[0]['id']
      return false
    else
      row1['allele_mgi_accession_id'] = ""
      return true
    end
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


  def self.convert_to_array psql_array
    return [] if psql_array.blank?

    psql_array[1, psql_array.length-2].gsub('"', '').split(',')
  end

end



if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  puts "## Start Rebuild of the Allele 2 Core #{Time.now}"
  BuildAllele2.new.run
  puts "## Completed Rebuild of the Allele 2 Core#{Time.now}"

  puts "## Start Rebuild of the EUCOMMToolsCre Allele 2 Core#{Time.now}"
  BuildAllele2.new(true).run
  puts "## Completed Rebuild of the EUCOMMToolsCre Allele 2 Core#{Time.now}"
end
