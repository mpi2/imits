#!/usr/bin/env ruby

require 'pp'
require "digest/md5"

class SolrData::ProductCoreData

  include ApplicationModel::DistributionCentre

  PLAN_SQL= <<-EOF
    SELECT mi_plans.id AS id,
       mi_plans.mutagenesis_via_crispr_cas9 AS crispr_plan,
       genes.marker_symbol AS marker_symbol, genes.mgi_accession_id AS mgi_accession_id,
       mi_plans.gene_id AS gene_id,
       centres.name AS production_centre_name,
       mi_plans.ignore_available_mice AS ignore_available_mice
    FROM mi_plans
      JOIN centres ON centres.id = mi_plans.production_centre_id
      JOIN consortia ON consortia.id = mi_plans.consortium_id
      JOIN genes ON genes.id = mi_plans.gene_id
    WHERE mi_plans.report_to_public = true AND consortia.name SUBS_EUCOMMTOOLSCRE
  EOF

# NOTES Remove Gene Trap alleles by only selecting TargetedAlleles
  ES_CELL_SQL= <<-EOF
    SELECT targ_rep_es_cells.*,
      CASE WHEN targ_rep_es_cells.allele_type IS NULL AND targ_rep_es_cells.allele_symbol_superscript_template IS NOT NULL THEN ''
      ELSE targ_rep_es_cells.allele_type END
      AS allele_type_v2,
      targ_rep_targeting_vectors.name AS targeting_vector_name,
      targ_rep_mutation_types.name AS mutation_type,
      targ_rep_mutation_types.allele_code AS mutation_type_allele_code,
      targ_rep_mutation_methods.allele_prefix AS allele_prefix,
      targ_rep_alleles.cassette AS cassette,
      targ_rep_alleles.cassette_type AS cassette_type,
      targ_rep_alleles.backbone AS backbone,
      targ_rep_alleles.has_issue AS has_issue,
      genes.marker_symbol AS marker_symbol,
      genes.mgi_accession_id AS mgi_accession_id,
      targ_rep_ikmc_projects.name AS ikmc_project,
      targ_rep_pipelines.name AS pipeline,
      targ_rep_alleles.project_design_id AS design_id,
      ARRAY['critical:' || targ_rep_alleles.taqman_critical_del_assay_id, 'upstream:' || targ_rep_alleles.taqman_upstream_del_assay_id, 'downstream:' || targ_rep_alleles.taqman_downstream_del_assay_id] AS loa
    FROM targ_rep_es_cells
      JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
      JOIN genes ON genes.id = targ_rep_alleles.gene_id
      LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = targ_rep_es_cells.ikmc_project_foreign_id
      LEFT JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_es_cells.pipeline_id
      LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
      LEFT JOIN targ_rep_mutation_methods ON targ_rep_mutation_methods.id = targ_rep_alleles.mutation_method_id
      LEFT JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.id = targ_rep_es_cells.targeting_vector_id
    WHERE targ_rep_alleles.type = 'TargRep::TargetedAllele' AND targ_rep_pipelines.name SUBS_EUCOMMTOOLSCRE
  EOF

  DISTRIBUTION_CENTRES_SQL= <<-EOF
    SELECT colony_distribution_centres.colony_id, array_agg(centres.name) AS centre_names, array_agg(colony_distribution_centres.distribution_network) AS distribution_networks,
           array_agg(colony_distribution_centres.start_date) AS start_dates, array_agg(colony_distribution_centres.end_date) AS end_dates, array_agg(colony_distribution_centres.reconciled) AS reconciled, array_agg(colony_distribution_centres.available) AS available
    FROM colony_distribution_centres
      LEFT JOIN centres ON centres.id = colony_distribution_centres.centre_id
    GROUP BY colony_distribution_centres.colony_id
  EOF

  def self.es_cell_sql
    sql = <<-EOF
      WITH es_cells AS (#{ES_CELL_SQL}),
      mouse_colonies AS (
        SELECT mi_attempts.es_cell_id AS es_cell_id, array_agg(colonies.name) AS list
        FROM mi_attempts
        JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id AND colonies.genotype_confirmed = true
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

      SELECT es_cells.id AS es_cell_id,
        es_cells.name AS es_cell_name,
        es_cells.targeting_vector_name AS vector_name,
        es_cells.allele_prefix AS allele_prefix,
        es_cells.mutation_type AS mutation_type,
        es_cells.mutation_type_allele_code AS mutation_type_allele_code,
        es_cells.parental_cell_line AS parental_cell_line,
        es_cells.cassette AS cassette,
        es_cells.cassette_type AS cassette_type,
        es_cells.backbone AS backbone,
        es_cells.marker_symbol AS marker_symbol,
        es_cells.mgi_accession_id AS mgi_accession_id,
        es_cells.allele_id AS allele_id,
        es_cells.has_issue AS has_issue,
        es_cells.allele_symbol_superscript_template AS allele_symbol_superscript_template,
        es_cells.mgi_allele_symbol_superscript AS allele_symbol_superscript,
        es_cells.allele_type_v2 AS es_cell_allele_type,
        es_cells.strain AS strain,
        mouse_colonies.list AS colonies,
        es_cells.pipeline AS pipeline,
        es_cells.ikmc_project_id AS ikmc_project,
        es_cells.design_id AS design_id,
        es_cells.loa AS loa,
        es_cells.created_at AS status_date,
        ARRAY[ES_CELL_QC_RESULTS] AS qc_data,
        distribution_qcs.distribution_qc_data AS distribution_qc
      FROM es_cells
      LEFT JOIN mouse_colonies ON mouse_colonies.es_cell_id = es_cells.id
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
    #es_cell_names finds all es_cells created from the targeting vector and orders them by the allele_type (tm1, tm1a then tm1e).This will allow your to determine the targeting vector allele_type by selecting the first allele_type off the list
    <<-EOF
      WITH es_cell_names AS (
        SELECT es_cells.targeting_vector_id AS targeting_vector_id, array_agg(es_cells.mgi_allele_symbol_superscript) AS allele_names,array_agg(es_cells.allele_type) AS allele_types, array_agg(es_cells.name) AS list
        FROM
          (SELECT targ_rep_es_cells.*
          FROM targ_rep_es_cells
          ORDER BY targ_rep_es_cells.targeting_vector_id, targ_rep_es_cells.mgi_allele_symbol_superscript) AS es_cells
        WHERE es_cells.report_to_public = true
        GROUP BY es_cells.targeting_vector_id
      )

      SELECT targ_rep_targeting_vectors.id AS targeting_vector_id,
             targ_rep_alleles.id AS allele_id,
             genes.marker_symbol AS marker_symbol,
             genes.mgi_accession_id AS mgi_accession_id,
             targ_rep_mutation_types.allele_code AS mutation_type_allele_code,
             targ_rep_alleles.has_issue AS has_issue,
             targ_rep_alleles.cassette AS cassette,
             targ_rep_alleles.cassette_type AS cassette_type,
             targ_rep_alleles.backbone AS backbone,
             targ_rep_alleles.project_design_id AS design_id,
             targ_rep_targeting_vectors.name AS vector_name,
             'Targeting Vector' AS vector_type,
             targ_rep_mutation_methods.allele_prefix AS allele_prefix,
             es_cell_names.list AS es_cell_names,
             es_cell_names.allele_names AS allele_names,
             es_cell_names.allele_types AS allele_types,
             targ_rep_pipelines.name AS pipeline,
             targ_rep_ikmc_projects.name AS ikmc_project,
             targ_rep_targeting_vectors.created_at AS status_date,
             targ_rep_alleles.project_design_id AS design_id,
             ARRAY['critical:' || targ_rep_alleles.taqman_critical_del_assay_id, 'upstream:' || targ_rep_alleles.taqman_upstream_del_assay_id, 'downstream:' || targ_rep_alleles.taqman_downstream_del_assay_id] AS loa
      FROM targ_rep_targeting_vectors
        JOIN targ_rep_alleles ON targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id
        JOIN genes ON genes.id = targ_rep_alleles.gene_id
        LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
        LEFT JOIN targ_rep_mutation_methods ON targ_rep_mutation_methods.id = targ_rep_alleles.mutation_method_id
        LEFT JOIN es_cell_names ON es_cell_names.targeting_vector_id = targ_rep_targeting_vectors.id
        LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = targ_rep_targeting_vectors.ikmc_project_foreign_id
        LEFT JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
      WHERE targ_rep_targeting_vectors.report_to_public = true AND targ_rep_alleles.type = 'TargRep::TargetedAllele'
            AND targ_rep_alleles.project_design_id IS NOT NULL AND targ_rep_alleles.cassette IS NOT NULL AND targ_rep_pipelines.name SUBS_EUCOMMTOOLSCRE
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
          intermediate.mutation_type_allele_code AS mutation_type_allele_code,
          intermediate.allele_prefix AS allele_prefix,
          'Intermediate Vector' AS vector_type,
          intermediate.cassette AS cassette,
          intermediate.pipeline AS pipeline,
          intermediate.allele_id AS allele_id
        FROM
          (SELECT targ_rep_alleles.project_design_id AS design_id, targ_rep_mutation_methods.allele_prefix AS allele_prefix, targ_rep_targeting_vectors.intermediate_vector AS vector_name, targ_rep_alleles.cassette AS cassette, targ_rep_pipelines.name AS pipeline, genes.marker_symbol AS marker_symbol, genes.mgi_accession_id AS mgi_accession_id, targ_rep_mutation_types.allele_code AS mutation_type_allele_code, targ_rep_targeting_vectors.allele_id AS allele_id
            FROM targ_rep_targeting_vectors
              JOIN targ_rep_alleles ON targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id
              JOIN genes ON genes.id = targ_rep_alleles.gene_id
              LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
              LEFT JOIN targ_rep_mutation_methods ON targ_rep_mutation_methods.id = targ_rep_alleles.mutation_method_id
              LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = targ_rep_targeting_vectors.ikmc_project_foreign_id
              LEFT JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
            WHERE targ_rep_targeting_vectors.intermediate_vector IS NOT NULL AND targ_rep_targeting_vectors.intermediate_vector != '' AND targ_rep_alleles.project_design_id IS NOT NULL AND targ_rep_alleles.cassette IS NOT NULL AND targ_rep_pipelines.name SUBS_EUCOMMTOOLSCRE
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

      SELECT 'M' || mi_attempts.id AS product_id,
        'MiAttempt' AS type,
        colonies.allele_type AS colony_allele_type,
        '' AS parent_mouse_allele_type,
        es_cells.allele_type_v2 AS es_cell_allele_type,
        colonies.allele_name AS colony_allele_name,
        mi_attempts.allele_target AS allele_target,
        plans.marker_symbol AS marker_symbol, plans.mgi_accession_id AS mgi_accession_id,
        plans.production_centre_name AS production_centre,
        es_cells.allele_id AS allele_id,
        es_cells.allele_symbol_superscript_template AS es_cell_allele_superscript_template,
        es_cells.mgi_allele_symbol_superscript AS es_allele_symbol_superscript,
        colonies.allele_symbol_superscript_template AS colony_allele_symbol_superscript_template,
        colonies.mgi_allele_symbol_superscript AS colonies_mgi_allele_symbol_superscript,
        plans.crispr_plan AS crispr_plan,
        mi_attempts.mutagenesis_factor_id AS mutagenesis_factor_id,
        colonies.name AS colony_name,
        '' AS parent_colony_name,
        mi_attempt_statuses.name AS mouse_status,
        mi_attempt_status_stamps.created_at AS mouse_status_date,
        es_cells.name AS es_cell_name,
        es_cells.has_issue AS has_issue,
        es_cells.pipeline AS pipeline,
        es_cells.ikmc_project_id AS ikmc_project_id,
        es_cells.design_id AS design_id,
        es_cells.loa AS loa,
        es_cells.targeting_vector_name AS vector_name,
        es_cells.mutation_type AS mutation_type,
        es_cells.cassette AS cassette,
        es_cells.cassette_type AS cassette_type,
        es_cells.backbone AS backbone,
        es_cells.mutation_type AS mutation_type,
        cb_strain.name AS background_colony_strain_name,
        NULL AS deleter_strain_name,
        test_strain.name AS test_strain_name,
        distribution_centres.centre_names AS distribution_centre_names,
        distribution_centres.distribution_networks AS distribution_networks,
        distribution_centres.start_dates AS distribution_start_dates,
        distribution_centres.end_dates AS distribution_end_dates,
        distribution_centres.reconciled AS distribution_reconciled,
        distribution_centres.available AS distribution_available,
        plans.gene_id AS imits_gene_id,
        false AS excised,
        ARRAY[COLONY_QC_RESULTS] AS qc_data
      FROM (mi_attempts
        LEFT JOIN (colonies JOIN colony_qcs ON colonies.id = colony_qcs.colony_id) ON colonies.mi_attempt_id = mi_attempts.id
        JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
        JOIN mi_attempt_status_stamps ON mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id AND mi_attempt_status_stamps.status_id = mi_attempts.status_id
        JOIN plans ON plans.id = mi_attempts.mi_plan_id
        )
        LEFT JOIN strains AS cb_strain ON cb_strain.id = colonies.background_strain_id
        LEFT JOIN strains AS test_strain ON test_strain.id = mi_attempts.test_cross_strain_id
        LEFT JOIN es_cells ON es_cells.id = mi_attempts.es_cell_id
        LEFT JOIN distribution_centres ON distribution_centres.colony_id = colonies.id
      WHERE mi_attempts.report_to_public = true AND mi_attempts.is_active = true AND (es_cells.id IS NOT NULL OR (mi_attempts.mutagenesis_factor_id IS NOT NULL AND colonies.genotype_confirmed = true AND colonies.report_to_public = true))

      UNION ALL

      SELECT 'P' || mouse_allele_mods.id AS product_id,
        'MouseAlleleModification' AS type,
        colonies.allele_type AS colony_allele_type,
        mi_colony.allele_type AS parent_mouse_allele_type,
        es_cells.allele_type_v2 AS es_cell_allele_type,
        colonies.allele_name AS colony_allele_name,
        '' AS allele_target,
        plans.marker_symbol AS marker_symbol, plans.mgi_accession_id AS mgi_accession_id,
        plans.production_centre_name AS production_centre,
        es_cells.allele_id AS allele_id,
        es_cells.allele_symbol_superscript_template AS es_cell_allele_superscript_template,
        es_cells.mgi_allele_symbol_superscript AS es_allele_symbol_superscript,
        colonies.allele_symbol_superscript_template AS colony_allele_symbol_superscript_template,
        colonies.mgi_allele_symbol_superscript AS colonies_mgi_allele_symbol_superscript,
        false AS crispr_plan,
        NULL AS mutagenesis_factor_id,
        colonies.name AS colony_name,
        mi_colony.name AS parent_colony_name,
        mouse_allele_mod_statuses.name AS mouse_status,
        mouse_allele_mod_status_stamps.created_at AS mouse_status_date,
        '' AS es_cell_name,
        es_cells.has_issue AS has_issue,
        es_cells.pipeline AS pipeline,
        es_cells.ikmc_project_id AS ikmc_project_id,
        es_cells.design_id AS design_id,
        ARRAY[NULL] AS loa,
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
        distribution_centres.reconciled AS distribution_reconciled,
        distribution_centres.available AS distribution_available,
        plans.gene_id AS imits_gene_id,
        true AS excised,
        ARRAY[COLONY_QC_RESULTS] AS qc_data
      FROM (mouse_allele_mods
        LEFT JOIN (colonies JOIN colony_qcs ON colonies.id = colony_qcs.colony_id) ON colonies.mouse_allele_mod_id = mouse_allele_mods.id
        JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
        JOIN mouse_allele_mod_status_stamps ON mouse_allele_mod_status_stamps.mouse_allele_mod_id = mouse_allele_mods.id AND mouse_allele_mod_status_stamps.status_id = mouse_allele_mods.status_id
        JOIN plans ON plans.id = mouse_allele_mods.mi_plan_id
        JOIN colonies mi_colony ON mi_colony.id = mouse_allele_mods.parent_colony_id
        JOIN mi_attempts ON mi_attempts.id = mi_colony.mi_attempt_id
        LEFT JOIN es_cells ON mi_attempts.es_cell_id = es_cells.id)
        LEFT JOIN strains AS cb_strain ON cb_strain.id = colonies.background_strain_id
        LEFT JOIN deleter_strains AS del_strain ON del_strain.id = mouse_allele_mods.deleter_strain_id
        LEFT JOIN distribution_centres ON distribution_centres.colony_id = colonies.id
      WHERE mouse_allele_mods.report_to_public = true AND mouse_allele_mods.is_active = true
    EOF

    colonies_qc_fields = ColonyQc::QC_FIELDS.map{|field| "'Production QC:#{field.to_s.sub('qc_', '').gsub('_', ' ')}:' || colony_qcs.#{field.to_s}"}.join(', ')
    sql.gsub!(/COLONY_QC_RESULTS/, colonies_qc_fields)
    return sql
  end

  def initialize (options = {})

    @file_name = options[:file_name] || ''
    @show_eucommtoolscre = options[:show_eucommtoolscre] || false
    @marker_symbols = options.has_key?(:marker_symbols) ? options[:marker_symbols].split(',') : nil

    if @show_eucommtoolscre
      @allele_design_project = 'Cre'
    else
      @allele_design_project = 'IMPC'
    end

    @process_mice = options[:process_mice] || true
    @process_es_cells = options[:process_es_cells] || true
    @process_targeting_vectors = options[:process_targeting_vectors] || true
    @process_intermediate_vectors = options[:process_intermediate_vectors] || true

    @look_up_contact = {}
    @qc_results = {}
    @docs = []

    Centre.all.each{|production_centre| if !production_centre.contact_email.blank? ; @look_up_contact[production_centre.name] = production_centre.contact_email; end }
    QcResult.all.each{|result| @qc_results[result.id] = result.description}
  end

  def run
    check_params
    generate_data
    save_to_file
  end

  def check_params
    puts "------------------"
    puts "PRODUCT SOLR REPORT run with:"
    puts "FILE NAME #{ @file_name.blank? ? "not set" : "set to #{@file_name}" }"
    puts "EUCOMMTOOLSCRE Filter set to #{@show_eucommtoolscre}"
    puts "MARKER SYMBOL Filter #{ @marker_symbols.blank? ? "not set" : "set to #{@marker_symbols.try(:to_sentence)}" }"
    puts "PROCESS MICE Filter set to #{@process_mice}"
    puts "PROCESS ES CELLS Filter set to #{@process_es_cells}"
    puts "PROCESS TARGETING VECTOR Filter set to #{@process_targeting_vectors}"
    puts "PROCESS INTERMEDIATE VECTOR Filter set to #{@process_intermediate_vectors}"
    puts "------------------"

    raise "file_name Parameter required" if @file_name.blank?
    raise "Invalid Parameter show_eucommtoolscre must be a boolean"  unless [TrueClass, FalseClass].include?(@show_eucommtoolscre.class)
    raise "Invalid Marker Symbol provided" if !@marker_symbols.blank? && @marker_symbols.any{|ms| Gene.find_by_marker_symbol(ms).blank?}
    raise "Invalid Parameter process_mice must be a boolean" unless [TrueClass, FalseClass].include?(@process_mice.class)
    raise "Invalid Parameter process_es_cells must be a boolean" unless [TrueClass, FalseClass].include?(@process_es_cells.class)
    raise "Invalid Parameter process_targeting_vectors must be a boolean" unless [TrueClass, FalseClass].include?(@process_targeting_vectors.class)
    raise "Invalid Parameter process_intermediate_vectors must be a boolean" unless [TrueClass, FalseClass].include?(@process_intermediate_vectors.class)

  end

  def save_to_file
    raise if @file_name.blank?

    file_exists = File.file?(@file_name)
    file = open(@file_name, 'a')

    file.write(Solr::Product.tsv_header) unless file_exists
#puts Solr::Product.tsv_header
    @docs.each do |doc|
      file.write(doc.doc_to_tsv)
#puts doc.doc_to_tsv
    end
  end
  private :save_to_file

  def process_product(step_no, product_type, product_sql, doc_creation_method_name)

    puts "#### step #{step_no} #{product_type} Products #{Time.now}"
    puts "#### step #{step_no}.1 Select #{Time.now}"

    # modify sql to either remove or select EUCOMMToolsCre
    if @show_eucommtoolscre == true
      product_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " = 'EUCOMMToolsCre'")
    else
      product_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " != 'EUCOMMToolsCre'")
    end

    rows = ActiveRecord::Base.connection.execute(product_sql)
    product_count = rows.count

    puts "count #{product_count}"
    puts "#### step #{step_no}.2 create json docs #{Time.now}"
    rows.each do |row|
      row['targ_rep_alleles_id'] = row['allele_id']
      @docs << self.method(doc_creation_method_name).call(row)
    end
  end
  private :process_product


  def generate_data

    step_no = 1
    puts "#### Starting #{Time.now}"

    if @process_mice == true
      process_product(step_no, 'mouse', self.class.mice_lines_sql, 'create_mouse_doc')
      step_no += 1
    end

    if @process_es_cells == true
      process_product(step_no, 'es_cell', self.class.es_cell_sql, 'create_es_cell_doc')
      step_no += 1
    end

    if @process_targeting_vectors == true
      process_product(step_no, 'targeting_vector', self.class.targeting_vectors_sql, 'create_targeting_vector_doc')
      step_no += 1
    end

    if @process_intermediate_vectors == true
      process_product(step_no, 'intermediate_vector', self.class.intermediate_vectors_sql, 'create_intermediate_vector_doc')
      step_no += 1
    end
  end
  private :generate_data

  def create_mouse_doc row
    allele_template = nil
    allele_template = row['es_cell_allele_superscript_template'] unless row['es_cell_allele_superscript_template'].blank? #
    allele_template = row['mi_colony_allele_symbol_superscript_template'] unless row['mi_colony_allele_symbol_superscript_template'].blank?
    allele_template = row['colony_allele_symbol_superscript_template'] unless row['colony_allele_symbol_superscript_template'].blank?

    allele_info = TargRep::RealAllele.calculate_allele_information( {'es_cell_allele_type' => row['es_cell_allele_type'] || nil,
                                                                'parent_colony_allele_type' => row['parent_mouse_allele_type'] || nil,
                                                                'colony_allele_type' => row['colony_allele_type'] || nil,
                                                                'allele_id' => row['allele_id'] || nil, #
                                                                'mi_allele_target'   => row['allele_target'] || nil,
                                                                'allele_name' => row['colony_allele_name'] || nil,
                                                                'excised' => row['excised'] == 't' ? true : false, #
                                                                'allele_symbol_superscript_template' => allele_template || nil, #
                                                                'mgi_allele_symbol_superscript' => row['colonies_mgi_allele_symbol_superscript'] || nil
                                                              })

    doc = Solr::Product.new({
     "allele_design_project"            => @allele_design_project,
     "product_id"                       => row["product_id"],
     "allele_id"                        => row["allele_id"],
     "marker_symbol"                    => row["marker_symbol"],
     "mgi_accession_id"                 => row["mgi_accession_id"],
     "allele_type"                      => allele_info['allele_type'],
     "allele_name"                      => allele_info['allele_symbol'],
     "allele_has_issues"                => row['has_issue'],
     "type"                             => 'mouse',
     "name"                             => row["colony_name"],
     "genetic_info"                     => ["background_colony_strain:#{row['background_colony_strain_name']}", "deleter_strain:#{row['deleter_strain_name']}", "test_strain:#{row['test_strain_name']}"],
     "production_centre"                => row["production_centre"],
     "production_completed"             => ['Genotype confirmed','Cre Excision Complete'].include?(row['mouse_status']) ? true : false,
     "status"                           => row["mouse_status"],
     "status_date"                      => row["mouse_status_date"].to_date.to_s,
     "qc_data"                          => self.class.convert_to_array(row['qc_data']).map{|qc| qc_data = qc.split(':') ; if !@qc_results.has_key?(qc_data[2].to_i) && qc_data[2] != 'na'; "#{qc_data[0]}:#{qc_data[1]}:#{qc_data[2]}" ; else @qc_results.has_key?(qc_data[2].to_i) && @qc_results[qc_data[2].to_i] != 'na' ? "#{qc_data[0]}:#{qc_data[1]}:#{@qc_results[qc_data[2].to_i]}" : nil ; end}.compact,
     "production_info"                  => ["type_of_microinjection:#{row["crispr_plan"] == 't' ? 'Cas9/Crispr' : 'ES Cell'}"],
     "associated_product_es_cell_name"  => row["es_cell_name"],
     "associated_product_colony_name"   => row["parent_colony_name"],
     "associated_product_vector_name"   => row["vector_name"],
     "order_links"                      => [],
     "order_names"                      => [],
     "contact_links"                    => [@look_up_contact.has_key?(row["production_centre"]) ? "mailto:#{@look_up_contact[row['production_centre']]}?Subject=Mouse Line for #{row['marker_symbol']}" : ''],
     "contact_names"                    => [@look_up_contact.has_key?(row["production_centre"]) ? row["production_centre"] : ''],
     "ikmc_project_id"                  => row["ikmc_project_id"],
     "design_id"                        => row["design_id"],
     "cassette"                         => row["cassette"]
    })


    if doc.production_completed == true

      distribution_centres = self.class.get_distribution_centres(row)

      distribution_centres.each do |dis_centre|
        order_name, order_link = self.class.mice_order_links(dis_centre)
        if order_name && order_link
          doc.order_names << order_name
          doc.order_links << order_link
        end
      end
    end

    doc
  end
  private :create_mouse_doc

  def create_es_cell_doc row
    allele_info = TargRep::RealAllele.calculate_allele_information( {'mutation_method_allele_prefix' => row['allele_prefix'] || nil,
                                                                'mutation_type_allele_code' => row['mutation_type_allele_code'] || nil,
                                                                'es_cell_allele_type' => row['es_cell_allele_type'] || nil,
                                                                'allele_id' => row['allele_id'] || nil,
                                                                'design_id' => row['design_id'] || nil,
                                                                'cassette' => row['cassette'] || nil,
                                                                'allele_symbol_superscript_template' => row['allele_symbol_superscript_template'] || nil,
                                                                'mgi_allele_symbol_superscript' => row['allele_symbol_superscript'] || nil
                                                              })

    doc = Solr::Product.new({
     "allele_design_project"            => @allele_design_project,
     "product_id"                       => 'E' + row["es_cell_id"],
     "allele_id"                        => row["allele_id"],
     "marker_symbol"                    => row['marker_symbol'],
     "mgi_accession_id"                 => row['mgi_accession_id'],
     "allele_type"                      => allele_info['allele_type'],
     "allele_name"                      => allele_info['allele_symbol'],
     "allele_has_issues"                => row['has_issue'],
     "genetic_info"                     => ["strain:#{row['strain']}", "cassette:#{row['cassette']}","cassette_type:#{row['cassette_type']}","parent_es_cell_line:#{row['parental_cell_line']}"],
     "type"                             => 'es_cell',
     "name"                             => row['es_cell_name'],
     "production_pipeline"              => row['pipeline'],
     "production_completed"             => true,
     "status"                           => 'ES Cell Produced',
     "status_date"                      => row['status_date'].to_date.to_s,
     "qc_data"                          => self.class.convert_to_array(row['qc_data']).keep_if{|qc| qc != 'NULL'} + self.class.convert_to_array(row['distribution_qc']).keep_if{|qc| qc != 'NULL'},
     "associated_products_colony_names" => self.class.convert_to_array(row['colonies']),
     "associated_product_vector_name"   => row['vector_name'],
     "ikmc_project_id"                  => row["ikmc_project"],
     "design_id"                        => row["design_id"],
     "cassette"                         => row["cassette"]
    })

    self.class.processes_order_link(doc, self.class.es_cell_and_targeting_vector_order_links(row['mgi_accession_id'], row['marker_symbol'], row['pipeline'], row['ikmc_project_id']))

    doc
  end
  private :create_es_cell_doc

  def create_targeting_vector_doc row

    allele_info = TargRep::RealAllele.calculate_allele_information( {'mutation_method_allele_prefix' => row['allele_prefix'] || nil,
                                                                'mutation_type_allele_code' => row['mutation_type_allele_code'] || nil,
                                                                'allele_id' => row['allele_id'] || nil,
                                                                'design_id' => row['design_id'] || nil,
                                                                'cassette' => row['cassette'] || nil,
                                                                'mgi_allele_symbol_superscript' => self.class.convert_to_array(row['allele_names'])[0] || nil
                                                              })

    doc = Solr::Product.new({
     "allele_design_project"            => @allele_design_project,
     "product_id"                        => 'T' + row["targeting_vector_id"],
     "allele_id"                         => row["allele_id"],
     "marker_symbol"                     => row['marker_symbol'],
     "mgi_accession_id"                  => row['mgi_accession_id'],
     "allele_type"                       => allele_info['allele_type'],
     "allele_name"                       => allele_info['allele_symbol'],
     "allele_has_issues"                 => row['has_issue'],
     "genetic_info"                      => ["cassette:#{row['cassette']}","cassette_type:#{row['cassette_type']}", "backbone:#{row['backbone']}"],
     "type"                              => 'targeting_vector',
     "name"                              => row['vector_name'],
     "production_pipeline"               => row['pipeline'],
     "production_completed"              => true,
     "status"                            => 'Targeting Vector Produced',
     "status_date"                       => row['status_date'].to_date.to_s,
     "associated_products_es_cell_names" => row['es_cell_names'],
     "other_links"                       => ["genbank_file:#{TargRep::Allele.targeting_vector_genbank_file_url(row['allele_id'])}", "allele_image:#{TargRep::Allele.vector_image_url(row['allele_id'])}", "design_link:#{TargRep::Allele.design_url(row['design_id'])}"],
     "ikmc_project_id"                  => row["ikmc_project"],
     "design_id"                        => row["design_id"],
     "cassette"                         => row["cassette"]
     })

    self.class.processes_order_link(doc, self.class.es_cell_and_targeting_vector_order_links(row['mgi_accession_id'], row['marker_symbol'], row['pipeline'], row['ikmc_project_id']))

    doc
  end
  private :create_targeting_vector_doc

  def create_intermediate_vector_doc row

    allele_info = TargRep::RealAllele.calculate_allele_information( {'mutation_method_allele_prefix' => row['allele_prefix'] || nil,
                                                                'mutation_type_allele_code' => row['mutation_type_allele_code'] || nil,
                                                                'allele_id' => row['allele_id'] || nil,
                                                                'design_id' => row['design_id'] || nil,
                                                                'mgi_allele_symbol_superscript' => self.class.convert_to_array(row['allele_names'])[0] || nil
                                                              })

    doc = Solr::Product.new({
     "allele_design_project"            => @allele_design_project,
     "product_id"                      => 'I' + row["vector_name"],
     "allele_id"                       => row["allele_id"],
     "marker_symbol"                   => row['marker_symbol'],
     "mgi_accession_id"                => row['mgi_accession_id'],
     "allele_type"                     => allele_info['allele_type'],
     "allele_name"                     => allele_info['allele_symbol'],
     "type"                            => 'intermediate_vector',
     "name"                            => row['vector_name'],
     "production_pipeline"             => row['pipeline'],
     "production_completed"            => true,
     "status"                          => 'Intermediate Vector Produced',
     "status_date"                     => '',
     "associated_product_vector_name"  => row['vector_name'],
     "other_links"                     => ["design_link:#{TargRep::Allele.design_url(row['design_id'])}"]
    })

    doc
  end
  private :create_intermediate_vector_doc


  def production_graph_url gene_id
    return "" if gene_id.blank?
    return "https://www.i-dcc.org/imits/open/genes/#{gene_id}/network_graph"
  end
  private :production_graph_url


  def self.get_distribution_centres row
    return [] if row['distribution_centre_names'].blank?

    dist_centres      = convert_to_array(row['distribution_centre_names'])
    networks          = convert_to_array(row['distribution_networks'])
    starts            = convert_to_array(row['distribution_start_dates'])
    ends              = convert_to_array(row['distribution_end_dates'])
    reconcileds       = convert_to_array(row['distribution_reconciled'])
    availables        = convert_to_array(row['distribution_available'])
    prod_centre_name  = row['production_centre']
    ikmc_project_id   = row["ikmc_project_id"]
    marker_symbol     = row["marker_symbol"]

    distribution_centres = []
    count = dist_centres.count
    return [] if count == 0
    (0...count).each do |i|
      distribution_centres << {:distribution_centre_name => dist_centres[i] == 'NULL' ?  nil : dist_centres[i],
                               :distribution_network     => networks[i] == 'NULL' ?  nil : networks[i],
                               :start_date               => starts[i] == 'NULL' ? nil : starts[i].to_time,
                               :end_date                 => ends[i] == 'NULL' ? nil : ends[i].to_time,
                               :reconciled               => reconcileds[i] == 'NULL' ? nil : reconcileds[i],
                               :available                => availables[i] == 'NULL' ? nil : availables[i],
                               :production_centre_name   => prod_centre_name,
                               :ikmc_project_id          => ikmc_project_id,
                               :marker_symbol            => marker_symbol
                                }
    end
    return distribution_centres
  end

  def self.convert_to_array psql_array
    return [] if psql_array.blank?

    psql_array[1, psql_array.length-2].gsub('"', '').split(',')
  end

  def self.processes_order_link(doc, order_link)
    doc.order_names = order_link[:names]
    doc.order_links = order_link[:urls]
  end

  def self.mice_order_links(distribution_centre, config = nil)
    params = {
      :distribution_network_name      => distribution_centre[:distribution_network],
      :distribution_centre_name       => distribution_centre[:distribution_centre_name],
      :production_centre_name         => distribution_centre[:production_centre_name],
      :dc_start_date                  => distribution_centre[:start_date],
      :dc_end_date                    => distribution_centre[:end_date],
      :reconciled                     => distribution_centre[:reconciled],
      :available                      => distribution_centre[:available],
      :ikmc_project_id                => distribution_centre[:ikmc_project_id],
      :marker_symbol                  => distribution_centre[:marker_symbol]
    }

    # create the order link
    begin
      return ApplicationModel::DistributionCentre.calculate_order_link( params, config )
    rescue => e
      puts "Error fetching order link. Exception details:"
      puts e.inspect
      puts e.backtrace.join("\n")
      return []
    end
  end

  def self.es_cell_and_targeting_vector_order_links(mgi_accession_id, marker_symbol, pipeline, ikmc_project_id)

    return {:urls => [], :names => []} if pipeline.blank?

    if ['EUCOMM', 'EUCOMMTools', 'EUCOMMToolsCre'].include?(pipeline)
      return {:urls => ["http://www.eummcr.org/order?add=#{mgi_accession_id}&material=es_cells"], :names => ['EUMMCR']}

    elsif ['KOMP-CSD', 'KOMP-Regeneron'].include?(pipeline)
      if ! marker_symbol.blank?
        url = "https://www.komp.org/geneinfo.php?Symbol=#{marker_symbol}"
      else
        url = "http://www.komp.org/"
      end

      return {:urls => [url], :names => ['KOMP']}

    elsif ['mirKO'].include?(pipeline)
      return {:urls => ["http://www.eummcr.org/order?add=#{mgi_accession_id}&material=es_cells",
                        "http://www.mmrrc.org/catalog/StrainCatalogSearchForm.php?search_query=#{marker_symbol}"],
              :names => ['EUMMCR', 'MMRRC']}

    elsif ['Sanger MGP', 'Sanger_Faculty'].include?(pipeline)
      return {:urls => ["mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for #{marker_symbol}"], :names => ['Wtsi']}

    elsif 'NorCOMM' == pipeline
      return {:urls => ["http://www.cmmr.ca/gene-detail.php?gene=#{mgi_accession_id}"], :names => ['NorCOMM']}

    elsif 'TIGM' == pipeline
      return {:urls => ["mailto:info@tigm.org?Subject=Mutant ES Cell line for #{marker_symbol}"], :names => ['TIGM']}

    elsif 'NARLabs' == pipeline
      return {:urls => ["mailto:geniechin@narlabs.org.tw?Subject=Mutant ES Cell line for #{marker_symbol}"], :names => ['NARLabs']}

    else
      puts "PIPELINE : #{pipeline}"
      raise "Pipeline not recognized"
    end
  end


end
