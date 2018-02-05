#!/usr/bin/env ruby

require 'pp'
require "digest/md5"


class SolrData::Allele2CoreData

  GENE_SQL = <<-EOF
    SELECT genes.* FROM genes WHERE genes.marker_symbol IS NOT NULL SUBS_GENE_TEMPLATE;
  EOF


  MICE_ALLELE_SQL = <<-EOF
    WITH plan_summary AS (
      SELECT mi_plans.id AS mi_plan_id, genes.marker_symbol AS gene_symbol, genes.mgi_accession_id AS gene_mgi_accession_id, centres.name AS production_centre
        FROM mi_plans
          JOIN genes ON genes.id = mi_plans.gene_id SUBS_GENE_TEMPLATE
          JOIN centres ON centres.id = mi_plans.production_centre_id
          JOIN consortia ON consortia.id = mi_plans.consortium_id AND consortia.name SUBS_EUCOMMTOOLSCRE
    ),

      mi_attempt_summary AS (
        SELECT plan_summary.gene_symbol AS gene_symbol, plan_summary.gene_mgi_accession_id AS gene_mgi_accession_id, targ_rep_es_cells.allele_id AS allele_id,
               mi_attempts.id AS mi_attempt_id, mi_attempts.external_ref AS mi_external_ref, mi_attempt_statuses.name AS mi_status_name, mi_attempts.report_to_public AS mi_report_to_public,
               blast_strain.name AS mi_blast_strain_name, test_cross_strain.name AS mi_test_cross_strain_name,
               targ_rep_es_cells.id AS es_cell_id, targ_rep_es_cells.name AS es_cell_name, targ_rep_alleles.cassette AS cassette, alleles.mgi_allele_accession_id AS es_cell_mgi_allele_id, alleles.mgi_allele_symbol_superscript AS es_cell_mgi_allele_symbol_superscript, CASE WHEN alleles.allele_type IS NULL THEN '' ELSE alleles.allele_type END AS es_cell_allele_type, alleles.allele_symbol_superscript_template AS es_cell_allele_superscript_template,
               mutagenesis_factors.id AS mutagenesis_factor_id,
               colonies.id AS mi_colony_id, colonies.name AS mi_colony_name, colony_alleles.mgi_allele_accession_id AS mi_colony_mgi_allele_id,
               colony_alleles.mgi_allele_symbol_superscript AS mi_colony_mgi_allele_symbol_superscript,
               colony_alleles.allele_type AS mi_colony_allele_type, colony_background_strain.name AS mi_colony_background_strain_name,
               plan_summary.production_centre AS mi_production_centre
          FROM mi_attempts
            JOIN plan_summary ON plan_summary.mi_plan_id = mi_attempts.mi_plan_id
            JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
            LEFT JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id
            LEFT JOIN alleles colony_alleles ON colony_alleles.colony_id = colonies.id
            LEFT JOIN strains blast_strain ON blast_strain.id = mi_attempts.blast_strain_id
            LEFT JOIN strains test_cross_strain ON test_cross_strain.id = mi_attempts.test_cross_strain_id
            LEFT JOIN strains colony_background_strain ON colony_background_strain.id = colonies.background_strain_id
            LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
            LEFT JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
            LEFT JOIN alleles ON alleles.es_cell_id = targ_rep_es_cells.id
            LEFT JOIN mutagenesis_factors ON mutagenesis_factors.id = mi_attempts.mutagenesis_factor_id
        WHERE mi_attempt_statuses.name != 'Micro-injection aborted'

    ),

      phenotyping_production_summary AS (
        SELECT parent_colony_id, 
        (array_agg(phenotyping_production_statuses.name ORDER BY phenotyping_production_statuses.order_by DESC))[1] AS phenotyping_status_name,
        (array_agg(plan_summary.production_centre ORDER BY phenotyping_production_statuses.order_by DESC))[1] AS phenotyping_centre, 
        array_agg(plan_summary.production_centre ORDER BY phenotyping_production_statuses.order_by DESC) AS phenotyping_centres
        FROM phenotyping_productions
          JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = phenotyping_productions.status_id
          JOIN plan_summary ON plan_summary.mi_plan_id = phenotyping_productions.mi_plan_id
        WHERE phenotyping_production_statuses.name != 'Phenotype Production Aborted' AND phenotyping_productions.report_to_public = true
        GROUP BY parent_colony_id
      ),

      late_adult_phenotyping_production_summary AS (
        SELECT parent_colony_id, 
        (array_agg(phenotyping_production_late_adult_statuses.name ORDER BY phenotyping_production_late_adult_statuses.order_by DESC))[1] AS phenotyping_status_name,
        (array_agg(plan_summary.production_centre ORDER BY phenotyping_production_late_adult_statuses.order_by DESC))[1] AS phenotyping_centre, 
        array_agg(CASE WHEN phenotyping_productions.selected_for_late_adult_phenotyping = true THEN plan_summary.production_centre ELSE NULL END) AS phenotyping_centres
        FROM phenotyping_productions
          JOIN phenotyping_production_late_adult_statuses ON phenotyping_production_late_adult_statuses.id = phenotyping_productions.late_adult_status_id
          JOIN plan_summary ON plan_summary.mi_plan_id = phenotyping_productions.mi_plan_id
        WHERE phenotyping_production_late_adult_statuses.name != 'Late Adult Phenotype Production Aborted' AND phenotyping_productions.late_adult_report_to_public = true
        GROUP BY parent_colony_id
      ),

      tissue_summary AS (
        SELECT parent_colony_id,
        (array_agg(pptdc.deposited_material)) AS deposited_tissues,
        (array_agg(centres.name)) AS tissue_distribution_centre_names,
        (array_agg(pptdc.start_date)) AS start_dates,
        (array_agg(pptdc.end_date)) AS end_dates
        FROM phenotyping_productions
          JOIN phenotyping_production_tissue_distribution_centres pptdc ON pptdc.phenotyping_production_id = phenotyping_productions.id
          JOIN centres ON centres.id = pptdc.centre_id
        WHERE (start_date IS NULL OR start_date < NOW()) AND (end_date IS NULL OR end_date > NOW()) 
        GROUP BY parent_colony_id
      ),

      colony_summary AS (
        SELECT colonies.id AS id, colonies.name AS colony_name, colonies.mouse_allele_mod_id AS mouse_allele_mod_id, alleles.mgi_allele_accession_id AS mgi_allele_accession_id,
               alleles.mgi_allele_symbol_superscript AS mgi_allele_symbol_superscript,
               alleles.allele_type AS allele_type, alleles.allele_subtype AS allele_subtype, colony_background_strain.name AS background_strain_name,
               phenotyping_production_summary.phenotyping_status_name AS phenotyping_status_name,
               phenotyping_production_summary.phenotyping_centre AS phenotyping_centre,
               phenotyping_production_summary.phenotyping_centres AS phenotyping_centres,
               late_adult_phenotyping_production_summary.phenotyping_status_name AS late_adult_phenotyping_status_name,
               late_adult_phenotyping_production_summary.phenotyping_centre AS late_adult_phenotyping_centre,
               late_adult_phenotyping_production_summary.phenotyping_centres AS late_adult_phenotyping_centres,
               tissue_summary.deposited_tissues AS tissue_deposited_tissues,
               tissue_summary.tissue_distribution_centre_names AS tissue_distribution_centre_names,
               tissue_summary.start_dates AS tissue_start_dates,
               tissue_summary.end_dates AS tissue_end_dates,
               colonies.report_to_public AS report_to_public, colonies.genotype_confirmed AS genotype_confirmed
        FROM colonies
        JOIN alleles ON alleles.colony_id = colonies.id
        LEFT JOIN strains colony_background_strain ON colony_background_strain.id = colonies.background_strain_id
        LEFT JOIN phenotyping_production_summary ON phenotyping_production_summary.parent_colony_id = colonies.id
        LEFT JOIN late_adult_phenotyping_production_summary ON late_adult_phenotyping_production_summary.parent_colony_id = colonies.id
        LEFT JOIN tissue_summary ON tissue_summary.parent_colony_id = colonies.id
      )


    -- Note! the colony data in colonies and mi_attempt_summary is the same when the colony was created via micro_injection.

    SELECT 'MiAttempt' AS colony_created_by,
           colony_summary.colony_name AS colony_name, colony_summary.mgi_allele_accession_id AS colony_mgi_allele_id, colony_summary.mgi_allele_symbol_superscript AS colony_mgi_allele_symbol_superscript,
           colony_summary.allele_type AS colony_allele_type, colony_summary.allele_subtype, colony_summary.background_strain_name AS colony_background_strain_name,
           NULL AS mouse_allele_status_name, NULL AS mouse_allele_mod_deleter_strain, NULL AS mouse_allele_mod_id, NULL AS excised,
           mi_attempt_summary.*,
           NULL AS mouse_allele_production_centre,
           colony_summary.phenotyping_status_name AS phenotyping_status_name, colony_summary.phenotyping_centre AS phenotyping_centre,
           colony_summary.phenotyping_centres AS phenotyping_centres,
           colony_summary.late_adult_phenotyping_status_name AS late_adult_phenotyping_status_name, colony_summary.late_adult_phenotyping_centre AS late_adult_phenotyping_centre,
           colony_summary.late_adult_phenotyping_centres AS late_adult_phenotyping_centres,
           colony_summary.tissue_deposited_tissues,
           colony_summary.tissue_distribution_centre_names,
           colony_summary.tissue_start_dates,
           colony_summary.tissue_end_dates
    FROM mi_attempt_summary
      LEFT JOIN colony_summary ON mi_attempt_summary.mi_colony_id = colony_summary.id
    WHERE ((colony_summary.report_to_public = true AND colony_summary.genotype_confirmed = true) OR (mi_attempt_summary.mutagenesis_factor_id IS NULL)) 
          AND (mi_attempt_summary.mi_report_to_public = true)

    UNION ALL

    SELECT 'MouseAlleleMod' AS colony_created_by,
           colony_summary.colony_name AS colony_name, colony_summary.mgi_allele_accession_id AS colony_mgi_allele_id, colony_summary.mgi_allele_symbol_superscript AS colony_mgi_allele_symbol_superscript,
           colony_summary.allele_type AS colony_allele_type, colony_summary.allele_subtype, colony_summary.background_strain_name AS colony_background_strain_name,
           mouse_allele_mod_statuses.name AS mouse_allele_status_name, deleter_strain.name AS mouse_allele_mod_deleter_strain, mouse_allele_mods.id AS mouse_allele_mod_id, mouse_allele_mods.cre_excision AS excised,
           mi_attempt_summary.*,
           mam_plan_summary.production_centre AS mouse_allele_production_centre,
           colony_summary.phenotyping_status_name AS phenotyping_status_name, colony_summary.phenotyping_centre AS phenotyping_centre,
           colony_summary.phenotyping_centres AS phenotyping_centres,
           colony_summary.late_adult_phenotyping_status_name AS late_adult_phenotyping_status_name, colony_summary.late_adult_phenotyping_centre AS late_adult_phenotyping_centre,
           colony_summary.late_adult_phenotyping_centres AS late_adult_phenotyping_centres,
           colony_summary.tissue_deposited_tissues,
           colony_summary.tissue_distribution_centre_names,
           colony_summary.tissue_start_dates,
           colony_summary.tissue_end_dates
    FROM colony_summary
      JOIN (mouse_allele_mods
                  JOIN plan_summary AS mam_plan_summary ON mam_plan_summary.mi_plan_id = mouse_allele_mods.mi_plan_id
                  LEFT JOIN strains deleter_strain ON deleter_strain.id = mouse_allele_mods.deleter_strain_id
                  JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
                ) ON mouse_allele_mods.id = colony_summary.mouse_allele_mod_id
      JOIN mi_attempt_summary ON mi_attempt_summary.mi_colony_id = mouse_allele_mods.parent_colony_id
    WHERE mouse_allele_mods.report_to_public = true AND mouse_allele_mod_statuses.name = 'Cre Excision Complete'
  EOF


  ES_CELL_VECTOR_ALLELES_SQL = <<-EOF
  WITH allele_details AS (
              SELECT targ_rep_alleles.id AS allele_id, genes.marker_symbol AS gene_symbol, genes.mgi_accession_id AS gene_mgi_accession_id,
                     targ_rep_alleles.project_design_id AS allele_design_id, targ_rep_alleles.cassette AS allele_cassette, targ_rep_alleles.cassette_type AS cassette_type,
                     targ_rep_mutation_methods.allele_prefix AS mutation_method_allele_prefix, targ_rep_mutation_methods.name AS mutation_method_name,
                     targ_rep_mutation_types.allele_code AS mutation_type_allele_code, targ_rep_mutation_types.name AS mutation_type_name
              FROM targ_rep_alleles
                JOIN genes ON genes.id = targ_rep_alleles.gene_id SUBS_GENE_TEMPLATE
                JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
                JOIN targ_rep_mutation_methods ON targ_rep_mutation_methods.id = targ_rep_alleles.mutation_method_id
  ),

  alleles_produced_from_vectors AS (
              SELECT targ_rep_targeting_vectors.id, allele_details.gene_symbol, allele_details.gene_mgi_accession_id, alleles.mgi_allele_symbol_superscript,
                     alleles.allele_type, CASE WHEN allele_details.allele_design_id IS NULL THEN '' ELSE CAST(allele_details.allele_design_id AS text) END AS project_design_id,
                     CASE WHEN allele_details.allele_cassette IS NULL THEN '' ELSE allele_details.allele_cassette END AS cassette, allele_details.cassette_type AS cassette_type, allele_details.mutation_method_allele_prefix AS allele_prefix, allele_details.mutation_type_allele_code AS allele_code,
                     count(CASE WHEN targ_rep_es_cells.report_to_public = false THEN NULL ELSE targ_rep_es_cells.id END) AS num_es_cells, string_agg(alleles.mgi_allele_accession_id, ',') AS es_mgi_allele_ids,
                     string_agg(targ_rep_es_cells.name, ',') AS es_cell_names, string_agg(targ_rep_es_cells.ikmc_project_id, ',') AS es_ikmc_projects_not_distinct,
                     string_agg(es_pipelines.name, ',') AS es_pipelines_not_distinct, string_agg(allele_details.allele_id::text, ',') AS allele_ids
              FROM targ_rep_es_cells
                JOIN alleles ON alleles.es_cell_id = targ_rep_es_cells.id
                LEFT JOIN targ_rep_targeting_vectors ON  targ_rep_targeting_vectors.id = targ_rep_es_cells.targeting_vector_id
                JOIN allele_details ON allele_details.allele_id = targ_rep_es_cells.allele_id
                JOIN targ_rep_pipelines es_pipelines ON es_pipelines.id = targ_rep_es_cells.pipeline_id AND es_pipelines.id SUBS_EUCOMMTOOLSCRE_ID
              WHERE targ_rep_es_cells.report_to_public = true
              GROUP BY targ_rep_targeting_vectors.id, allele_details.gene_symbol, allele_details.gene_mgi_accession_id, alleles.mgi_allele_symbol_superscript,
                       alleles.allele_type, allele_details.allele_design_id, allele_details.allele_cassette, allele_details.cassette_type, allele_details.mutation_method_allele_prefix, allele_details.mutation_type_allele_code
  ),

  targeting_vector_info AS (
        SELECT targ_rep_targeting_vectors.*,
               allele_details.gene_symbol AS marker_symbol,
               allele_details.gene_mgi_accession_id AS mgi_accession_id,
               allele_details.allele_id AS tv_targeting_vector_allele_id,
               CASE WHEN allele_details.allele_cassette IS NULL THEN '' ELSE allele_details.allele_cassette END AS tv_cassette,
               allele_details.cassette_type AS tv_cassette_type,
               CASE WHEN allele_details.allele_design_id IS NULL THEN '' ELSE CAST(allele_details.allele_design_id AS text) END AS tv_project_design_id,
               allele_details.mutation_type_name AS tv_mutation_type,
               allele_details.mutation_type_allele_code AS tv_allele_code,
               allele_details.mutation_method_name AS tv_mutation_method,
               allele_details.mutation_method_allele_prefix AS tv_allele_prefix,
               tv_pipelines.name AS tv_pipelines,
               targ_rep_targeting_vectors.ikmc_project_id AS tv_ikmc_project_id
        FROM targ_rep_targeting_vectors
          JOIN allele_details ON allele_details.allele_id = targ_rep_targeting_vectors.allele_id
          JOIN targ_rep_pipelines tv_pipelines ON tv_pipelines.id = targ_rep_targeting_vectors.pipeline_id AND tv_pipelines.id SUBS_EUCOMMTOOLSCRE_ID
  ),

  allele_summary AS (
        SELECT CASE WHEN alleles_produced_from_vectors.gene_symbol IS NOT NULL THEN alleles_produced_from_vectors.gene_symbol
                    WHEN targeting_vector_info.marker_symbol IS NOT NULL THEN targeting_vector_info.marker_symbol
                    ELSE NULL END AS marker_symbol,
               CASE WHEN alleles_produced_from_vectors.gene_mgi_accession_id IS NOT NULL THEN alleles_produced_from_vectors.gene_mgi_accession_id
                    WHEN targeting_vector_info.mgi_accession_id IS NOT NULL THEN targeting_vector_info.mgi_accession_id
                    ELSE NULL END AS mgi_accession_id,

               alleles_produced_from_vectors.mgi_allele_symbol_superscript,
               alleles_produced_from_vectors.allele_type,

               CASE WHEN alleles_produced_from_vectors.project_design_id IS NOT NULL THEN alleles_produced_from_vectors.project_design_id
                    WHEN targeting_vector_info.tv_project_design_id IS NOT NULL THEN targeting_vector_info.tv_project_design_id
                    ELSE NULL END AS project_design_id,
               CASE WHEN alleles_produced_from_vectors.cassette IS NOT NULL THEN alleles_produced_from_vectors.cassette
                    WHEN targeting_vector_info.tv_cassette IS NOT NULL THEN targeting_vector_info.tv_cassette
                    ELSE NULL END AS cassette,
               CASE WHEN alleles_produced_from_vectors.cassette_type IS NOT NULL THEN alleles_produced_from_vectors.cassette_type
                    WHEN targeting_vector_info.tv_cassette_type IS NOT NULL THEN targeting_vector_info.tv_cassette_type
                    ELSE NULL END AS cassette_type,
               alleles_produced_from_vectors.es_mgi_allele_ids AS es_mgi_allele_ids_not_distinct,
               CASE WHEN alleles_produced_from_vectors.allele_prefix IS NOT NULL THEN alleles_produced_from_vectors.allele_prefix
                    ELSE targeting_vector_info.tv_allele_prefix END AS allele_prefix,
               CASE WHEN alleles_produced_from_vectors.allele_code IS NOT NULL THEN alleles_produced_from_vectors.allele_code
                    ELSE targeting_vector_info.tv_allele_code END AS allele_code,

               alleles_produced_from_vectors.allele_ids AS es_allele_ids,
               alleles_produced_from_vectors.es_cell_names AS es_cell_names,
               alleles_produced_from_vectors.es_pipelines_not_distinct AS es_pipelines,
               alleles_produced_from_vectors.es_ikmc_projects_not_distinct AS es_ikmc_projects,
               alleles_produced_from_vectors.id AS alleles_produced_from_vector_tv,

               targeting_vector_info.tv_pipelines AS tv_pipeline,
               targeting_vector_info.tv_ikmc_project_id AS tv_ikmc_project,
               targeting_vector_info.id AS tv_id,
               targeting_vector_info.tv_targeting_vector_allele_id AS tv_allele_id,

               alleles_produced_from_vectors.num_es_cells AS num_es_cells

          FROM targeting_vector_info
           FULL JOIN alleles_produced_from_vectors
              ON alleles_produced_from_vectors.gene_symbol = targeting_vector_info.marker_symbol
                AND alleles_produced_from_vectors.cassette = targeting_vector_info.tv_cassette
                AND alleles_produced_from_vectors.project_design_id = targeting_vector_info.tv_project_design_id
                AND alleles_produced_from_vectors.allele_code       = targeting_vector_info.tv_allele_code
                AND alleles_produced_from_vectors.allele_prefix     = targeting_vector_info.tv_allele_prefix

        WHERE alleles_produced_from_vectors.gene_symbol IS NOT NULL OR targeting_vector_info.report_to_public = true
    )



    SELECT allele_summary.marker_symbol AS gene_symbol, allele_summary.mgi_accession_id AS gene_mgi_accession_id,
           allele_summary.mgi_allele_symbol_superscript AS mgi_allele_symbol_superscript, allele_summary.allele_type AS allele_type, NULL AS allele_subtype,
           allele_summary.project_design_id AS design_id, allele_summary.cassette, allele_summary.cassette_type, allele_summary.allele_prefix, allele_summary.allele_code AS mutation_type_allele_code,
           string_agg(allele_summary.es_allele_ids, ',') AS es_allele_ids_not_distinct,
           string_agg(allele_summary.es_mgi_allele_ids_not_distinct, ',') AS es_mgi_allele_ids_not_distinct,
           string_agg(allele_summary.tv_allele_id::text, ',') AS tv_allele_ids_not_distinct,
           string_agg(allele_summary.es_cell_names, ',') AS es_cell_names,
           string_agg(allele_summary.es_pipelines, ',') AS es_pipelines_not_distinct,
           string_agg(allele_summary.es_ikmc_projects, ',') AS es_ikmc_projects_not_distinct,
           string_agg(allele_summary.tv_pipeline, ',') AS tv_pipelines_not_distinct,
           string_agg(allele_summary.tv_ikmc_project, ',') AS tv_ikmc_projects_not_distinct,
           SUM (CASE WHEN tv_id = alleles_produced_from_vector_tv THEN allele_summary.num_es_cells ELSE 0 END) AS num_es_cells,
           count(tv_id) AS num_targeting_vectors

      FROM allele_summary

    GROUP BY allele_summary.marker_symbol,
             allele_summary.mgi_accession_id,
             allele_summary.mgi_allele_symbol_superscript,
             allele_summary.allele_type,
             allele_summary.project_design_id,
             allele_summary.cassette,
             allele_summary.cassette_type,
             allele_summary.allele_prefix,
             allele_summary.allele_code
  EOF


  PHENOTYPE_DATA_AVAILABLE_FOR_GENE = <<-EOF
    SELECT genes.marker_symbol AS gene_marker_symbol, genes.mgi_accession_id AS gene_mgi_accession_id, centres.name AS phenotyping_centre,
           phenotyping_productions.*,
           phenotyping_production_statuses.name AS phenotyping_status_name,
           phenotyping_production_late_adult_statuses.name AS late_adult_phenotyping_status_name,
           CASE WHEN phenotyping_productions.selected_for_late_adult_phenotyping = true THEN centres.name ELSE '' END AS late_adult_phenotyping_centre
    FROM phenotyping_productions
      JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = phenotyping_productions.status_id
      LEFT JOIN phenotyping_production_late_adult_statuses ON phenotyping_production_late_adult_statuses.id = phenotyping_productions.status_id AND phenotyping_productions.late_adult_report_to_public = true
      JOIN mi_plans ON mi_plans.id = phenotyping_productions.mi_plan_id
      JOIN centres ON centres.id = mi_plans.production_centre_id
      JOIN consortia ON consortia.id = mi_plans.consortium_id AND consortia.name SUBS_EUCOMMTOOLSCRE
      JOIN genes ON genes.id = mi_plans.gene_id SUBS_GENE_TEMPLATE
    WHERE phenotyping_productions.report_to_public = true
  EOF


  def initialize(options = {})
    @show_eucommtoolscre = options[:show_eucommtoolscre] || false
    @marker_symbols = options.has_key?(:marker_symbols) ? options[:marker_symbols] : nil

    @file_name = options[:file_name] || ''

    if @show_eucommtoolscre
      @allele_design_project = 'Cre'
    else
      @allele_design_project = 'IMPC'
    end

    @mouse_status_list = {}
    PhenotypingProduction::Status.all.each{|status| @mouse_status_list[status['name']] = status['order_by']}
    MouseAlleleMod::Status.all.each{|status| @mouse_status_list[status['name']] = status['order_by']}
    MiAttempt::Status.all.each{|status| @mouse_status_list[status['name']] = status['order_by']}

    @phenotype_status_list = {}
    PhenotypingProduction::LateAdultStatus.all.each{|status| @phenotype_status_list[status['name']] = status['order_by']}

    @translate_to_legacy_status = {'No ES Cell Production'          => 'Not Assigned for ES Cell Production',
                                   'ES Cell Production in Progress' => 'Assigned for ES Cell Production',
                                   'ES Cell Targeting Confirmed'    => 'ES Cells Produced',
                                   'Micro-injection in progress'    => 'Assigned for Mouse Production and Phenotyping',
                                   'Chimeras obtained'              => 'Assigned for Mouse Production and Phenotyping',
                                   'Founder obtained'              => 'Assigned for Mouse Production and Phenotyping',
                                   'Genotype confirmed'             => 'Mice Produced',
                                   'Rederivation Started'           => 'Mice Produced',
                                   'Rederivation Complete'          => 'Mice Produced',
                                   'Cre Excision Started'           => 'Mice Produced',
                                   'Cre Excision Complete'          => 'Mice Produced',
                                   'Phenotype Attempt Registered'   => 'Mice Produced',
                                   'Phenotyping Started'            => 'Mice Produced',
                                   'Phenotyping Complete'           => 'Mice Produced'
                                 }


    puts "#### loading alleles!" if @use_alleles
    puts "#### loading genes!" if @use_genes

    @gene_sql = GENE_SQL.dup
    @mouse_sql = MICE_ALLELE_SQL.dup
    @es_cell_and_targeting_vector_sql = ES_CELL_VECTOR_ALLELES_SQL.dup
    @gene_phenotyping_sql = PHENOTYPE_DATA_AVAILABLE_FOR_GENE.dup

    marker_symbols = @marker_symbols.to_a.map {|ms| "'#{ms}'" }.join ','

    if ! @marker_symbols.nil?
      @gene_sql.gsub!(/SUBS_GENE_TEMPLATE/, " AND genes.marker_symbol IN (#{marker_symbols})")
      @mouse_sql.gsub!(/SUBS_GENE_TEMPLATE/, " AND genes.marker_symbol IN (#{marker_symbols})")
      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_GENE_TEMPLATE/, " AND genes.marker_symbol IN (#{marker_symbols})")
      @gene_phenotyping_sql.gsub!(/SUBS_GENE_TEMPLATE/, " AND genes.marker_symbol IN (#{marker_symbols})")
    else
      @gene_sql.gsub!(/SUBS_GENE_TEMPLATE/, '')
      @mouse_sql.gsub!(/SUBS_GENE_TEMPLATE/, '')
      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_GENE_TEMPLATE/, '')
      @gene_phenotyping_sql.gsub!(/SUBS_GENE_TEMPLATE/, '')
    end

    if @show_eucommtoolscre == true
      @mouse_sql.gsub!(/SUBS_EUCOMMTOOLSCRE_ID/, ' = 8 ')
      @mouse_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " = 'EUCOMMToolsCre'")

      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_EUCOMMTOOLSCRE_ID/, ' = 8 ')
      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " = 'EUCOMMToolsCre'")

      @gene_phenotyping_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " = 'EUCOMMToolsCre'")
    else
      @mouse_sql.gsub!(/SUBS_EUCOMMTOOLSCRE_ID/, ' != 8 ')
      @mouse_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " != 'EUCOMMToolsCre'")

      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_EUCOMMTOOLSCRE_ID/, ' != 8 ')
      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " != 'EUCOMMToolsCre'")
      @gene_phenotyping_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " != 'EUCOMMToolsCre'")
    end

    @allele_data = {}
    @gene_data = {}
  end

  def mouse_sql
    @mouse_sql
  end

  def es_cell_and_targeting_vector_sql
    @es_cell_and_targeting_vector_sql
  end

  def gene_phenotyping_sql
    @gene_phenotyping_sql
  end

  def gene_sql
    @gene_sql
  end

  def allele_data
    @allele_data
  end

  def gene_data
    @gene_data
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
    puts "------------------"

    raise "file_name Parameter required" if @file_name.blank?
    raise "Invalid Parameter show_eucommtoolscre must be a boolean" unless [TrueClass, FalseClass].include?(@show_eucommtoolscre.class)
    raise "Invalid Marker Symbol provided" if !@marker_symbols.blank? && @marker_symbols.any?{|ms| Gene.find_by_marker_symbol(ms).blank?}
  end

  def save_to_file
    raise if @file_name.blank?

    file_exists = File.file?(@file_name)

    file = open(@file_name, 'a')

    file.write(Solr::Allele2.tsv_header) unless file_exists
#puts Solr::Allele2.tsv_header
    @allele_data.each do |key, allele|
      file.write(allele.doc_to_tsv)
#puts allele.doc_to_tsv
    end

    @gene_data.each do |key, gene|
      file.write(gene.doc_to_tsv)
#puts gene.doc_to_tsv
    end
  end

  def mouse_status_is_more_adavanced(status_challenger, doc_status)
    return false if status_challenger.blank?
    if @mouse_status_list[doc_status] < @mouse_status_list[status_challenger]
      return true
    else
      return false
    end
  end
  private :mouse_status_is_more_adavanced

  def phenotype_status_is_more_adavanced(status_challenger, doc_status)
    return false if status_challenger.blank?
    if @phenotype_status_list[doc_status] < @phenotype_status_list[status_challenger]
      return true
    else
      return false
    end
  end
  private :phenotype_status_is_more_adavanced

  def generate_data
    puts "#### step 1 - Process Default Genes details..."

    puts "#### select..."
    #puts @gene_sql
    rows = ActiveRecord::Base.connection.execute(@gene_sql)

    puts "#### processing rows ..."
    rows.each do |row|
      puts "PROCESSING ROW #{row['marker_symbol']}" unless @marker_symbols.nil?
      #pp row
      @gene_data[row['mgi_accession_id']] = create_new_default_gene_doc(row)
    end

    puts "#### step 1 - Complete"
    puts "#### step 2 - Process Mice Data..."

    puts "#### select..."
#    puts @mouse_sql
    rows = ActiveRecord::Base.connection.execute(@mouse_sql)
 
    puts "#### processing rows ..."
    rows.each do |row|
      #pp row

      # ignore if mouse status is aborted
      next if !row['mouse_allele_mod_status_name'].blank? && row['mouse_allele_mod_status_name'] == 'Mouse Allele Modification Aborted'
      next if !row['mi_status_name'].blank? && row['mi_status_name'] == 'Micro-injection aborted'

      # Update gene doc
      #puts "Grab gene doc for #{row['marker_symbol']} and update mouse information"
      doc = get_gene_doc(row['gene_mgi_accession_id'])
      mouse_gene_update_doc(doc, row)

      if row['colony_mgi_allele_symbol_superscript'].blank? || row['colony_allele_type'].blank?
        puts "    ALLELE SYMBOL MISSING FOR mouse: #{row['gene_symbol']}"
        next
      end

      allele_details = {'allele_symbol' => row['colony_mgi_allele_symbol_superscript'], 'allele_type' => row['colony_allele_type']}

      # Update allele doc
      #puts "Grab allele doc for #{allele_details['allele_symbol']} and update mouse information"
      doc = get_allele_doc(row, allele_details)
      mouse_allele_update_doc(doc, row)
    end



    puts "#### step 2 - Complete"
    puts "#### step 3 - Process ES Cell and Targeting Vector Data..."

    puts "#### select..."
 #   puts @es_cell_and_targeting_vector_sql
    rows = ActiveRecord::Base.connection.execute(@es_cell_and_targeting_vector_sql)

    puts "#### processing rows ..."
    rows.each do |row|
      #pp row
      ## clean up aggragated data from sql: i.e. remove duplicates etc.
      row['allele_id'] = (self.class.convert_to_array("{#{row['es_allele_ids_not_distinct']}}") + self.class.convert_to_array("{#{row['tv_allele_ids_not_distinct']}}")).first
      row['allele_mgi_accession_id'] = self.class.convert_to_array("{#{row['es_mgi_allele_ids_not_distinct']}}").reject { |c| c.empty? }.first
      row['es_cell_name'] = self.class.convert_to_array("{#{row['es_cell_names']}}").first

      row['es_ikmc_projects'] = self.class.convert_to_array("{#{row['es_ikmc_projects_not_distinct']}}").uniq
      row['es_pipelines'] = self.class.convert_to_array("{#{row['es_pipelines_not_distinct']}}").uniq
      row['tv_ikmc_projects'] = self.class.convert_to_array("{#{row['tv_ikmc_projects_not_distinct']}}").uniq
      row['tv_pipelines'] = self.class.convert_to_array("{#{row['tv_pipelines_not_distinct']}}").uniq

      # Update gene doc
      #puts "Grab gene doc for #{row['marker_symbol']} and update ES Cell information"
      doc = get_gene_doc(row['gene_mgi_accession_id'])
      es_cell_gene_update_doc(doc, row)

      if !row['mgi_allele_symbol_superscript'].blank?
        allele_details = {'allele_symbol' => row['mgi_allele_symbol_superscript'], 'allele_type' => row['allele_type']}
      elsif !row['design_id'].blank? && !row['cassette'].blank? && !row['mutation_type_allele_code'].blank?
        allele_details = {'allele_symbol' => "#{row['allele_prefix']}#{row['design_id']}(#{row['cassette']})", 'allele_type' => row['mutation_type_allele_code']}
      elsif !row['allele_id'].blank? && !row['cassette'].blank? && !row['mutation_type_allele_code'].blank?
        allele_details = {'allele_symbol' => "#{row['allele_prefix']}#{row['allele_id']}(#{row['cassette']})", 'allele_type' => row['mutation_type_allele_code']}
      else
        allele_details = {'allele_symbol' => nil, 'allele_type' => nil}
      end

      if allele_details['allele_symbol'].blank? || allele_details['allele_type'].blank?
        puts "    ALLELE SYMBOL MISSING FOR es_cell: #{row['gene_symbol']}"
        next
      end
      # Update allele doc
      #puts "Grab allele doc for #{allele_details['allele_symbol']} and update ES Cell information"
      doc = get_allele_doc(row, allele_details)
      es_cell_allele_update_doc(doc, row)
    end


    puts "#### step 3 - Complete"

    puts "#### step 4 - Add missing phenotyping statuses to gene docs"

    rows = ActiveRecord::Base.connection.execute(@gene_phenotyping_sql)

    rows.each do |row|
      doc = get_gene_doc(row['gene_mgi_accession_id'])
      phenotyping_gene_update_doc(doc, row)
    end

    puts "#### step 4 - Complete"

    puts "#### step 5 - Append Additional Data..."

    ## append additional data based on already collated data
    @allele_data.each do |key, allele_data_doc|

      gene_doc = @gene_data[allele_data_doc.mgi_accession_id]

      allele_data_doc.marker_type = gene_doc.marker_type
      allele_data_doc.marker_name = gene_doc.marker_name
      allele_data_doc.marker_synonym = gene_doc.synonym
      allele_data_doc.marker_mgi_accession_id = gene_doc.mgi_accession_id
      allele_data_doc.feature_type = gene_doc.feature_type

      allele_data_doc.human_gene_symbol = gene_doc.human_gene_symbol
      allele_data_doc.human_entrez_gene_id = gene_doc.human_entrez_gene_id
      allele_data_doc.human_homolo_gene_id = gene_doc.human_homolo_gene_id

      if allele_data_doc.mutation_type == 'tm'
        allele_data_doc.mutation_type = 'Targeted'
      elsif allele_data_doc.mutation_type == 'em'
        allele_data_doc.mutation_type = 'Endonuclease-mediated'
      else
        allele_data_doc.mutation_type = nil
      end

      mutagenesis_url = TargRep::RealAllele.mutagenesis_url({'mgi_accession_id' => allele_data_doc.mgi_accession_id,
                                                             'allele_symbol' => allele_data_doc.allele_name,
                                                             'allele_type' => allele_data_doc.allele_type,
                                                             'pipeline' => allele_data_doc.pipeline
                                                            })

      mutagenesis_url = '' if allele_data_doc.allele_name =~ /#{allele_data_doc.cassette}/
      allele_data_doc.links <<   "mutagenesis_url:#{mutagenesis_url}" unless mutagenesis_url.blank?

      # Add allele symbol string variants
      allele_data_doc.allele_symbol = "#{allele_data_doc.marker_symbol}<#{allele_data_doc.allele_name}>" # eg) Cbx1<tm1a(EUCOMM)Wtsi>
      allele_data_doc.allele_symbol_search_variants << "#{allele_data_doc.marker_symbol}#{allele_data_doc.allele_name}" # eg) Cbx1tm1a(EUCOMM)Wtsi
      allele_data_doc.allele_symbol_search_variants << "#{allele_data_doc.marker_symbol} #{allele_data_doc.allele_name}" # eg) Cbx1 tm1a(EUCOMM)Wtsi
      allele_data_doc.allele_symbol_search_variants << "#{allele_data_doc.marker_symbol}<sup>#{allele_data_doc.allele_name}</sup>" # eg) Cbx1<sup>tm1a(EUCOMM)Wtsi</sup>
      allele_data_doc.allele_symbol_search_variants << "#{allele_data_doc.marker_symbol}<#{allele_data_doc.allele_name}>" # eg) Cbx1<tm1a(EUCOMM)Wtsi>

      if !allele_data_doc.cassette_type.blank? && allele_data_doc.cassette_type == 'Promotorless'
        with_feature = 'Promotorless'
        without_feature = 'Promotor Driven'
      else
        with_feature = 'Promotor Driven'
        without_feature = 'Promotorless'
      end

      allele_features = {
        'a'  => {'allele_category' => 'Knockout First', 'features' => ['Reporter Tag', "#{with_feature} Selection Tag", "Conditional Potential", "Non-Expressive"], 'without_features' => ["#{without_feature} Selection Tag"]},
        'b'  => {'allele_category' => 'Deletion', 'features' => ['Reporter Tag', ], 'without_features' => ["Promotorless Selection Tag", "Promotor Driven Selection Tag"]},
        'c'  => {'allele_category' => 'Wild type Floxed Exon', 'features' => ["Conditional Potential"], 'without_features' => ["Reporter Tag", "Promotorless Selection Tag", "Promotor Driven Selection Tag"]},
        'd'  => {'allele_category' => 'Deletion', 'features' => [], 'without_features' => ["Reporter Tag", "Promotorless Selection Tag", "Promotor Driven Selection Tag"]},
        'e'  => {'allele_category' => 'Targeted, Non-Conditional', 'features' => ['Reporter Tag', "#{with_feature} Selection Tag", "Non-Expressive"], 'without_features' => ["#{without_feature} Selection Tag"]},
        'e.1'  => {'allele_category' => 'Targeted, Non-Conditional', 'features' => ['Reporter Tag'], 'without_features' => ["Promoterless Selection Tag", "Promotor Driven Selection Tag"]},
        "''"   => {'allele_category' => 'Deletion', 'features' => ['Reporter Tag', "#{with_feature} Selection Tag"], 'without_features' => ["#{without_feature} Selection Tag"]},
        '.1' => {'allele_category' => 'Deletion', 'features' => ['Reporter Tag'], 'without_features' => ["Promotorless Selection Tag", "Promotor Driven Selection Tag"]},
        '.2' => {'allele_category' => 'Deletion', 'features' => [], 'without_features' => ["Reporter Tag", "Promotorless Selection Tag", "Promotor Driven Selection Tag"]},
        'Indel' => {'allele_category' => 'Indel', 'features' => [], 'without_features' => ["Reporter Tag", "Promotorless Selection Tag", "Promotor Driven Selection Tag"]},
        'Deletion' => {'allele_category' => 'Deletion', 'features' => [], 'without_features' => ["Reporter Tag", "Promotorless Selection Tag", "Promotor Driven Selection Tag"]}, 
      }

      if allele_features.include?(allele_data_doc.allele_type)
        allele_data_doc.allele_category = allele_features[allele_data_doc.allele_type]['allele_category']
        allele_data_doc.allele_features = allele_features[allele_data_doc.allele_type]['features']
        allele_data_doc.without_allele_features = allele_features[allele_data_doc.allele_type]['without_features']
      else
        allele_data_doc.allele_category << allele_data_doc.allele_type
      end
      
      allele_data_doc.tissues_available = true if allele_data_doc.tissue_types.include?('Fixed Tissue') || allele_data_doc.tissue_types.include?('Paraffin-embedded Sections')


    end

    ## append additional data based on already collated data
    @gene_data.each do |key, gene_data_doc|

      gene_data_doc.es_cell_status = 'No ES Cell Production' if gene_data_doc.es_cell_status.blank? && gene_data_doc.feature_type == 'protein coding gene'

      gene_data_doc.marker_mgi_accession_id = gene_data_doc.mgi_accession_id
      gene_data_doc.latest_es_cell_status = gene_data_doc.es_cell_status
      gene_data_doc.latest_mouse_status = gene_data_doc.mouse_status
      gene_data_doc.latest_phenotype_status = gene_data_doc.phenotype_status
      gene_data_doc.latest_production_centre = gene_data_doc.production_centres
      gene_data_doc.latest_phenotyping_centre = gene_data_doc.phenotyping_centres
      gene_data_doc.latest_phenotype_started = (['Phenotyping Started', 'Phenotyping Complete'].include?(gene_data_doc.phenotype_status) ? true : false) unless gene_data_doc.phenotype_status.blank?
      gene_data_doc.latest_phenotype_complete = (['Phenotyping Complete'].include?(gene_data_doc.phenotype_status) ? true : false) unless gene_data_doc.phenotype_status.blank?

      gene_data_doc.late_adult_phenotype_started = (['Late Adult Phenotyping Started', 'Late Adult Phenotyping Complete'].include?(gene_data_doc.late_adult_phenotype_status) ? true : false) unless gene_data_doc.late_adult_phenotype_status.blank?
      gene_data_doc.late_adult_phenotype_complete = (['Late Adult Phenotyping Complete'].include?(gene_data_doc.late_adult_phenotype_status) ? true : false) unless gene_data_doc.late_adult_phenotype_status.blank?

      gene_data_doc.latest_project_status = gene_data_doc.es_cell_status
      gene_data_doc.latest_project_status = gene_data_doc.mouse_status unless gene_data_doc.mouse_status.blank?
      gene_data_doc.latest_project_status = gene_data_doc.phenotype_status unless gene_data_doc.phenotype_status.blank?

      gene_data_doc.latest_project_status_legacy = @translate_to_legacy_status[gene_data_doc.latest_project_status] if @translate_to_legacy_status.has_key?(gene_data_doc.latest_project_status)
      gene_data_doc.conditional_mouse_status = @translate_to_legacy_status[gene_data_doc.conditional_mouse_status] if @translate_to_legacy_status.has_key?(gene_data_doc.conditional_mouse_status)
      gene_data_doc.deletion_mouse_status = @translate_to_legacy_status[gene_data_doc.deletion_mouse_status] if @translate_to_legacy_status.has_key?(gene_data_doc.deletion_mouse_status)
      gene_data_doc.disease_model_status = @translate_to_legacy_status[gene_data_doc.disease_model_status] if @translate_to_legacy_status.has_key?(gene_data_doc.disease_model_status)
    end
    puts "#### step 4 - Complete"
  end


  def get_allele_doc(data_row, allele_details)
    doc =  @allele_data["#{data_row['gene_mgi_accession_id']} #{allele_details['allele_symbol']}"] || create_new_default_allele_doc(data_row, allele_details)
    if doc.blank?
      raise "allele doc not found for #{data_row['gene_mgi_accession_id']} + #{allele_details['allele_symbol']}"
    else
      return doc
    end
  end
  private :get_allele_doc

  def get_gene_doc(mgi_accession_id)
    #puts "GENE ID: #{mgi_accession_id}"
    doc =  @gene_data[mgi_accession_id]
    if doc.blank?
      raise "gene doc not found for #{mgi_accession_id}"
    else
      return doc
    end
  end
  private :get_gene_doc

  def create_new_default_allele_doc(data_row, allele_details)

    southern_tools_url = TargRep::EsCell.southern_tools_url(data_row['es_cell_name']) unless data_row['excised'] == 't'
    lrpcr_genotype_primers = TargRep::RealAllele.lrpcr_genotype_primers(data_row['gene_mgi_accession_id'], allele_details['allele_symbol'], allele_details['allele_type'])
    genotype_primers_url = TargRep::RealAllele.lrpcr_genotype_primers(data_row['gene_mgi_accession_id'], allele_details['allele_symbol'], allele_details['allele_type'])

    links = []
    links <<   "southern_tools:#{southern_tools_url}" unless southern_tools_url.blank?
    links <<   "lrpcr_genotype_primers:#{lrpcr_genotype_primers}" unless lrpcr_genotype_primers.blank?
    links <<   "genotype_primers:#{genotype_primers_url}" unless genotype_primers_url.blank?

    @allele_data["#{data_row['gene_mgi_accession_id']} #{allele_details['allele_symbol']}"] = Solr::Allele2.new ({
                                                       'allele_design_project' => @allele_design_project,
                                                       'marker_symbol' => data_row['gene_symbol'],
                                                       'mgi_accession_id' => data_row['gene_mgi_accession_id'],
                                                       'allele_symbol' => '',
                                                       'allele_symbol_search_variants' => [],
                                                       'allele_name' => allele_details['allele_symbol'],
                                                       'allele_mgi_accession_id' => '',
                                                       'allele_type' => allele_details['allele_type'] ,
                                                       'allele_description' => '',
                                                       'genbank_file' => TargRep::Allele.genbank_file_url(data_row['allele_id'], "#{allele_details['allele_type'].blank? ? nil : allele_details['allele_type']}"),
                                                       'allele_image' => TargRep::Allele.allele_image_url(data_row['gene_symbol'], data_row['allele_id'], "#{allele_details['allele_type'].blank? ? nil : allele_details['allele_type']}"),
                                                       'allele_simple_image' => TargRep::Allele.simple_allele_image_url(data_row['gene_symbol'], data_row['allele_id'], "#{allele_details['allele_type'].blank? ? nil : allele_details['allele_type']}"),
                                                       'vector_genbank_file' => '',
                                                       'vector_allele_image' => '',
                                                       'design_id' => '',
                                                       'cassette' => '',
                                                       'cassette_type' => '',
                                                       'pipeline' => [],
                                                       'ikmc_project' => [],
                                                       'mutation_type' => allele_details['allele_symbol'][0,2],
                                                       'allele_category' => '',
                                                       'allele_features' => [],
                                                       'without_allele_features' => [],
                                                       'targeting_vector_available' => false,
                                                       'es_cell_available' => false, 
                                                       'mouse_available' => false,
                                                       'mouse_status' => '',
                                                       'phenotype_status' => '',
                                                       'late_adult_phenotype_status' => '',
                                                       'es_cell_status' => '',
                                                       'production_centre' => '',
                                                       'phenotyping_centre' => '',
                                                       'production_centres' => [],
                                                       'phenotyping_centres' => [],
                                                       'late_adult_phenotyping_centre' => '',
                                                       'late_adult_phenotyping_centres' => [],
                                                       'tissues_available' => false,
                                                       'tissue_types' => [],
                                                       'tissue_enquiry_links' => [],
                                                       'tissue_distribution_centres' => [],
                                                       'links' => links,
                                                       'type' => 'Allele'})

    return @allele_data["#{data_row['gene_mgi_accession_id']} #{allele_details['allele_symbol']}"]
  end
  private :create_new_default_allele_doc

  def mouse_allele_update_doc(doc, data_row)

    doc.allele_description = Allele.allele_description({
                                             'marker_symbol'               => data_row['gene_symbol'],
                                             'cassette'                    => data_row['cassette'],
                                             'allele_type'                 => data_row['colony_allele_type'],
                                             'allele_subtype'              => data_row['allele_subtype']
                                           })

# I think the is not nessary any more you can just use the colony_mgi_allelle_id
    if !data_row['colony_mgi_allele_id'].blank?
      doc.allele_mgi_accession_id = data_row['colony_mgi_allele_id']
    elsif data_row['mouse_allele_mod_id'].blank? && !data_row['es_cell_mgi_allele_id'].blank?
      doc.allele_mgi_accession_id = data_row['es_cell_mgi_allele_id']
    end

    # set Mouse status
# can mouse status not be collapsed into one field returned from the query?
    mouse_status = data_row['mouse_allele_status_name'] || data_row['mi_status_name']
# can mouse production Centre not be collapsed into one field returned from the query?
    mouse_production_centre = data_row['mouse_allele_production_centre'] || data_row['mi_production_centre']

# only going to add alleles with genotype confirmed mice
    if doc.mouse_status.blank? || mouse_status_is_more_adavanced(mouse_status, doc.mouse_status)
      doc.mouse_status = mouse_status
      doc.production_centre = mouse_production_centre
    end

    if doc.phenotype_status.blank? || mouse_status_is_more_adavanced(data_row['phenotyping_status_name'], doc.phenotype_status)
      doc.phenotype_status = data_row['phenotyping_status_name']
      doc.phenotyping_centre = data_row['phenotyping_centre']
    end

    if doc.late_adult_phenotype_status.blank? || phenotype_status_is_more_adavanced(data_row['late_adult_phenotyping_status_name'], doc.late_adult_phenotype_status)
      doc.late_adult_phenotype_status = data_row['late_adult_phenotyping_status_name']
      doc.late_adult_phenotyping_centre = data_row['late_adult_phenotyping_centre'] if data_row['late_adult_phenotyping_status_name'] != 'Not Registered For Late Adult Phenotyping'
    end

    doc.production_centres << data_row['mouse_allele_production_centre'] unless data_row['mouse_allele_production_centre'].blank?
    doc.production_centres << data_row['mi_production_centre'] unless data_row['mi_production_centre'].blank?
    self.class.convert_to_array(data_row['phenotyping_centres']).each{|phenotyping_centre| doc.phenotyping_centres << phenotyping_centre}
    self.class.convert_to_array(data_row['late_adult_phenotyping_centres']).each{|phenotyping_centre| doc.late_adult_phenotyping_centres << phenotyping_centre}


    doc.production_centres = doc.production_centres.uniq
    doc.phenotyping_centres = doc.phenotyping_centres.uniq
    doc.late_adult_phenotyping_centres = doc.late_adult_phenotyping_centres.uniq

# mice will always be available
    if !doc.mouse_status.blank? && ['Genotype confirmed', 'Cre Excision Complete'].include?(doc.mouse_status)
      doc.mouse_available = true
    end

    tissue_distribution_centres = self.class.get_tissue_distribution_centres(data_row)

    tissue_distribution_centres.each do |dis_centre|
      order_name, order_link = self.class.tissue_order_links(dis_centre)
      if order_name && order_link
        doc.tissue_types << order_name
        doc.tissue_enquiry_links << order_link
        doc.tissue_distribution_centres << dis_centre[:distribution_centre_name]
      end
    end

    return true
  end
  private :mouse_allele_update_doc

  def es_cell_allele_update_doc(doc, data_row)
    doc.allele_description = Allele.allele_description({
                                         'marker_symbol'               => data_row['gene_symbol'],
                                         'cassette'                    => data_row['cassette'],
                                         'allele_type'                 => data_row['allele_type'],
                                         'allele_subtype'              => data_row['allele_subtype']
                                       })

    doc.design_id = data_row['design_id']
    doc.cassette = data_row['cassette']
    doc.cassette_type = data_row['cassette_type']
#    doc.links << "loa_link_id:#{data_row['targ_rep_alleles_id']}"

    # set ES Cell status
    if data_row['num_es_cells'].to_i > 0 || doc.es_cell_status == 'ES Cell Targeting Confirmed'
      doc.es_cell_status = 'ES Cell Targeting Confirmed'
      doc.es_cell_available = true
    else
      doc.es_cell_status = 'No ES Cell Production'
    end

    if data_row['num_targeting_vectors'].to_i > 0
      doc.targeting_vector_available = true
      doc.vector_genbank_file = TargRep::Allele.targeting_vector_genbank_file_url(data_row['allele_id'])
      doc.vector_allele_image = TargRep::Allele.vector_image_url(data_row['allele_id'])
    end

    doc.allele_mgi_accession_id = data_row['allele_mgi_accession_id'] unless data_row['allele_mgi_accession_id'].blank?

    data_row['es_pipelines'].each{|pipeline| doc.pipeline << pipeline} unless data_row['es_pipelines'].blank?
    data_row['tv_pipelines'].each{|pipeline| doc.pipeline << pipeline} unless data_row['tv_pipelines'].blank?

    data_row['es_ikmc_projects'].each{|ikmc_project| doc.ikmc_project << ikmc_project} unless data_row['es_ikmc_projects'].blank?
    data_row['tv_ikmc_projects'].each{|ikmc_project| doc.ikmc_project << ikmc_project} unless data_row['tv_ikmc_projects'].blank?

    doc.pipeline = doc.pipeline.uniq
    doc.ikmc_project = doc.ikmc_project.uniq
#    doc.links = doc.links.uniq

    return true
  end
  private :es_cell_allele_update_doc

  def create_new_default_gene_doc(data_row)
    gene_doc =  Solr::Allele2.new( {
                 'allele_design_project' => @allele_design_project,
                 'marker_symbol' => data_row['marker_symbol'],
                 'mgi_accession_id' => data_row['mgi_accession_id'],
                 'synonym' => !data_row['synonyms'].blank? ? data_row['synonyms'].split('|') : '',
                 'marker_type' => data_row['marker_type'],
                 'marker_name' => data_row['marker_name'],
                 'feature_type' => data_row['feature_type'],
                 'human_gene_symbol' => data_row['human_marker_symbol'],
                 'human_entrez_gene_id' => data_row['human_entrez_gene_id'],
                 'human_homolo_gene_id' => data_row['human_homolo_gene_id'],
                 'feature_chromosome' => data_row['chr'],
                 'feature_strand' => data_row['strand_name'],
                 'feature_coord_start' => data_row['start_coordinates'],
                 'feature_coord_end' => data_row['end_coordinates'],
                 'gene_model_ids' => ["ensembl_ids:#{data_row['ensembl_ids']}", "vega_ids:#{data_row['vega_ids']}", "ncbi_ids:#{data_row['ncbi_ids']}", "ccds_ids:#{data_row['ccds_ids']}"],
                 'genetic_map_links' => [],
                 'sequence_map_links' => [],
                 'pipeline' => [],
                 'ikmc_project' => [],
                 'mouse_status' => '',
                 'conditional_mouse_status' => '',
                 'deletion_mouse_status' => '',
                 'disease_model_status' => '',
                 'phenotype_status' => '',
                 'late_adult_phenotype_status' => '',
                 'late_adult_phenotyping_centre' => '',
                 'late_adult_phenotyping_centres' => [],
                 'late_adult_phenotype_started' => '',
                 'late_adult_phenotype_complete' => '',
                 'es_cell_status' => '',
                 'production_centre' => '',
                 'phenotyping_centre' => '',
                 'production_centres' => [],
                 'phenotyping_centres' => [],
                 'links' => [],
                 'type' => 'Gene',
                 'latest_es_cell_status' => '',
                 'latest_mouse_status' => '',
                 'latest_project_status_legacy' => '',
                 'latest_project_status' => '',
                 'latest_production_centre' => [],
                 'latest_phenotyping_centre' => [],
                 'latest_phenotype_started' => '',
                 'latest_phenotype_complete' => '',
                 'latest_phenotype_status' => ''
                } )

    unless  data_row['chr'].blank? || data_row['start_coordinates'].blank? || data_row['end_coordinates'].blank?
      gene_doc.genetic_map_links = ["mgi:http://www.informatics.jax.org/searches/linkmap.cgi?chromosome=#{data_row['chr']}&midpoint=#{data_row['cm_position']}&cmrange=1.0&dsegments=1&syntenics=0"] if data_row['cm_position'].blank?
      vega_id = data_row['vega_ids'].blank? ? "" : "g=#{data_row['vega_ids'].split(',').sort{|s1, s2| s2 <=> s1}[0]};"
      ensum_id = data_row['ensembl_ids'].blank? ? "" :"g=#{data_row['ensembl_ids'].split(',').sort{|s1, s2| s2 <=> s1}[0]};"
      gene_doc.sequence_map_links  << "vega:http://vega.sanger.ac.uk/Mus_musculus/Location/View?#{vega_id}r=#{data_row['chr']}:#{data_row['start_coordinates']}-#{data_row['end_coordinates']}"
      gene_doc.sequence_map_links  << "ensembl:http://www.ensembl.org/Mus_musculus/Location/View?#{ensum_id}r=#{data_row['chr']}:#{data_row['start_coordinates']}-#{data_row['end_coordinates']}"
      gene_doc.sequence_map_links  << "ucsc:http://genome.ucsc.edu/cgi-bin/hgTracks?db=mm10&position=chr#{data_row['chr']}%3A#{data_row['start_coordinates']}-#{data_row['end_coordinates']}"
      gene_doc.sequence_map_links  << "ncbi:http://www.ncbi.nlm.nih.gov/mapview/maps.cgi?TAXID=10090&CHR=#{data_row['chr']}&MAPS=genes%5B#{data_row['start_coordinates']}:#{data_row['end_coordinates']}%5D"
    end

    return gene_doc
  end
  private :create_new_default_gene_doc

  def mouse_gene_update_doc(doc, data_row)

    # set Mouse status
    mouse_status = data_row['mouse_allele_status_name'] || data_row['mi_status_name']
    allele_type = data_row['colony_allele_type']
    mouse_production_centre = data_row['mouse_allele_production_centre'] || data_row['mi_production_centre']

    if doc.mouse_status.blank? || mouse_status_is_more_adavanced(mouse_status, doc.mouse_status)
      doc.mouse_status = mouse_status
      doc.production_centre = mouse_production_centre
    end

    if ['a', 'c'].include?(allele_type) || data_row['allele_subtype'] == 'Conditional Ready'
      if doc.conditional_mouse_status.blank? || mouse_status_is_more_adavanced(mouse_status, doc.conditional_mouse_status)
        doc.conditional_mouse_status = mouse_status
      end
    elsif ['b', "''", 'd', '.1', '.2', 'Deletion', 'Indel'].include?(allele_type)
      if doc.deletion_mouse_status.blank? || mouse_status_is_more_adavanced(mouse_status, doc.deletion_mouse_status)
        doc.deletion_mouse_status = mouse_status
      end
    end

    if doc.phenotype_status.blank? || mouse_status_is_more_adavanced(data_row['phenotyping_status_name'], doc.phenotype_status)
      doc.phenotype_status = data_row['phenotyping_status_name']
      doc.phenotyping_centre = data_row['phenotyping_centre']
    end

    if doc.late_adult_phenotype_status.blank? || phenotype_status_is_more_adavanced(data_row['late_adult_phenotyping_status_name'], doc.late_adult_phenotype_status)
      doc.late_adult_phenotype_status = data_row['late_adult_phenotyping_status_name']
      doc.late_adult_phenotyping_centre = data_row['late_adult_phenotyping_centre'] if data_row['late_adult_phenotyping_status_name'] != 'Not Registered For Late Adult Phenotyping'
    end

    doc.production_centres << data_row['mouse_allele_production_centre'] unless data_row['mouse_allele_production_centre'].blank?
    doc.production_centres << data_row['mi_production_centre'] unless data_row['mi_production_centre'].blank?
    self.class.convert_to_array(data_row['phenotyping_centres']).each{|phenotyping_centre| doc.phenotyping_centres << phenotyping_centre}
    self.class.convert_to_array(data_row['late_adult_phenotyping_centres']).each{|phenotyping_centre| doc.late_adult_phenotyping_centres << phenotyping_centre}


    doc.production_centres = doc.production_centres.uniq
    doc.phenotyping_centres = doc.phenotyping_centres.uniq
    doc.late_adult_phenotyping_centres = doc.late_adult_phenotyping_centres.uniq
  end

  def es_cell_gene_update_doc(doc, data_row)
    # set ES Cell status
    if data_row['num_es_cells'].to_i > 0 || doc.es_cell_status == 'ES Cell Targeting Confirmed'
      doc.es_cell_status = 'ES Cell Targeting Confirmed'
    else
      doc.es_cell_status = 'No ES Cell Production'
    end

    data_row['es_pipelines'].each{|pipeline| doc.pipeline << pipeline} unless data_row['es_pipelines'].blank?
    data_row['tv_pipelines'].each{|pipeline| doc.pipeline << pipeline} unless data_row['tv_pipelines'].blank?

    data_row['es_ikmc_projects'].each{|ikmc_project| doc.ikmc_project << ikmc_project} unless data_row['es_ikmc_projects'].blank?
    data_row['tv_ikmc_projects'].each{|ikmc_project| doc.ikmc_project << ikmc_project} unless data_row['tv_ikmc_projects'].blank?

    doc.pipeline= doc.pipeline.uniq
    doc.ikmc_project = doc.ikmc_project.uniq
  end
  private :mouse_gene_update_doc

  def phenotyping_gene_update_doc(doc, data_row)

    if doc.phenotype_status.blank? || mouse_status_is_more_adavanced(data_row['phenotyping_status_name'], doc.phenotype_status)
      doc.phenotype_status = data_row['phenotyping_status_name']
      doc.phenotyping_centre = data_row['phenotyping_centre']
    end

    if doc.late_adult_phenotype_status.blank? || phenotype_status_is_more_adavanced(data_row['late_adult_phenotyping_status_name'], doc.late_adult_phenotype_status)
      doc.late_adult_phenotype_status = data_row['late_adult_phenotyping_status_name']
      doc.late_adult_phenotyping_centre = data_row['late_adult_phenotyping_centre'] if data_row['late_adult_phenotyping_status_name'] != 'Not Registered For Late Adult Phenotyping'
    end

    doc.phenotyping_centres << data_row['phenotyping_centre']
    doc.phenotyping_centres = doc.phenotyping_centres.uniq

    doc.late_adult_phenotyping_centres << data_row['late_adult_phenotyping_centre'] unless data_row['late_adult_phenotyping_centre'].blank?
    doc.late_adult_phenotyping_centres = doc.late_adult_phenotyping_centres.uniq
  end
  private :phenotyping_gene_update_doc

  def self.get_tissue_distribution_centres data_row
    return [] if data_row['tissue_distribution_centre_names'].blank?
    dist_centres       = convert_to_array_without_removing_nulls(data_row['tissue_distribution_centre_names'])
    starts             = convert_to_array_without_removing_nulls(data_row['tissue_start_dates'])
    ends               = convert_to_array_without_removing_nulls(data_row['tissue_end_dates'])
    deposited_material = convert_to_array_without_removing_nulls(data_row['tissue_deposited_tissues'])


    tissue_distribution_centres = []
    count = dist_centres.count
    return [] if count == 0
    (0...count).each do |i|
      tissue_distribution_centres << {:distribution_centre_name => dist_centres[i] == 'NULL' ?  nil : dist_centres[i],
                               :start_date               => starts[i] == 'NULL' ? nil : starts[i].to_time,
                               :end_date                 => ends[i] == 'NULL' ? nil : ends[i].to_time,
                               :deposited_material       => deposited_material[i] == 'NULL' ? nil : deposited_material[i]
                                }
    end
    return tissue_distribution_centres
  end


  def self.tissue_order_links(tissue_distribution)
    params = {
      :distribution_centre_name       => tissue_distribution[:distribution_centre_name],
      :deposited_material             => tissue_distribution[:deposited_material],
      :dc_start_date                  => tissue_distribution[:start_date],
      :dc_end_date                    => tissue_distribution[:end_date]
    }

    # create the order link
    begin
      return PhenotypingProduction::TissueDistributionCentre.calculate_order_link( params )
    rescue => e
      puts "Error fetching order link. Exception details:"
      puts e.inspect
      puts e.backtrace.join("\n")
      return []
    end
  end

  def self.convert_to_array psql_array
    return [] if psql_array.blank? || psql_array.length <= 2

    new_array = psql_array[1, psql_array.length-2].gsub('"', '').split(',')
    new_array.delete('NULL')
    return new_array
  end

  def self.convert_to_array_without_removing_nulls psql_array
    return [] if psql_array.blank? || psql_array.length <= 2

    new_array = psql_array[1, psql_array.length-2].gsub('"', '').split(',')
    return new_array
  end

end
