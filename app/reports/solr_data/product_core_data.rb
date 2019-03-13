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
      JOIN genes ON genes.id = mi_plans.gene_id SUBS_GENE_TEMPLATE
    WHERE mi_plans.report_to_public = true AND consortia.name SUBS_EUCOMMTOOLSCRE
  EOF

# NOTES Remove Gene Trap alleles by only selecting TargetedAlleles
  ES_CELL_SQL= <<-EOF
    SELECT targ_rep_es_cells.*,
      CASE WHEN alleles.allele_type IS NULL AND alleles.allele_symbol_superscript_template IS NOT NULL THEN ''
      ELSE alleles.allele_type END
      AS allele_type,
      targ_rep_targeting_vectors.name AS targeting_vector_name,
      targ_rep_alleles.cassette AS cassette,
      targ_rep_alleles.cassette_type AS cassette_type,
      targ_rep_alleles.backbone AS backbone,
      targ_rep_alleles.has_issue AS has_issue,
      genes.marker_symbol AS marker_symbol,
      genes.mgi_accession_id AS mgi_accession_id,
      targ_rep_ikmc_projects.name AS ikmc_project,
      targ_rep_pipelines.name AS pipeline,
      targ_rep_alleles.project_design_id AS design_id
    FROM targ_rep_es_cells
      JOIN alleles ON alleles.es_cell_id = targ_rep_es_cells.id
      JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
      JOIN genes ON genes.id = targ_rep_alleles.gene_id SUBS_GENE_TEMPLATE
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
        es_cells.parental_cell_line AS parental_cell_line,
        es_cells.cassette AS cassette,
        es_cells.cassette_type AS cassette_type,
        es_cells.backbone AS backbone,
        es_cells.marker_symbol AS marker_symbol,
        es_cells.mgi_accession_id AS mgi_accession_id,
        es_cells.allele_id AS allele_id,
        es_cells.has_issue AS has_issue,
        alleles.allele_symbol_superscript_template AS allele_symbol_superscript_template,
        alleles.mgi_allele_symbol_superscript AS mgi_allele_symbol_superscript,
        alleles.allele_type AS allele_type,
        es_cells.strain AS strain,
        mouse_colonies.list AS colonies,
        es_cells.pipeline AS pipeline,
        es_cells.ikmc_project_id AS ikmc_project,
        es_cells.design_id AS design_id,
        es_cells.created_at AS status_date,
        ARRAY[ES_CELL_QC_RESULTS] AS qc_data,
        distribution_qcs.distribution_qc_data AS distribution_qc
      FROM es_cells
      JOIN alleles ON alleles.es_cell_id = es_cells.id
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
    <<-EOF
      WITH es_cell_names AS (
        SELECT es_cells.targeting_vector_id AS targeting_vector_id, es_cells.mgi_allele_symbol_superscript AS allele_name, es_cells.allele_type AS allele_type,
               es_cells.gene_marker_symbol, es_cells.cassette, es_cells.project_design_id, es_cells.allele_code, es_cells.allele_prefix,
               array_agg(es_cells.name) AS list
        FROM
          (SELECT targ_rep_es_cells.*, alleles.*, genes.marker_symbol AS gene_marker_symbol, targ_rep_alleles.cassette, targ_rep_alleles.project_design_id, 
                  targ_rep_mutation_types.allele_code, targ_rep_mutation_methods.allele_prefix
          FROM targ_rep_es_cells
          JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
          JOIN genes ON genes.id = targ_rep_alleles.gene_id
          JOIN targ_rep_mutation_methods ON targ_rep_mutation_methods.id = targ_rep_alleles.mutation_method_id
          JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
          JOIN alleles ON alleles.es_cell_id = targ_rep_es_cells.id
          ORDER BY targ_rep_es_cells.targeting_vector_id, alleles.mgi_allele_symbol_superscript) AS es_cells
        WHERE es_cells.report_to_public = true AND es_cells.allele_type != 'e'
        GROUP BY es_cells.targeting_vector_id, es_cells.mgi_allele_symbol_superscript, es_cells.allele_type, 
                 es_cells.gene_marker_symbol, es_cells.cassette, es_cells.project_design_id, es_cells.allele_code, es_cells.allele_prefix
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
             CASE WHEN es_cell_names.targeting_vector_id = targ_rep_targeting_vectors.id THEN es_cell_names.list else NULL end AS es_cell_names,
             es_cell_names.allele_name AS mgi_allele_symbol_superscript,
             es_cell_names.allele_type AS allele_type,
             targ_rep_pipelines.name AS pipeline,
             targ_rep_ikmc_projects.name AS ikmc_project,
             targ_rep_targeting_vectors.created_at AS status_date,
             targ_rep_alleles.project_design_id AS design_id
      FROM targ_rep_targeting_vectors
        JOIN targ_rep_alleles ON targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id
        JOIN genes ON genes.id = targ_rep_alleles.gene_id SUBS_GENE_TEMPLATE
        LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id AND targ_rep_mutation_types.name != 'Targeted Non Conditional'
        LEFT JOIN targ_rep_mutation_methods ON targ_rep_mutation_methods.id = targ_rep_alleles.mutation_method_id
        LEFT JOIN es_cell_names ON  es_cell_names.gene_marker_symbol = genes.marker_symbol
                                    AND es_cell_names.cassette = targ_rep_alleles.cassette
                                    AND es_cell_names.project_design_id = targ_rep_alleles.project_design_id
                                    AND es_cell_names.allele_code       = targ_rep_mutation_types.allele_code
                                    AND es_cell_names.allele_prefix     = targ_rep_mutation_methods.allele_prefix
        LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = targ_rep_targeting_vectors.ikmc_project_foreign_id
        LEFT JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
      WHERE targ_rep_targeting_vectors.report_to_public = true AND targ_rep_alleles.type = 'TargRep::TargetedAllele'
            AND targ_rep_alleles.project_design_id IS NOT NULL AND targ_rep_alleles.cassette IS NOT NULL AND targ_rep_pipelines.name SUBS_EUCOMMTOOLSCRE
      ORDER BY targ_rep_targeting_vectors.name
    EOF
  end

  def self.intermediate_vectors_sql
    # Currently disabled as not used.
    # This is incorrect. Need to replicate the logic in the targeting vector section
    <<-EOF
      WITH es_cell_names AS (
        SELECT es_cells.intermediate_vector AS intermediate_vector, array_agg(es_cells.mgi_allele_symbol_superscript) AS allele_names,array_agg(es_cells.allele_type) AS allele_types
        FROM
          (SELECT targ_rep_es_cells.*, alleles.*, targ_rep_targeting_vectors.intermediate_vector AS intermediate_vector
          FROM targ_rep_es_cells
          JOIN alleles ON alleles.es_cell_id = targ_rep_es_cells.id
          JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.id = targ_rep_es_cells.targeting_vector_id
          WHERE targ_rep_targeting_vectors.intermediate_vector IS NOT NULL AND targ_rep_targeting_vectors.intermediate_vector != '' AND
            alleles.mgi_allele_symbol_superscript IS NOT NULL AND alleles.mgi_allele_symbol_superscript != '' AND
            alleles.allele_type IS NOT NULL AND alleles.allele_type != ''
          ORDER BY targ_rep_targeting_vectors.intermediate_vector, alleles.mgi_allele_symbol_superscript) AS es_cells
        GROUP BY es_cells.intermediate_vector
      )

      SELECT distinct_intermediate_vectors.*, es_cell_names.allele_names AS allele_names, es_cell_names.allele_types AS allele_types
      FROM
      (
        SELECT DISTINCT intermediate.design_id AS design_id, intermediate.marker_symbol AS marker_symbol, 
        intermediate.mgi_accession_id AS mgi_accession_id, intermediate.vector_name AS vector_name,
          intermediate.mutation_type_allele_code AS mutation_type_allele_code,
          intermediate.allele_prefix AS allele_prefix,
          'Intermediate Vector' AS vector_type,
          intermediate.cassette AS cassette,
          intermediate.pipeline AS pipeline,
          intermediate.allele_id AS allele_id
        FROM
          (SELECT targ_rep_alleles.project_design_id AS design_id, targ_rep_mutation_methods.allele_prefix AS allele_prefix, targ_rep_targeting_vectors.intermediate_vector AS vector_name, 
                  targ_rep_alleles.cassette AS cassette, targ_rep_pipelines.name AS pipeline, genes.marker_symbol AS marker_symbol, genes.mgi_accession_id AS mgi_accession_id, 
                  targ_rep_mutation_types.allele_code AS mutation_type_allele_code, targ_rep_targeting_vectors.allele_id AS allele_id
            FROM targ_rep_targeting_vectors
              JOIN targ_rep_alleles ON targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id
              JOIN genes ON genes.id = targ_rep_alleles.gene_id SUBS_GENE_TEMPLATE
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
      distribution_centres AS (#{DISTRIBUTION_CENTRES_SQL}),

      colony_summary AS (
        SELECT colonies.id, colonies.mi_attempt_id, colonies.mouse_allele_mod_id, colonies.name, colonies.genotype_confirmed, colonies.report_to_public AS report_colony_to_public, 
               background_strain.name AS background_strain, colonies.is_released_from_genotyping, colonies.genotyping_comment,
               alleles.mgi_allele_symbol_superscript, alleles.allele_symbol_superscript_template, alleles.mgi_allele_accession_id, alleles.allele_type,
               ARRAY[COLONY_QC_RESULTS] AS qc_data                                
        FROM colonies
          LEFT JOIN strains background_strain ON background_strain.id = colonies.background_strain_id
          JOIN alleles ON colonies.id = alleles.colony_id
          JOIN production_centre_qcs ON production_centre_qcs.allele_id = alleles.id 
      )

      SELECT 'M' || mi_attempts.id AS product_id,
        'MiAttempt' AS type,
        plans.marker_symbol AS marker_symbol, plans.mgi_accession_id AS mgi_accession_id,
        plans.production_centre_name AS production_centre,
        es_cells.allele_id AS allele_id,

        colony_summary.allele_symbol_superscript_template AS allele_symbol_superscript_template,
        colony_summary.mgi_allele_symbol_superscript AS mgi_allele_symbol_superscript,
        colony_summary.allele_type AS allele_type,
        colony_summary.genotyping_comment AS genotyping_comment,

        plans.crispr_plan AS crispr_plan,
        mi_attempts.mutagenesis_factor_id AS mutagenesis_factor_id,
        colony_summary.name AS colony_name,
        '' AS parent_colony_name,
        mi_attempt_statuses.name AS mouse_status,
        mi_attempt_status_stamps.created_at AS mouse_status_date,
        es_cells.name AS es_cell_name,
        es_cells.has_issue AS has_issue,
        es_cells.pipeline AS pipeline,
        es_cells.ikmc_project_id AS ikmc_project_id,
        es_cells.design_id AS design_id,
        es_cells.targeting_vector_name AS vector_name,
        es_cells.cassette AS cassette,
        es_cells.cassette_type AS cassette_type,
        es_cells.backbone AS backbone,
        colony_summary.background_strain AS background_colony_strain_name,
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
        colony_summary.qc_data AS qc_data
      FROM (mi_attempts
        LEFT JOIN colony_summary ON colony_summary.mi_attempt_id = mi_attempts.id
        JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id AND mi_attempt_statuses.name = 'Genotype confirmed'
        JOIN mi_attempt_status_stamps ON mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id AND mi_attempt_status_stamps.status_id = mi_attempts.status_id
        JOIN plans ON plans.id = mi_attempts.mi_plan_id
        )
        LEFT JOIN strains AS test_strain ON test_strain.id = mi_attempts.test_cross_strain_id
        LEFT JOIN es_cells ON es_cells.id = mi_attempts.es_cell_id
        LEFT JOIN distribution_centres ON distribution_centres.colony_id = colony_summary.id
      WHERE mi_attempts.report_to_public = true AND mi_attempts.is_active = true AND
           (es_cells.id IS NOT NULL OR (mi_attempts.mutagenesis_factor_id IS NOT NULL AND colony_summary.genotype_confirmed = true AND colony_summary.report_colony_to_public = true))

      UNION ALL

      SELECT 'P' || mouse_allele_mods.id AS product_id,
        'MouseAlleleModification' AS type,
        plans.marker_symbol AS marker_symbol, plans.mgi_accession_id AS mgi_accession_id,
        plans.production_centre_name AS production_centre,
        es_cells.allele_id AS allele_id,
        
        colony_summary.allele_symbol_superscript_template AS allele_symbol_superscript_template,
        colony_summary.mgi_allele_symbol_superscript AS mgi_allele_symbol_superscript,
        colony_summary.allele_type AS allele_type,
        colony_summary.genotyping_comment AS genotyping_comment,

        false AS crispr_plan,
        NULL AS mutagenesis_factor_id,
        colony_summary.name AS colony_name,
        mi_colony.name AS parent_colony_name,
        mouse_allele_mod_statuses.name AS mouse_status,
        mouse_allele_mod_status_stamps.created_at AS mouse_status_date,
        '' AS es_cell_name,
        es_cells.has_issue AS has_issue,
        es_cells.pipeline AS pipeline,
        es_cells.ikmc_project_id AS ikmc_project_id,
        es_cells.design_id AS design_id,
        '' AS vector_name,
        '' AS cassette,
        '' AS cassette_type,
        '' AS backbone,
        colony_summary.background_strain AS background_colony_strain_name,
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
        colony_summary.qc_data AS qc_data
      FROM (mouse_allele_mods
        LEFT JOIN colony_summary ON colony_summary.mouse_allele_mod_id = mouse_allele_mods.id
        JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id AND mouse_allele_mod_statuses.name = 'Cre Excision Complete'
        JOIN mouse_allele_mod_status_stamps ON mouse_allele_mod_status_stamps.mouse_allele_mod_id = mouse_allele_mods.id AND mouse_allele_mod_status_stamps.status_id = mouse_allele_mods.status_id
        JOIN plans ON plans.id = mouse_allele_mods.mi_plan_id
        JOIN colony_summary mi_colony ON mi_colony.id = mouse_allele_mods.parent_colony_id
        JOIN mi_attempts ON mi_attempts.id = mi_colony.mi_attempt_id
        LEFT JOIN es_cells ON mi_attempts.es_cell_id = es_cells.id)
        LEFT JOIN deleter_strains AS del_strain ON del_strain.id = mouse_allele_mods.deleter_strain_id
        LEFT JOIN distribution_centres ON distribution_centres.colony_id = colony_summary.id
      WHERE mouse_allele_mods.report_to_public = true AND mouse_allele_mods.is_active = true
    EOF

    colonies_qc_fields = ProductionCentreQc::QC_FIELDS.map{|field, options| "'Production QC:#{options[:name].gsub("'", "''")}:' || production_centre_qcs.#{field.to_s}"}.join(', ')
    sql.gsub!(/COLONY_QC_RESULTS/, colonies_qc_fields)
    return sql
  end

  def initialize (options = {})

    @file_name = options[:file_name] || ''
    @show_eucommtoolscre = options[:show_eucommtoolscre] || false
    @marker_symbols = options.has_key?(:marker_symbols) ? options[:marker_symbols] : nil

    if @show_eucommtoolscre
      @allele_design_project = 'Cre'
    else
      @allele_design_project = 'IMPC'
    end

    @process_mice = options[:process_mice] || true
    @process_es_cells = options[:process_es_cells] || true
    @process_targeting_vectors = options[:process_targeting_vectors] || true
    @process_intermediate_vectors = options[:process_intermediate_vectors] || false

    @look_up_contact = {}
    @docs = []

    Centre.all.each{|production_centre| if !production_centre.contact_email.blank? ; @look_up_contact[production_centre.name] = production_centre.contact_email; end }

    @mice_lines_sql = self.class.mice_lines_sql
    @es_cell_sql = self.class.es_cell_sql
    @targeting_vectors_sql = self.class.targeting_vectors_sql
    @intermediate_vectors_sql = self.class.intermediate_vectors_sql
    [@mice_lines_sql, @es_cell_sql, @targeting_vectors_sql, @intermediate_vectors_sql].each do |product_sql|
      if @show_eucommtoolscre == true
        product_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " = 'EUCOMMToolsCre'")
      else
        product_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " != 'EUCOMMToolsCre'")
      end
  
      if !@marker_symbols.blank?
        marker_symbols = @marker_symbols.to_a.map {|ms| "'#{ms}'" }.join(',')
        product_sql.gsub!(/SUBS_GENE_TEMPLATE/, " AND genes.marker_symbol IN (#{marker_symbols})")
      else
        product_sql.gsub!(/SUBS_GENE_TEMPLATE/, "")
      end
    end
  end

  def mice_lines_sql
    @mice_lines_sql
  end

  def es_cell_sql
    @es_cell_sql
  end

  def targeting_vectors_sql
    @targeting_vectors_sql
  end

  def intermediate_vectors_sql
    @intermediate_vectors_sql
  end

  def products
    return @docs
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
    raise "Invalid Marker Symbol provided" if !@marker_symbols.blank? && @marker_symbols.any?{|ms| Gene.find_by_marker_symbol(ms).blank?}
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


  def process_product(step_no, product_type, product_sql, doc_creation_method_name)

    puts "#### step #{step_no} #{product_type} Products #{Time.now}"
    puts "#### step #{step_no}.1 Select #{Time.now}"

    rows = ActiveRecord::Base.connection.execute(product_sql)
    product_count = rows.count

    puts "count #{product_count}"
    puts "#### step #{step_no}.2 create json docs #{Time.now}"
    rows.each do |row|
      row['targ_rep_alleles_id'] = row['allele_id']

      if !row['mgi_allele_symbol_superscript'].blank? && !row['allele_type'].blank?
        allele_details = {'allele_symbol' => row['mgi_allele_symbol_superscript'], 'allele_type' => row['allele_type']}
      elsif !row['design_id'].blank? && !row['cassette'].blank? && !row['mutation_type_allele_code'].blank? && !row['allele_prefix'].blank?
        allele_details = {'allele_symbol' => "#{row['allele_prefix']}#{row['design_id']}#{}(#{row['cassette']})", 'allele_type' => row['mutation_type_allele_code']}
      elsif !row['allele_id'].blank? && !row['cassette'].blank? && !row['mutation_type_allele_code'].blank? && !row['allele_prefix'].blank?
        allele_details = {'allele_symbol' => "#{row['allele_prefix']}#{row['allele_id']}#{}(#{row['cassette']})", 'allele_type' => row['mutation_type_allele_code']}
      else
        allele_details = {'allele_symbol' => nil, 'allele_type' => nil}
      end

      if allele_details['allele_symbol'].blank? || allele_details['allele_type'].blank?
        puts "    ALLELE SYMBOL MISSING FOR #{product_type}: #{row['marker_symbol']}"
        next
      end

      @docs << self.method(doc_creation_method_name).call(row, allele_details)
    end
  end
  private :process_product

  
  def generate_data

    step_no = 1
    puts "#### Starting #{Time.now}"

    if @process_mice == true
      process_product(step_no, 'mouse', mice_lines_sql, 'create_mouse_doc')
      step_no += 1
    end

    if @process_es_cells == true
      process_product(step_no, 'es_cell', es_cell_sql, 'create_es_cell_doc')
      step_no += 1
    end

    if @process_targeting_vectors == true
      process_product(step_no, 'targeting_vector', targeting_vectors_sql, 'create_targeting_vector_doc')
      step_no += 1
    end

    if @process_intermediate_vectors == true
      process_product(step_no, 'intermediate_vector', intermediate_vectors_sql, 'create_intermediate_vector_doc')
      step_no += 1
    end
  end


  def create_mouse_doc row, allele_details

    doc = Solr::Product.new({
     "allele_design_project"            => @allele_design_project,
     "product_id"                       => row["product_id"],
     "allele_id"                        => row["allele_id"],
     "marker_symbol"                    => row["marker_symbol"],
     "mgi_accession_id"                 => row["mgi_accession_id"],
     "allele_type"                      => allele_details['allele_type'],
     "allele_name"                      => allele_details['allele_symbol'],
     "allele_has_issues"                => row['has_issue'],
     "type"                             => 'mouse',
     "name"                             => row["colony_name"],
     "genetic_info"                     => ["background_colony_strain:#{row['background_colony_strain_name']}", "deleter_strain:#{row['deleter_strain_name']}", "test_strain:#{row['test_strain_name']}"],
     "production_centre"                => row["production_centre"],
     "production_completed"             => ['Genotype confirmed','Cre Excision Complete'].include?(row['mouse_status']) ? true : false,
     "status"                           => row["mouse_status"],
     "status_date"                      => row["mouse_status_date"].to_date.to_s,
     "qc_data"                          => self.class.convert_to_array(row['qc_data']).select{|qc| qc != 'NULL'}.map{|qc| qc_data = qc.split(':') ; qc_data[2] != 'na' ? "#{qc_data[0]}:#{qc_data[1]}:#{qc_data[2]}" : nil }.compact,
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

  def create_es_cell_doc row, allele_details

    doc = Solr::Product.new({
     "allele_design_project"            => @allele_design_project,
     "product_id"                       => 'E' + row["es_cell_id"],
     "allele_id"                        => row["allele_id"],
     "marker_symbol"                    => row['marker_symbol'],
     "mgi_accession_id"                 => row['mgi_accession_id'],
     "allele_type"                      => allele_details['allele_type'],
     "allele_name"                      => allele_details['allele_symbol'],
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

  def create_targeting_vector_doc row, allele_details

    doc = Solr::Product.new({
     "allele_design_project"            => @allele_design_project,
     "product_id"                        => 'T' + row["targeting_vector_id"],
     "allele_id"                         => row["allele_id"],
     "marker_symbol"                     => row['marker_symbol'],
     "mgi_accession_id"                  => row['mgi_accession_id'],
     "allele_type"                       => allele_details['allele_type'],
     "allele_name"                       => allele_details['allele_symbol'],
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

  def create_intermediate_vector_doc row, allele_details

    doc = Solr::Product.new({
     "allele_design_project"            => @allele_design_project,
     "product_id"                      => 'I' + row["vector_name"],
     "allele_id"                       => row["allele_id"],
     "marker_symbol"                   => row['marker_symbol'],
     "mgi_accession_id"                => row['mgi_accession_id'],
     "allele_type"                     => allele_details['allele_type'],
     "allele_name"                     => allele_details['allele_symbol'],
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
        url = "https://www.mmrrc.org/catalog/StrainCatalogSearchForm.php?SourceCollection=KOMP&search_query=#{marker_symbol}"
      else
        url = "https://www.mmrrc.org/catalog/overview_Major_Collection.php#108"
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

    elsif 'GENCODYS' == pipeline
      return {:urls => ["mailto:info@gencodys.eu?Subject=Mutant ES Cell line for #{marker_symbol}"], :names => ['GENCODYS']}

    else
      puts "PIPELINE : #{pipeline}"
      raise "Pipeline not recognized"
    end
  end


end
