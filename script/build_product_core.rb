#!/usr/bin/env ruby

require 'pp'
require "digest/md5"
require "#{Rails.root}/script/solr_connect"

class BuildProductCore

  PLAN_SQL= <<-EOF
    SELECT mi_plans.id AS id,
       mi_plans.mutagenesis_via_crispr_cas9 AS crispr_plan,
       genes.marker_symbol AS marker_symbol, genes.mgi_accession_id AS mgi_accession_id,
       mi_plans.gene_id AS gene_id,
       centres.name AS production_centre_name,
       mi_plans.ignore_available_mice AS ignore_available_mice
    FROM mi_plans
      JOIN centres ON centres.id = mi_plans.production_centre_id
      JOIN genes ON genes.id = mi_plans.gene_id
    WHERE mi_plans.report_to_public = true AND mi_plans.ignore_available_mice = false
  EOF


  ES_CELL_SQL= <<-EOF
    SELECT targ_rep_es_cells.*,
      targ_rep_targeting_vectors.name AS targeting_vector_name,
      targ_rep_mutation_types.name AS mutation_type,
      targ_rep_alleles.cassette AS cassette,
      targ_rep_alleles.cassette_type AS cassette_type,
      targ_rep_alleles.backbone AS backbone,
      genes.marker_symbol AS marker_symbol,
      genes.mgi_accession_id AS mgi_accession_id
    FROM targ_rep_es_cells
      JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
      JOIN genes ON genes.id = targ_rep_alleles.gene_id
      LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
      LEFT JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.id = targ_rep_es_cells.targeting_vector_id
  EOF

  DISTRIBUTION_CENTRES_SQL= <<-EOF
    SELECT all_dis_centres.mi_attempt_id, all_dis_centres.phenotype_attempt_id, array_agg(all_dis_centres.centre_name) AS centre_names, array_agg(all_dis_centres.distribution_network) AS distribution_networks, array_agg(all_dis_centres.start_date) AS start_dates, array_agg(all_dis_centres.end_date) AS end_dates
    FROM
    (
      SELECT mi_attempt_id AS mi_attempt_id, NULL AS phenotype_attempt_id, centres.name AS centre_name, distribution_network, start_date, end_date
      FROM mi_attempt_distribution_centres
      LEFT JOIN centres ON centres.id = mi_attempt_distribution_centres.centre_id
      UNION ALL
      SELECT NULL AS mi_attempt_id, phenotype_attempt_id AS phenotype_attempt_id, centres.name AS centre_name, distribution_network, start_date, end_date
      FROM phenotype_attempt_distribution_centres
      LEFT JOIN centres ON centres.id = phenotype_attempt_distribution_centres.centre_id
    ) AS all_dis_centres
    GROUP BY all_dis_centres.mi_attempt_id, all_dis_centres.phenotype_attempt_id
  EOF

  def self.es_cell_sql
    sql = <<-EOF
      WITH es_cells AS (#{ES_CELL_SQL}),
      mouse_colonies AS (
        SELECT mi_attempts.es_cell_id AS es_cell_id, array_agg(mi_attempts.colony_name) AS list
        FROM mi_attempts
        GROUP BY mi_attempts.es_cell_id
      ),
      distribution_qcs AS (
        SELECT grouped_distribution_qc.es_cell_id, GROUPED_QC_FIELDS AS distribution_qc_data
        FROM
        (
          SELECT targ_rep_distribution_qcs.es_cell_id AS es_cell_id,
          QC_FIELDS
          FROM targ_rep_distribution_qcs
          JOIN targ_rep_es_cell_distribution_centres ON targ_rep_es_cell_distribution_centres.id = targ_rep_distribution_qcs.es_cell_distribution_centre_id
          GROUP BY targ_rep_distribution_qcs.es_cell_id
        ) AS grouped_distribution_qc
      )

      SELECT es_cells.name AS es_cell_name,
        es_cells.targeting_vector_name AS vector_name,
        es_cells.mutation_type AS mutation_type,
        es_cells.parental_cell_line AS parental_cell_line,
        es_cells.cassette AS cassette,
        es_cells.cassette_type AS cassette_type,
        es_cells.backbone AS backbone,
        es_cells.marker_symbol AS marker_symbol,
        es_cells.mgi_accession_id AS mgi_accession_id,
        es_cells.allele_id AS allele_id,
        es_cells.allele_symbol_superscript_template AS allele_symbol_superscript_template,
        es_cells.mgi_allele_symbol_superscript AS allele_symbol_superscript,
        es_cells.allele_type AS es_cell_allele_type,
        es_cells.strain AS strain,
        mouse_colonies.list AS colonies,
        targ_rep_pipelines.name AS pipeline,
        targ_rep_ikmc_projects.name AS ikmc_project_id,
        es_cells.created_at AS status_date,
        ARRAY[ES_CELL_QC_RESULTS] AS qc_data,
        distribution_qcs.distribution_qc_data AS distribution_qc
      FROM es_cells
      LEFT JOIN mouse_colonies ON mouse_colonies.es_cell_id = es_cells.id
      LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = es_cells.ikmc_project_foreign_id
      LEFT JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
      LEFT JOIN distribution_qcs ON distribution_qcs.es_cell_id = es_cells.id
      WHERE es_cells.report_to_public = true
      ORDER BY es_cell_name
    EOF

    sql['ES_CELL_QC_RESULTS'] = TargRep::EsCell.qc_options.map{|key, value| md = /^(\w*)_qc_(\w*)/.match(key); "'#{md[1].capitalize} QC:#{md[2]}:' || es_cells.#{key}" }.join(', ')
    sql['GROUPED_QC_FIELDS'] = TargRep::DistributionQc.get_qc_metrics.map{|key, value| "grouped_distribution_qc.#{key}"}.join(' || ')
    sql['QC_FIELDS'] = TargRep::DistributionQc.get_qc_metrics.map{|key, value| "array_agg('Distribution QC (' || targ_rep_es_cell_distribution_centres.name || '):#{value[:name].gsub("'", "")}:' || targ_rep_distribution_qcs.#{key}) AS #{key}" }.join(', ')
    return sql
  end

  def self.targeting_vectors_sql
    #es_cell_names finds all es_cells created from the targeting vector and orders them by the allele_type (tm1, tm1a then tm1e).This will allow your to determine the targeting vector allele_type by selecting the first allele_type of the list
    <<-EOF
      WITH es_cell_names AS (
        SELECT es_cells.targeting_vector_id AS targeting_vector_id, array_agg(es_cells.mgi_allele_symbol_superscript) AS allele_names,array_agg(es_cells.allele_type) AS allele_types, array_agg(es_cells.name) AS list
        FROM
          (SELECT targ_rep_es_cells.*
          FROM targ_rep_es_cells
          ORDER BY targ_rep_es_cells.targeting_vector_id, targ_rep_es_cells.mgi_allele_symbol_superscript) AS es_cells
        GROUP BY es_cells.targeting_vector_id
      )

      SELECT genes.marker_symbol AS marker_symbol,
             genes.mgi_accession_id AS mgi_accession_id,
             targ_rep_mutation_types.code AS allele_type,
             targ_rep_alleles.id AS allele_id,
             targ_rep_alleles.cassette AS cassette,
             targ_rep_alleles.cassette_type AS cassette_type,
             targ_rep_alleles.backbone AS backbone,
             targ_rep_alleles.project_design_id AS design_id,
             targ_rep_targeting_vectors.name AS vector_name,
             'Targeting Vector' AS vector_type,
             es_cell_names.list AS es_cell_names,
             es_cell_names.allele_names AS allele_names,
             es_cell_names.allele_types AS allele_types,
             targ_rep_pipelines.name AS pipeline,
             targ_rep_ikmc_projects.name AS ikmc_project_id,
             targ_rep_targeting_vectors.created_at AS status_date
      FROM targ_rep_targeting_vectors
        JOIN targ_rep_alleles ON targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id
        LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
        JOIN genes ON genes.id = targ_rep_alleles.gene_id
        LEFT JOIN es_cell_names ON es_cell_names.targeting_vector_id = targ_rep_targeting_vectors.id
        LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = targ_rep_targeting_vectors.ikmc_project_foreign_id
        LEFT JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
      WHERE targ_rep_targeting_vectors.report_to_public = true AND targ_rep_alleles.type = 'TargRep::TargetedAllele'
      ORDER BY targ_rep_targeting_vectors.name
    EOF
  end

  def self.intermediate_vectors_sql
    <<-EOF
      WITH es_cell_names AS (
        SELECT es_cells.intermediate_vector AS intermediate_vector, array_agg(es_cells.mgi_allele_symbol_superscript) AS allele_names,array_agg(es_cells.allele_type) AS allele_types
        FROM
          (SELECT targ_rep_es_cells.*, targ_rep_targeting_vectors.intermediate_vector AS intermediate_vector
          FROM targ_rep_es_cells
          JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.id = targ_rep_es_cells.targeting_vector_id
          WHERE targ_rep_targeting_vectors.intermediate_vector IS NOT NULL AND targ_rep_targeting_vectors.intermediate_vector != '' AND
            targ_rep_es_cells.mgi_allele_symbol_superscript IS NOT NULL AND targ_rep_es_cells.mgi_allele_symbol_superscript != '' AND
            targ_rep_es_cells.allele_type IS NOT NULL AND targ_rep_es_cells.allele_type != ''
          ORDER BY targ_rep_targeting_vectors.intermediate_vector, targ_rep_es_cells.mgi_allele_symbol_superscript) AS es_cells
        GROUP BY es_cells.intermediate_vector
      )

      SELECT distinct_intermediate_vectors.*, es_cell_names.allele_names AS allele_names, es_cell_names.allele_types AS allele_types
      FROM
      (
        SELECT DISTINCT intermediate.design_id AS design_id, intermediate.marker_symbol AS marker_symbol, intermediate.mgi_accession_id AS mgi_accession_id, intermediate.vector_name AS vector_name,
          intermediate.mutation_type AS mutation_type,
          'Intermediate Vector' AS vector_type,
          intermediate.cassette AS cassette,
          intermediate.pipeline AS pipeline,
          intermediate.mutation_type AS mutation_type
        FROM
          (SELECT targ_rep_alleles.project_design_id AS design_id, targ_rep_targeting_vectors.intermediate_vector AS vector_name, targ_rep_alleles.cassette AS cassette, targ_rep_pipelines.name AS pipeline, genes.marker_symbol AS marker_symbol, genes.mgi_accession_id AS mgi_accession_id, targ_rep_mutation_types.code AS mutation_type
            FROM targ_rep_targeting_vectors
              JOIN targ_rep_alleles ON targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id
              JOIN genes ON genes.id = targ_rep_alleles.gene_id
              LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
              LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = targ_rep_targeting_vectors.ikmc_project_foreign_id
              LEFT JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
            WHERE targ_rep_targeting_vectors.intermediate_vector IS NOT NULL AND targ_rep_targeting_vectors.intermediate_vector != ''
            ) AS intermediate
        ORDER BY intermediate.vector_name
      ) AS distinct_intermediate_vectors
      LEFT JOIN es_cell_names ON es_cell_names.intermediate_vector = distinct_intermediate_vectors.vector_name
    EOF
  end

  def self.mice_lines_sql
    sql = <<-EOF
      WITH plans AS (#{PLAN_SQL}), es_cells AS (#{ES_CELL_SQL}),
      distribution_centres AS (#{DISTRIBUTION_CENTRES_SQL})

      SELECT 'MiAttempt' AS type,
        '' AS mouse_allele_mod_allele_type,
        mi_attempts.mouse_allele_type AS mi_attempt_mouse_allele_type,
        es_cells.allele_type AS es_cell_allele_type,
        plans.marker_symbol AS marker_symbol, plans.mgi_accession_id AS mgi_accession_id,
        plans.production_centre_name AS production_centre,
        es_cells.allele_id AS allele_id,
        es_cells.allele_symbol_superscript_template AS allele_symbol_superscript_template,
        es_cells.mgi_allele_symbol_superscript AS allele_symbol_superscript,
        plans.crispr_plan AS crispr_plan,
        mi_attempts.colony_name AS colony_name,
        '' AS parent_colony_name,
        mi_attempt_statuses.name AS mouse_status,
        mi_attempt_status_stamps.created_at AS mouse_status_date,
        es_cells.name AS es_cell_name,
        targ_rep_ikmc_projects.name AS ikmc_project_id,
        es_cells.targeting_vector_name AS vector_name,
        es_cells.mutation_type AS mutation_type,
        es_cells.cassette AS cassette,
        es_cells.cassette_type AS cassette_type,
        es_cells.backbone AS backbone,
        es_cells.mutation_type AS mutation_type,
        cb_strain.name AS background_colony_strain_name,
        del_strain.name AS deleter_strain_name,
        test_strain.name AS test_strain_name,
        distribution_centres.centre_names AS distribution_centre_names,
        distribution_centres.distribution_networks AS distribution_networks,
        distribution_centres.start_dates AS distribution_start_dates,
        distribution_centres.end_dates AS distribution_end_dates,
        plans.gene_id AS imits_gene_id,
        ARRAY[MI_ATTEMPT_QC_RESULTS] AS qc_data
      FROM (mi_attempts
        JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
        JOIN mi_attempt_status_stamps ON mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id AND mi_attempt_status_stamps.status_id = mi_attempts.status_id
        JOIN plans ON plans.id = mi_attempts.mi_plan_id
        )
        LEFT JOIN strains AS cb_strain ON cb_strain.id = mi_attempts.colony_background_strain_id
        LEFT JOIN deleter_strains AS del_strain ON del_strain.id = mi_attempts.colony_background_strain_id
        LEFT JOIN strains AS test_strain ON test_strain.id = mi_attempts.colony_background_strain_id
        LEFT JOIN es_cells ON es_cells.id = mi_attempts.es_cell_id
        LEFT JOIN distribution_centres On distribution_centres.mi_attempt_id = mi_attempts.id
        LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = es_cells.ikmc_project_foreign_id
      WHERE mi_attempts.report_to_public = true

      UNION ALL

      SELECT 'MouseAlleleModification' AS type,
        mouse_allele_mods.mouse_allele_type AS mouse_allele_mod_allele_type,
        mi_attempts.mouse_allele_type AS mi_attempt_mouse_allele_type,
        es_cells.allele_type AS es_cell_allele_type,
        plans.marker_symbol AS marker_symbol, plans.mgi_accession_id AS mgi_accession_id,
        plans.production_centre_name AS production_centre,
        es_cells.allele_id AS allele_id,
        es_cells.allele_symbol_superscript_template AS allele_symbol_superscript_template,
        es_cells.mgi_allele_symbol_superscript AS allele_symbol_superscript,
        false AS crispr_plan,
        mouse_allele_mods.colony_name AS colony_name,
        mi_attempts.colony_name AS parent_colony_name,
        mouse_allele_mod_statuses.name AS mouse_status,
        mouse_allele_mod_status_stamps.created_at AS mouse_status_date,
        '' AS es_cell_name,
        targ_rep_ikmc_projects.name AS ikmc_project_id,
        '' AS vector_name,
        '' AS mutation_type,
        '' AS cassette,
        '' AS cassette_type,
        '' AS backbone,
        es_cells.mutation_type AS mutation_type,
        cb_strain.name AS background_colony_strain_name,
        del_strain.name AS deleter_strain_name,
        '' AS test_strain_name,
        distribution_centres.centre_names AS distribution_centre_names,
        distribution_centres.distribution_networks AS distribution_networks,
        distribution_centres.start_dates AS distribution_start_dates,
        distribution_centres.end_dates AS distribution_end_dates,
        plans.gene_id AS imits_gene_id,
        ARRAY[PHENOTYPE_ATTEMPT_QC_RESULTS] AS qc_data
      FROM (mouse_allele_mods
        JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
        JOIN mouse_allele_mod_status_stamps ON mouse_allele_mod_status_stamps.mouse_allele_mod_id = mouse_allele_mods.id AND mouse_allele_mod_status_stamps.status_id = mouse_allele_mods.status_id
        JOIN plans ON plans.id = mouse_allele_mods.mi_plan_id
        JOIN mi_attempts ON mi_attempts.id = mouse_allele_mods.mi_attempt_id
        LEFT JOIN es_cells ON mi_attempts.es_cell_id = es_cells.id)
        LEFT JOIN strains AS cb_strain ON cb_strain.id = mouse_allele_mods.colony_background_strain_id
        LEFT JOIN deleter_strains AS del_strain ON del_strain.id = mouse_allele_mods.colony_background_strain_id
        LEFT JOIN distribution_centres ON distribution_centres.phenotype_attempt_id = mouse_allele_mods.phenotype_attempt_id
        LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = es_cells.ikmc_project_foreign_id
      WHERE mouse_allele_mods.report_to_public = true AND mouse_allele_mods.cre_excision = true
    EOF

    mi_attempts_qc_fields = MiAttempt::QC_FIELDS.map{|field| "'Production QC:#{field.to_s.sub('qc_', '').gsub('_', ' ')}:' || mi_attempts.#{field.to_s}_id"}.join(', ')
    sql['MI_ATTEMPT_QC_RESULTS'] = mi_attempts_qc_fields

    phenotype_attempts_qc_fields = PhenotypeAttempt::QC_FIELDS.map{|field| "'Production QC:#{field.to_s.sub('qc_', '').gsub('_', ' ')}:' || mouse_allele_mods.#{field.to_s}_id"}.join(', ')
    sql['PHENOTYPE_ATTEMPT_QC_RESULTS'] = phenotype_attempts_qc_fields

    return sql
  end



  def initialize
    @config = YAML.load_file("#{Rails.root}/script/build_allele2.yml")
    @solr_update = YAML.load_file("#{Rails.root}/config/solr_update.yml")

    @solr_url = @solr_update[Rails.env]['index_proxy']['product']
    puts "#### #{@solr_url}/admin/"
    @solr_user = @config['options']['SOLR_USER']
    @solr_password = @config['options']['SOLR_PASSWORD']
    @dataset_max_size = 80000
    @process_mice = true
    @process_es_cells = false
    @process_targeting_vectors = false
    @process_intermediate_vectors = false
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

    @qc_results = {}

    @look_up_contact = {}
    Centre.all.each{|production_centre| if !production_centre.contact_email.blank? ; @look_up_contact[production_centre.name] = production_centre.contact_email; end }
    QcResult.all.each{|result| @qc_results[result.id] = result.description}
  end

  def build_json data
    list = []
    data.each do |row|
      item = {'add' => {'doc' => row }}
      list.push item.to_json
    end
    return list
  end

  def delete_index type
    puts "deleting #{Time.now}"
    proxy = SolrConnect::Proxy.new(@solr_url)
    proxy.update({'delete' => {'query' => "type:#{type}"}}.to_json, @solr_user, @solr_password)
    proxy.update({'commit' => {}}.to_json, @solr_user, @solr_password)
    puts "deleting complete #{Time.now}"
    nil
  end

  def send_to_index data
    puts "sending data #{Time.now}"
    proxy = SolrConnect::Proxy.new(@solr_url)
    proxy.update(data.join, @solr_user, @solr_password)
    proxy.update({'commit' => {}}.to_json, @solr_user, @solr_password)
    puts "Commit Completed #{Time.now}"
    nil
  end


  def sent_to_index_in_batches datasets
    datasets.each do |data|
      puts "convert data into json format #{Time.now}"
      data = build_json(data)
      puts "finished converting data into json format #{Time.now}"
      puts "sending data set to solr #{Time.now}"
      send_to_index(data)
      puts "sending data set to sorl completed  #{Time.now}"
    end
    nil
  end

  def process_product_and_send_to_solr_core (step_no, product_type, product_sql, doc_creation_method_name)

    puts "#### step #{step_no} #{product_type} Products #{Time.now}"
    puts "#### step #{step_no}.1 Select #{Time.now}"
puts product_sql
    rows = ActiveRecord::Base.connection.execute(product_sql)
    product_count = rows.count

    puts "count #{product_count}"
    puts "#### step #{step_no}.2 create json docs #{Time.now}"


    doc_sets = [[]]
    doc_set = doc_sets[-1]
    row_no = 0
    rows.each do |row|
      row_no +=1
      if row_no > @dataset_max_size
        doc_sets << []
        doc_set = doc_sets[-1]
        row_no = 0
      end
      doc_set << self.method(doc_creation_method_name).call(row)
    end

    puts "#### step #{step_no}.3 Delete all #{product_type} Products #{Time.now}"

    delete_index (product_type)

    puts "#### step #{step_no}.4 Send all #{product_type} Products to solr index #{Time.now}"

    sent_to_index_in_batches(doc_sets)

    puts "step #{step_no} done #{Time.now}"
  end

  def run
    step_no = 1
    puts "#### Starting #{Time.now}"


    if @process_mice == true
      process_product_and_send_to_solr_core(step_no, 'mouse', self.class.mice_lines_sql, 'create_mouse_doc')
      step_no += 1
    end

    if @process_es_cells == true
      process_product_and_send_to_solr_core(step_no, 'es_cell', self.class.es_cell_sql, 'create_es_cell_doc')
      step_no += 1
    end

    if @process_targeting_vectors == true
      process_product_and_send_to_solr_core(step_no, 'targeting_vector', self.class.targeting_vectors_sql, 'create_targeting_vector_doc')
      step_no += 1
    end

    if @process_intermediate_vectors == true
      process_product_and_send_to_solr_core(step_no, 'intermediate_vector', self.class.intermediate_vectors_sql, 'create_intermediate_vector_doc')
      step_no += 1
    end
  end



  def prepare_allele_symbol row, type
    row['allele_symbol'] = 'None'
    row['allele_symbol'] = 'DUMMY_' + row['targ_rep_alleles_id'] if ! row['targ_rep_alleles_id'].to_s.empty?
    row['allele_symbol'] = 'tm1' + row['allele_type'] if ! row['allele_type'].blank? && row['allele_type'] != 'None'
    row['allele_symbol'] = row['allele_symbol_superscript'] if ! row['allele_symbol_superscript'].to_s.empty?
    row['allele_symbol'] = row['allele_symbol_superscript_template'].to_s.gsub(/\@/, row['allele_type'].to_s) if ! row['allele_type'].nil? && ! row['allele_symbol_superscript_template'].to_s.empty?

  end

  def process_allele_type row, type
    row['allele_type'] = 'None'
    row['allele_type'] = @guess_mapping[ row['mutation_type'] ] if (!row['mutation_type'].blank?) && @guess_mapping.has_key?(row['mutation_type'])
    row['allele_type'] = row['es_cell_allele_type'] if !row['es_cell_allele_type'].nil?
    row['allele_type'] = row['mi_attempt_mouse_allele_type'] if type != 'Allele' && !row['mi_attempt_mouse_allele_type'].blank?
    guess_allele_type(row) if type == 'MouseAlleleModification'

    prepare_allele_symbol(row, type)
  end

  def guess_allele_type row
    if !row['mouse_allele_mod_allele_type'].blank? and !['a', 'e', ''].include?(row['mouse_allele_mod_allele_type'])
      row['allele_type'] =  row['mouse_allele_mod_allele_type']
    else
      # cre version of the mi_attempt allele
      row['allele_type'] =  @guess_mapping[row['allele_type']] if @guess_mapping.has_key?(row['allele_type'])
    end
  end


  def create_mouse_doc row
    process_allele_type(row, row['type'])

    doc = {"marker_symbol"              => row["marker_symbol"],
     "mgi_accession_id"                 => row["mgi_accession_id"],
     "allele_type"                      => row['allele_type'],
     "allele_name"                      => row['allele_symbol'],
     "type"                             => 'mouse',
     "name"                             => row["colony_name"],
     "genetic_info"                     => ["background_colony_strain:#{row['background_colony_strain_name']}", "deleter_strain:#{row['deleter_strain_name']}", "test_strain:#{row['test_strain_name']}"],
     "production_centre"                => row["production_centre"],
     "production_completed"             => ['Genotype confirmed','Cre Excision Complete'].include?(row['mouse_status']) ? true : false,
     "status"                           => row["mouse_status"],
     "status_date"                      => row["mouse_status_date"].to_date.to_s,
     "qc_data"                          => self.class.convert_to_array(row['qc_data']).map{|qc| qc_data = qc.split(':') ; @qc_results.has_key?(qc_data[2].to_i) && @qc_results[qc_data[2].to_i] != 'na' ? "#{qc_data[0]}:#{qc_data[1]}:#{@qc_results[qc_data[2].to_i]}" : nil}.compact,
     "production_info"                  => ["type_of_microinjection:#{row["crispr_plan"] == true ? 'Casp9/Crispr' : 'ES Cell'}"],
     "associated_product_es_cell_name"  => row["es_cell_name"],
     "associated_product_colony_name"   => row["parent_colony_name"],
     "associated_product_vector_name"   => row["vector_name"],
     "order_links"                      => [],
     "order_names"                      => [],
     "contact_links"                    => [@look_up_contact.has_key?(row["production_centre"]) ? "mailto:#{@look_up_contact[row['production_centre']]}?Subject=Mouse Line for #{row['marker_symbol']}" : ''],
     "contact_names"                    => [@look_up_contact.has_key?(row["production_centre"]) ? row["production_centre"] : ''],
     "other_links"                      => ["production_graph:#{production_graph_url(row['imits_gene_id'])}"]
    }

    distribution_centres = self.class.get_distribution_centres(row)

    distribution_centres.each do |dis_centre|
      order_name, order_link = self.class.mice_order_links(dis_centre, row["ikmc_project_id"], row["marker_symbol"])
      if order_name && order_link
        doc["order_names"] << order_name
        doc["order_links"] << order_link
      end
    end
    doc
  end

  def create_es_cell_doc row
    process_allele_type(row, 'Allele')

    doc = {"marker_symbol"              => row['marker_symbol'],
     "mgi_accession_id"                 => row['mgi_accession_id'],
     "allele_type"                      => row['allele_type'],
     "allele_name"                      => row['allele_symbol'],
     "genetic_info"                     => ["strain:#{row['strain']}", "cassette:#{row['cassette']}","cassette_type:#{row['cassette_type']}","parent_es_cell_line:#{row['parental_cell_line']}"],
     "type"                             => 'es_cell',
     "name"                             => row['es_cell_name'],
     "production_pipeline"              => row['pipeline'],
     "production_completed"             => true,
     "status"                           => 'ES Cell Produced',
     "status_date"                      => row['status_date'].to_date.to_s,
     "qc_data"                          => self.class.convert_to_array(row['qc_data']).keep_if{|qc| qc != 'NULL'} + self.class.convert_to_array(row['distribution_qc']).keep_if{|qc| qc != 'NULL'},
     "associated_products_colony_names" => self.class.convert_to_array(row['colonies']),
     "associated_product_vector_name"   => row['vector_name']
    }

    self.class.processes_order_link(doc, self.class.es_cell_and_targeting_vector_order_links(row['mgi_accession_id'], row['marker_symbol'], row['pipeline'], row['ikmc_project_id']))

    doc
  end

  def create_targeting_vector_doc row
    doc = {"marker_symbol"               => row['marker_symbol'],
     "mgi_accession_id"                  => row['mgi_accession_id'],
     "allele_type"                       => '',
     "allele_name"                       => '',
     "genetic_info"                      => ["cassette:#{row['cassette']}","cassette_type:#{row['cassette_type']}", "backbone:#{row['backbone']}"],
     "type"                              => 'targeting_vector',
     "name"                              => row['vector_name'],
     "production_pipeline"               => row['pipeline'],
     "production_completed"              => true,
     "status"                            => 'Targeting Vector Produced',
     "status_date"                       => row['status_date'].to_date.to_s,
     "associated_products_es_cell_names" => row['es_cell_names'],
     "other_links"                       => ["genbank_file:#{self.class.targeting_vector_genbank_file_url(row['allele_id'])}", "allele_image:#{self.class.vector_image_url(row['allele_id'])}", "design_link:#{self.class.design_url(row['design_id'])}"]
    }

    allele_type, allele_name = self.class.process_vector_allele_type(self.class.convert_to_array(row['allele_names']), self.class.convert_to_array(row['allele_types']), row['allele_type'], row['pipeline'], row['cassette'])
    if allele_name
      doc["allele_type"] = allele_type
      doc["allele_name"] = allele_name
    end

    self.class.processes_order_link(doc, self.class.es_cell_and_targeting_vector_order_links(row['mgi_accession_id'], row['marker_symbol'], row['pipeline'], row['ikmc_project_id']))
    doc
  end

  def create_intermediate_vector_doc row
    doc = {"marker_symbol"             => row['marker_symbol'],
     "mgi_accession_id"                => row['mgi_accession_id'],
     "allele_type"                     => '',
     "allele_name"                     => '',
     "type"                            => 'intermediate_vector',
     "production_pipeline"             => row['pipeline'],
     "production_completed"            => true,
     "status"                          => 'Intermediate Vector Produced',
     "status_date"                     => '',
     "associated_product_vector_name"  => row['vector_name'],
     "other_links"                     => ["design_link:#{self.class.design_url(row['design_id'])}"]
    }

    allele_type, allele_name = self.class.process_vector_allele_type(self.class.convert_to_array(row['allele_names']), self.class.convert_to_array(row['allele_types']), row['mutation_type'], row['pipeline'], row['cassette'])
    if allele_name
      doc["allele_type"] = allele_type
      doc["allele_name"] = allele_name
    end

    doc
  end

  def self.targeting_vector_genbank_file_url allele_id
    return "" if allele_id.blank?
    return "https://www.mousephenotype.org/imits/targ_rep/alleles/#{allele_id}/targeting-vector-genbank-file"
  end

  def self.vector_image_url allele_id
    return "" if allele_id.blank?
    return "http://www.i-dcc.org/imits/targ_rep/alleles/#{allele_id}/vector-image"
  end

  def self.design_url design_id
    return "" if design_id.blank?
    return "http://www.sanger.ac.uk/htgt/htgt2/design/designedit/refresh_design?design_id=#{design_id}"
  end

  def production_graph_url gene_id
    return "" if gene_id.blank?
    return "https://www.mousephenotype.org/imits/open/genes/#{gene_id}/network_graph"
  end

  def self.get_distribution_centres row
    return [] if row['distribution_centre_names'].blank?
    centres  = convert_to_array(row['distribution_centre_names'])
    networks = convert_to_array(row['distribution_networks'])
    starts   = convert_to_array(row['distribution_start_dates'])
    ends     = convert_to_array(row['distribution_end_dates'])

    distribution_centres = []
    count = centres.count
    return [] if count == 0
    (0...count).each do |i|
      distribution_centres << {:centre_name          => centres[i],
                               :distribution_network => networks[i],
                               :start_date           => starts[i] == 'NULL' ? nil : starts[i].to_time,
                               :end_date             => ends[i] == 'NULL' ? nil : ends[i].to_time
                               }
    end
    return distribution_centres
  end

  def self.convert_to_array psql_array
    return [] if psql_array.blank?

    psql_array[1, psql_array.length-2].gsub('"', '').split(',')
  end

  def self.process_vector_allele_type (allele_names, allele_types, mutation_type_code, pipeline = '', cassette = '')
    if !allele_names.blank? and allele_types[0] != 'NULL' and allele_names[0] != 'NULL'
      return [allele_types[0], allele_names[0]]
    end

    cre_knock_in_suffix = /(_Cre[0-9A-Za-z]+)_/.match(cassette)

    allele_guess_hash = {'crd' => {'type' => 'a', 'allele_name' => "tm1a"},
     'tnc' => {'type' => 'e', 'allele_name' => "tm1e"},
     'del' => {'type' => '', 'allele_name' => "tm1"},
     'cki' => {'type' => 'Cre Knock In', 'allele_name' => "tm1"}
      }

    return [] if mutation_type_code.blank? or !allele_guess_hash.has_key?(mutation_type_code)

    allele_name_guess = [allele_guess_hash[mutation_type_code]['type'], allele_guess_hash[mutation_type_code]['allele_name']]

    return allele_name_guess
  end

  def self.processes_order_link(doc, order_link)
    doc['order_names'] = order_link[:names]
    doc['order_links'] = order_link[:urls]
  end


  def self.mice_order_links(distribution_centre, project_id, marker_symbol, config = nil)
    config ||= YAML.load_file("#{Rails.root}/config/dist_centre_urls.yml")

    raise "Expecting to find KOMP in distribution centre config" if ! config.has_key? 'KOMP'
    raise "Expecting to find EMMA in distribution centre config" if ! config.has_key? 'EMMA'

    order_from_name ||= []
    order_from_url ||= []

    centre_name = distribution_centre[:centre_name]
    return [] if ! ['UCD', 'KOMP Repo', 'EMMA'].include?(centre_name) && !(config.has_key?(centre_name) || Centre.where("contact_email IS NOT NULL").map{|c| c.name}.include?(centre_name))
    current_time = Time.now

    if distribution_centre[:start_date]
      start_date = distribution_centre[:start_date]
    else
      start_date = current_time
    end

    if distribution_centre[:end_date]
      end_date = distribution_centre[:end_date]
    else
      end_date = current_time
    end

    range = start_date.to_time..end_date.to_time

    return [] if ! range.cover?(current_time)
    centre = Centre.where("contact_email IS NOT NULL AND name = '#{centre_name}'").first
    centre_name = 'KOMP' if ['UCD', 'KOMP Repo'].include?(centre_name)
    centre_name = distribution_centre[:distribution_network] if distribution_centre[:distribution_network]
    details = ''

    if config.has_key?(centre_name) && (!config[centre_name][:default].blank? || !config[centre_name][:preferred].blank?)
      # if blank then will default to order_from_url = details[:default]
      details = config[centre_name]
      order_from_url = details[:default]

      if !config[centre_name][:preferred].blank?
        project_id = project_id
        marker_symbol = marker_symbol
        order_from_name = centre_name

        # order of regex expression doesn't matter: http://stackoverflow.com/questions/5781362/ruby-operator

        if project_id &&  details[:preferred] =~ /PROJECT_ID/
          order_from_url = details[:preferred].gsub(/PROJECT_ID/, project_id)
        end

        if marker_symbol && details[:preferred] =~ /MARKER_SYMBOL/
          order_from_url = details[:preferred].gsub(/MARKER_SYMBOL/, marker_symbol)
        end
      end
    elsif centre
      details = centre
      order_from_url = "mailto:#{details.contact_email}?subject=Mutant mouse enquiry"
      order_from_name = centre_name
    end

    return [] if details.blank?

    if order_from_url
      return [order_from_name, order_from_url]
    else
      return []
    end
  end

  def self.es_cell_and_targeting_vector_order_links(mgi_accession_id, marker_symbol, pipeline, ikmc_project_id)

    return {:urls => [], :names => []} if pipeline.blank?

    if ['EUCOMM', 'EUCOMMTools', 'EUCOMMToolsCre'].include?(pipeline)
      return {:urls => ["http://www.eummcr.org/order?add=#{mgi_accession_id}&material=es_cells"], :names => ['EUMMCR']}

    elsif ['KOMP-CSD', 'KOMP-Regeneron'].include?(pipeline)
      if ! ikmc_project_id.blank?
        if ikmc_project_id.match(/^VG/)
          project = ikmc_project_id
        else
          project = 'CSD' + ikmc_project_id
        end
        url = "http://www.komp.org/geneinfo.php?project=#{project}"
      else
        url = "http://www.komp.org/"
      end

      return {:urls => [url], :names => ['KOMP']}

    elsif ['mirKO'].include?(pipeline)
      return {:urls => ["http://www.eummcr.org/order?add=#{mgi_accession_id}&material=es_cells",
                        "http://www.mmrrc.org/catalog/StrainCatalogSearchForm.php?search_query=#{marker_symbol}"],
              :names => ['EUMMCR', 'MMRRC']}

    elsif ['Sanger MGP'].include?(pipeline)
      return {:urls => ["mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for #{marker_symbol}"], :names => ['Wtsi']}

    elsif 'NorCOMM' == pipeline
      return {:urls => ['http://www.phenogenomics.ca/services/cmmr/escell_services.html'], :names => ['NorCOMM']}

    else
      puts "PIPELINE : #{pipeline}"
      raise "Pipeline not recognized"
    end
  end

end

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  BuildProductCore.new.run
end