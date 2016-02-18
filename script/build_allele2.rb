#!/usr/bin/env ruby

require 'pp'
require "digest/md5"
require "#{Rails.root}/script/solr_connect"

class BuildAllele2

  GENE_SQL = <<-EOF
    SELECT genes.* FROM genes WHERE genes.marker_symbol IS NOT NULL SUBS_GENE_TEMPLATE;
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
        SELECT genes.marker_symbol AS gene_symbol, genes.mgi_accession_id AS gene_mgi_accession_id, targ_rep_es_cells.allele_id AS allele_id,
               mi_attempts.id AS mi_attempt_id, mi_attempts.external_ref AS mi_external_ref, mi_attempt_statuses.name AS mi_status_name, mi_attempts.report_to_public AS mi_report_to_public,
               blast_strain.name AS mi_blast_strain_name, test_cross_strain.name AS mi_test_cross_strain_name,
               targ_rep_es_cells.id AS es_cell_id, targ_rep_es_cells.name AS es_cell_name, targ_rep_es_cells.mgi_allele_symbol_superscript AS es_cell_mgi_allele_symbol_superscript, CASE WHEN targ_rep_es_cells.allele_type IS NULL THEN '' ELSE targ_rep_es_cells.allele_type END AS es_cell_allele_type, targ_rep_es_cells.allele_symbol_superscript_template AS es_cell_allele_superscript_template,
               mutagenesis_factor_summary.mutagenesis_details AS mi_mutagenesis_factor_details,
               colonies.id AS mi_colony_id, colonies.name AS mi_colony_name, colonies.mgi_allele_id AS mi_colony_mgi_allele_id, colonies.allele_name AS mi_colony_allele_name, allele_target As mi_allele_target ,colonies.mgi_allele_symbol_superscript AS mi_colony_mgi_allele_symbol_superscript, colonies.allele_symbol_superscript_template AS mi_colony_allele_symbol_superscript_template, colonies.allele_type AS mi_colony_allele_type, colony_background_strain.name AS mi_colony_background_strain_name,
               centres.name AS mi_production_centre
          FROM mi_attempts
            JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
            JOIN genes ON genes.id = mi_plans.gene_id SUBS_GENE_TEMPLATE
            JOIN consortia ON consortia.id = mi_plans.consortium_id AND consortia.name SUBS_EUCOMMTOOLSCRE
            JOIN centres ON centres.id = mi_plans.production_centre_id
            JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
            LEFT JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id
            LEFT JOIN strains blast_strain ON blast_strain.id = mi_attempts.blast_strain_id
            LEFT JOIN strains test_cross_strain ON test_cross_strain.id = mi_attempts.test_cross_strain_id
            LEFT JOIN strains colony_background_strain ON colony_background_strain.id = colonies.background_strain_id
            LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
            LEFT JOIN mutagenesis_factor_summary ON mutagenesis_factor_summary.mi_attempt_id = mi_attempts.id
        WHERE mi_attempts.experimental = false AND mi_attempt_statuses.name != 'Micro-injection aborted'

    ),

      phenotyping_production_summary AS (
        SELECT parent_colony_id, (array_agg(phenotyping_production_statuses.name ORDER BY phenotyping_production_statuses.order_by DESC))[1] AS phenotyping_status_name,
        (array_agg(centres.name ORDER BY phenotyping_production_statuses.order_by DESC))[1] AS phenotyping_centre, array_agg(centres.name ORDER BY phenotyping_production_statuses.order_by DESC) AS phenotyping_centres
        FROM phenotyping_productions
          JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = phenotyping_productions.status_id
          JOIN mi_plans ON mi_plans.id = phenotyping_productions.mi_plan_id
          JOIN genes ON genes.id = mi_plans.gene_id SUBS_GENE_TEMPLATE
          JOIN consortia ON consortia.id = mi_plans.consortium_id AND consortia.name SUBS_EUCOMMTOOLSCRE
          JOIN centres ON centres.id = mi_plans.production_centre_id
        WHERE phenotyping_production_statuses.name != 'Phenotype Production Aborted'
        GROUP BY parent_colony_id
      )


    -- Note! the colony data in colonies and mi_attempt_summary is the same when the colony was created via micro_injection.

    SELECT CASE WHEN colonies.mouse_allele_mod_id IS NOT NULL THEN 'MouseAlleleMod' ELSE 'MiAttempt' END AS colony_created_by,
           colonies.name AS colony_name, colonies.mgi_allele_id AS colony_mgi_allele_id, colonies.allele_name AS colony_allele_name, colonies.mgi_allele_symbol_superscript AS colony_mgi_allele_symbol_superscript, colonies.allele_symbol_superscript_template AS colony_allele_symbol_superscript_template, colonies.allele_type AS colony_allele_type, colony_background_strain.name AS colony_background_strain_name,
           colonies.allele_description_summary AS allele_description_summary, colonies.auto_allele_description AS auto_allele_description,
           mouse_allele_mod_statuses.name AS mouse_allele_status_name, deleter_strain.name AS mouse_allele_mod_deleter_strain, mouse_allele_mods.cre_excision AS excised,
           mi_attempt_summary.*,
           mam_centre.name AS mouse_allele_production_centre,
           phenotyping_production_summary.phenotyping_status_name AS phenotyping_status_name, phenotyping_production_summary.phenotyping_centre AS phenotyping_centre, phenotyping_production_summary.phenotyping_centres AS phenotyping_centres
    FROM colonies
      JOIN strains colony_background_strain ON colony_background_strain.id = colonies.background_strain_id
      LEFT JOIN (mouse_allele_mods
                  JOIN mi_plans mam_plan ON mam_plan.id = mouse_allele_mods.mi_plan_id
                  JOIN centres mam_centre ON mam_centre.id = mam_plan.production_centre_id
                  LEFT JOIN strains deleter_strain ON deleter_strain.id = mouse_allele_mods.deleter_strain_id
                  JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
                ) ON mouse_allele_mods.id = colonies.mouse_allele_mod_id AND mouse_allele_mods.report_to_public = true
      JOIN mi_attempt_summary ON mi_attempt_summary.mi_colony_id = mouse_allele_mods.parent_colony_id OR (mi_attempt_summary.mi_colony_id = colonies.id AND mi_attempt_summary.mi_report_to_public = true)
      LEFT JOIN phenotyping_production_summary ON phenotyping_production_summary.parent_colony_id = colonies.id
    WHERE (colonies.report_to_public = true AND colonies.genotype_confirmed = true) OR mi_mutagenesis_factor_details IS NULL
  EOF


  ES_CELL_VECTOR_ALLELES_SQL = <<-EOF
  WITH alleles_produced_from_vectors AS (
              SELECT targ_rep_targeting_vectors.id, genes.marker_symbol, genes.mgi_accession_id, targ_rep_es_cells.mgi_allele_symbol_superscript, targ_rep_es_cells.allele_symbol_superscript_template, targ_rep_es_cells.allele_type, CASE WHEN targ_rep_alleles.project_design_id IS NULL THEN '' ELSE CAST(targ_rep_alleles.project_design_id AS text) END, CASE WHEN targ_rep_alleles.cassette IS NULL THEN '' ELSE targ_rep_alleles.cassette END, targ_rep_mutation_methods.allele_prefix, targ_rep_mutation_types.allele_code,
                     count(CASE WHEN targ_rep_es_cells.report_to_public = false THEN NULL ELSE targ_rep_es_cells.id END) AS num_es_cells, string_agg(targ_rep_es_cells.mgi_allele_id, ',') AS es_mgi_allele_ids, string_agg(targ_rep_es_cells.name, ',') AS es_cell_names, string_agg(targ_rep_es_cells.ikmc_project_id, ',') AS es_ikmc_projects_not_distinct, string_agg(es_pipelines.name, ',') AS es_pipelines_not_distinct, string_agg(targ_rep_alleles.id::text, ',') AS allele_ids
              FROM targ_rep_es_cells
                LEFT JOIN targ_rep_targeting_vectors ON  targ_rep_targeting_vectors.id = targ_rep_es_cells.targeting_vector_id
                JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
                JOIN genes ON genes.id = targ_rep_alleles.gene_id SUBS_GENE_TEMPLATE
                JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
                JOIN targ_rep_mutation_methods ON targ_rep_mutation_methods.id = targ_rep_alleles.mutation_method_id
                JOIN targ_rep_pipelines es_pipelines ON es_pipelines.id = targ_rep_es_cells.pipeline_id AND es_pipelines.id SUBS_EUCOMMTOOLSCRE_ID
              WHERE targ_rep_es_cells.report_to_public = true OR targ_rep_targeting_vectors.report_to_public = true
              GROUP BY targ_rep_targeting_vectors.id, genes.marker_symbol, genes.mgi_accession_id, targ_rep_es_cells.mgi_allele_symbol_superscript, targ_rep_es_cells.allele_symbol_superscript_template, targ_rep_es_cells.allele_type, targ_rep_alleles.project_design_id, targ_rep_alleles.cassette, targ_rep_mutation_methods.allele_prefix, targ_rep_mutation_types.allele_code
  ),

  targeting_vector_info AS (
        SELECT targ_rep_targeting_vectors.*,
               genes.marker_symbol AS marker_symbol,
               genes.mgi_accession_id AS mgi_accession_id,
               tv_alleles.id AS tv_targeting_vector_allele_id,
               CASE WHEN tv_alleles.cassette IS NULL THEN '' ELSE tv_alleles.cassette END AS tv_cassette,
               CASE WHEN tv_alleles.project_design_id IS NULL THEN '' ELSE CAST(tv_alleles.project_design_id AS text) END AS tv_project_design_id,
               tv_mutation_type.name AS tv_mutation_type,
               tv_mutation_type.allele_code AS tv_allele_code,
               tv_mutation_method.name AS tv_mutation_method,
               tv_mutation_method.allele_prefix AS tv_allele_prefix,
               tv_pipelines.name AS tv_pipelines,
               ikmc_project_id AS tv_ikmc_project_id
        FROM targ_rep_targeting_vectors
          JOIN targ_rep_alleles tv_alleles ON tv_alleles.id = targ_rep_targeting_vectors.allele_id
          JOIN genes ON genes.id = tv_alleles.gene_id SUBS_GENE_TEMPLATE
          JOIN targ_rep_mutation_types tv_mutation_type ON tv_mutation_type.id = tv_alleles.mutation_type_id
          JOIN targ_rep_mutation_methods tv_mutation_method ON tv_mutation_method.id = tv_alleles.mutation_method_id
          JOIN targ_rep_pipelines tv_pipelines ON tv_pipelines.id = targ_rep_targeting_vectors.pipeline_id AND tv_pipelines.id SUBS_EUCOMMTOOLSCRE_ID
  )



    SELECT allele_summary.marker_symbol AS gene_symbol, allele_summary.mgi_accession_id AS gene_mgi_accession_id,
           allele_summary.mgi_allele_symbol_superscript AS es_cell_mgi_allele_symbol_superscript, allele_summary.allele_symbol_superscript_template AS es_cell_allele_symbol_superscript_template, allele_summary.allele_type AS es_cell_allele_type,
           allele_summary.project_design_id AS design_id, allele_summary.cassette, allele_summary.allele_prefix, allele_summary.allele_code AS mutation_type_allele_code,
           string_agg(allele_summary.es_allele_ids, ',') AS es_allele_ids_not_distinct,
           string_agg(allele_summary.es_mgi_allele_ids_not_distinct, ',') AS es_mgi_allele_ids_not_distinct,
           string_agg(allele_summary.tv_allele_id::text, ',') AS tv_allele_ids_not_distinct,
           string_agg(allele_summary.es_cell_names, ',') AS es_cell_names,
           string_agg(allele_summary.es_pipelines, ',') AS es_pipelines_not_distinct,
           string_agg(allele_summary.es_ikmc_projects, ',') AS es_ikmc_projects_not_distinct,
           string_agg(allele_summary.tv_pipeline, ',') AS tv_pipelines_not_distinct,
           string_agg(allele_summary.tv_ikmc_project, ',') AS tv_ikmc_projects_not_distinct,
           SUM (allele_summary.num_es_cells) AS num_es_cells,
           count(tv_id) AS num_tv_cells

      FROM (
        SELECT CASE WHEN alleles_produced_from_vectors.marker_symbol IS NOT NULL THEN alleles_produced_from_vectors.marker_symbol
                    WHEN targeting_vector_info.marker_symbol IS NOT NULL THEN targeting_vector_info.marker_symbol
                    ELSE NULL END AS marker_symbol,
               CASE WHEN alleles_produced_from_vectors.mgi_accession_id IS NOT NULL THEN alleles_produced_from_vectors.mgi_accession_id
                    WHEN targeting_vector_info.mgi_accession_id IS NOT NULL THEN targeting_vector_info.mgi_accession_id
                    ELSE NULL END AS mgi_accession_id,

               alleles_produced_from_vectors.mgi_allele_symbol_superscript,
               alleles_produced_from_vectors.allele_symbol_superscript_template,
               alleles_produced_from_vectors.allele_type,

               CASE WHEN alleles_produced_from_vectors.project_design_id IS NOT NULL THEN alleles_produced_from_vectors.project_design_id
                    WHEN targeting_vector_info.tv_project_design_id IS NOT NULL THEN targeting_vector_info.tv_project_design_id
                    ELSE NULL END AS project_design_id,
               CASE WHEN alleles_produced_from_vectors.cassette IS NOT NULL THEN alleles_produced_from_vectors.cassette
                    WHEN targeting_vector_info.tv_cassette IS NOT NULL THEN targeting_vector_info.tv_cassette
                    ELSE NULL END AS cassette,
               alleles_produced_from_vectors.es_mgi_allele_ids AS es_mgi_allele_ids_not_distinct,
               CASE WHEN alleles_produced_from_vectors.allele_prefix IS NOT NULL THEN alleles_produced_from_vectors.allele_prefix
                    ELSE targeting_vector_info.tv_allele_prefix END AS allele_prefix,
               CASE WHEN alleles_produced_from_vectors.allele_code IS NOT NULL THEN alleles_produced_from_vectors.allele_code
                    ELSE targeting_vector_info.tv_allele_code END AS allele_code,

               alleles_produced_from_vectors.allele_ids AS es_allele_ids,
               alleles_produced_from_vectors.es_cell_names AS es_cell_names,
               alleles_produced_from_vectors.es_pipelines_not_distinct AS es_pipelines,
               alleles_produced_from_vectors.es_ikmc_projects_not_distinct AS es_ikmc_projects,

               targeting_vector_info.tv_pipelines AS tv_pipeline,
               targeting_vector_info.tv_ikmc_project_id AS tv_ikmc_project,
               targeting_vector_info.id AS tv_id,
               targeting_vector_info.tv_targeting_vector_allele_id AS tv_allele_id,

               alleles_produced_from_vectors.num_es_cells AS num_es_cells

          FROM targeting_vector_info
           FULL JOIN alleles_produced_from_vectors
              ON alleles_produced_from_vectors.marker_symbol = targeting_vector_info.marker_symbol
                AND alleles_produced_from_vectors.cassette = targeting_vector_info.tv_cassette
                AND alleles_produced_from_vectors.project_design_id = targeting_vector_info.tv_project_design_id
                AND alleles_produced_from_vectors.allele_code       = targeting_vector_info.tv_allele_code
                AND alleles_produced_from_vectors.allele_prefix     = targeting_vector_info.tv_allele_prefix

        WHERE targeting_vector_info.report_to_public = true OR targeting_vector_info.id IS NULL
      ) AS allele_summary

    GROUP BY allele_summary.marker_symbol,
             allele_summary.mgi_accession_id,
             allele_summary.mgi_allele_symbol_superscript,
             allele_summary.allele_symbol_superscript_template,
             allele_summary.allele_type,
             allele_summary.project_design_id,
             allele_summary.cassette,
             allele_summary.allele_prefix,
             allele_summary.allele_code
  EOF


  def initialize(show_eucommtoolscre = false)
    @show_eucommtoolscre = show_eucommtoolscre
    @config = YAML.load_file("#{Rails.root}/script/build_allele2.yml")

    @solr_update = YAML.load_file("#{Rails.root}/config/solr_update.yml")

    @mouse_status_list = {}
    PhenotypingProduction::Status.all.each{|status| @mouse_status_list[status['name']] = status['order_by']}
    MouseAlleleMod::Status.all.each{|status| @mouse_status_list[status['name']] = status['order_by']}
    MiAttempt::Status.all.each{|status| @mouse_status_list[status['name']] = status['order_by']}

    @translate_to_legacy_status = {'No ES Cell Production'          => 'Not Assigned for ES Cell Production',
                                   'ES Cell Production in Progress' => 'Assigned for ES Cell Production',
                                   'ES Cell Targeting Confirmed'    => 'ES Cells Produced',
                                   'Micro-injection in progress'    => 'Assigned for Mouse Production and Phenotyping',
                                   'Chimeras obtained'              => 'Assigned for Mouse Production and Phenotyping',
                                   'Founders obtained'              => 'Assigned for Mouse Production and Phenotyping',
                                   'Genotype confirmed'             => 'Mice Produced',
                                   'Rederivation Started'           => 'Mice Produced',
                                   'Rederivation Complete'          => 'Mice Produced',
                                   'Cre Excision Started'           => 'Mice Produced',
                                   'Cre Excision Complete'          => 'Mice Produced',
                                   'Phenotype Attempt Registered'   => 'Mice Produced',
                                   'Phenotyping Started'            => 'Mice Produced',
                                   'Phenotyping Complete'           => 'Mice Produced'
                                 }

    @solr_user = @solr_update[Rails.env]['user']
    @solr_password = @solr_update[Rails.env]['password']

    @marker_symbol = !@config['options']['MARKER_SYMBOL'].blank? ? @config['options']['MARKER_SYMBOL'].split(',') : nil
    @load_from_file = @config['options']['LOAD_FROM_FILE']
    @save_as_csv = @config['options']['SAVE_AS_CSV']
    @root = "#{Rails.root}/tmp/solr_updates"

    pp @config['options']

    puts "#### loading alleles!" if @use_alleles
    puts "#### loading genes!" if @use_genes

    @gene_sql = GENE_SQL.dup
    @mouse_sql = MICE_ALLELE_SQL.dup
    @es_cell_and_targeting_vector_sql = ES_CELL_VECTOR_ALLELES_SQL.dup

    marker_symbols = @marker_symbol.to_a.map {|ms| "'#{ms}'" }.join ','

    if ! @marker_symbol.nil?
      @gene_sql.gsub!(/SUBS_GENE_TEMPLATE/, " AND genes.marker_symbol IN (#{marker_symbols})")
      @mouse_sql.gsub!(/SUBS_GENE_TEMPLATE/, " AND genes.marker_symbol IN (#{marker_symbols})")
      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_GENE_TEMPLATE/, " AND genes.marker_symbol IN (#{marker_symbols})")
    else
      @gene_sql.gsub!(/SUBS_GENE_TEMPLATE/, '')
      @mouse_sql.gsub!(/SUBS_GENE_TEMPLATE/, '')
      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_GENE_TEMPLATE/, '')
    end

    if @show_eucommtoolscre == true
      @mouse_sql.gsub!(/SUBS_EUCOMMTOOLSCRE_ID/, ' = 8 ')
      @mouse_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " = 'EUCOMMToolsCre'")

      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_EUCOMMTOOLSCRE_ID/, ' = 8 ')
      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " = 'EUCOMMToolsCre'")

      @solr_url = @solr_update[Rails.env]['index_proxy']['eucommtoolscre_allele2']
    else
      @mouse_sql.gsub!(/SUBS_EUCOMMTOOLSCRE_ID/, ' != 8 ')
      @mouse_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " != 'EUCOMMToolsCre'")

      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_EUCOMMTOOLSCRE_ID/, ' != 8 ')
      @es_cell_and_targeting_vector_sql.gsub!(/SUBS_EUCOMMTOOLSCRE/, " != 'EUCOMMToolsCre'")

      @solr_url = @solr_update[Rails.env]['index_proxy']['allele2']
    end

    @allele_data = {}
    @gene_data = {}

    puts "#### #{@solr_url}/admin/"

    if @load_from_file.blank?
      generate_data
    else
      load_from_file(@load_from_file)
    end

    if @save_as_csv
      save_data
    else
      update_solr
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

  def generate_data
    puts "#### index: #{@solr_url}"

    puts "#### step 1 - Process Default Genes details..."

    puts "#### select..."
    #puts @gene_sql
    rows = ActiveRecord::Base.connection.execute(@gene_sql)

    rows.each do |row|
      puts "PROCESSING ROW #{row['marker_symbol']}" unless @marker_symbol.nil?
      #pp row
      @gene_data[row['mgi_accession_id']] = create_new_default_gene_doc(row)
    end


    puts "#### step 2 - Process Mice Data..."

    puts "#### select..."
#    puts @mouse_sql
    rows = ActiveRecord::Base.connection.execute(@mouse_sql)

    rows.each do |row|
      #pp row

      # ignore if mouse status is aborted
      next if !row['mouse_allele_mod_status'].blank? && row['mouse_allele_mod_status'] == 'Mouse Allele Modification Aborted'
      next if !row['mi_status_name'].blank? && row['mi_status_name'] == 'Micro-injection aborted'

      # Update gene doc
      #puts "Grab gene doc for #{row['marker_symbol']} and update mouse information"
      doc = get_gene_doc(row['gene_mgi_accession_id'])
      mouse_gene_update_doc(doc, row)

      #puts "Calculating allele"
      allele_template = nil
      allele_template = row['es_cell_allele_superscript_template'] unless row['es_cell_allele_superscript_template'].blank?
      allele_template = row['mi_colony_allele_symbol_superscript_template'] unless row['mi_colony_allele_symbol_superscript_template'].blank?
      allele_template = row['colony_allele_symbol_superscript_template'] unless row['colony_allele_symbol_superscript_template'].blank?

      allele_details = TargRep::RealAllele.calculate_allele_information( {'es_cell_allele_type' => row['es_cell_allele_type'] || nil,
                                                                          'parent_colony_allele_type' => row['mi_colony_allele_type'] || nil,
                                                                          'colony_allele_type' => row['colony_allele_type'] || nil,
                                                                          'allele_id' => row['allele_id'] || nil,
                                                                          'mi_allele_target'   => row['mi_allele_target'] || nil,
                                                                          'allele_name' => row['colony_allele_name'] || nil,
                                                                          'excised' => row['excised'] == 't' ? true : false,
                                                                          'allele_symbol_superscript_template' => allele_template || nil,
                                                                          'mgi_allele_symbol_superscript' => row['colony_mgi_allele_symbol_superscript'] || nil
                                                                        })

      # Update allele doc
      #puts "Grab allele doc for #{allele_details['allele_symbol']} and update mouse information"
      doc = get_allele_doc(row, allele_details)
      mouse_allele_update_doc(doc, row)
    end



    puts "#### step 3 - Process ES Cell and Targeting Vector Data..."

    puts "#### select..."
 #   puts @es_cell_and_targeting_vector_sql
    rows = ActiveRecord::Base.connection.execute(@es_cell_and_targeting_vector_sql)

    # pass 2/3

    rows.each do |row|
      #pp row
      ## clean up aggragated data from sql: i.e. remove duplicates etc.
      row['allele_id'] = (self.class.convert_to_array("{#{row['es_allele_ids_not_distinct']}}") + self.class.convert_to_array("{#{row['tv_allele_ids_not_distinct']}}")).first
      row['allele_mgi_accession_id'] = self.class.convert_to_array("{#{row['es_mgi_allele_ids_not_distinct']}}").reject { |c| c.empty? }.first
      row['es_cell_name'] = self.class.convert_to_array("{#{row['es_cell_names']}}").first

      if !row['num_es_cells'].blank? && row['num_es_cells'].to_i > 0
        row['es_cell_allele_type'] = row['es_cell_allele_type'].blank? ? '' : row['es_cell_allele_type']
      end

      row['es_ikmc_projects'] = self.class.convert_to_array("{#{row['es_ikmc_projects_not_distinct']}}").uniq
      row['es_pipelines'] = self.class.convert_to_array("{#{row['es_pipelines_not_distinct']}}").uniq
      row['tv_ikmc_projects'] = self.class.convert_to_array("{#{row['tv_ikmc_projects_not_distinct']}}").uniq
      row['tv_pipelines'] = self.class.convert_to_array("{#{row['tv_pipelines_not_distinct']}}").uniq

      # Update gene doc
      #puts "Grab gene doc for #{row['marker_symbol']} and update ES Cell information"
      doc = get_gene_doc(row['gene_mgi_accession_id'])
      es_cell_gene_update_doc(doc, row)

      #puts "Calculating allele"

      allele_details = TargRep::RealAllele.calculate_allele_information( {'mutation_method_allele_prefix' => row['allele_prefix'] || nil,
                                                                          'mutation_type_allele_code' => row['mutation_type_allele_code'] || nil,
                                                                          'es_cell_allele_type' => row['es_cell_allele_type'] || nil,
                                                                          'allele_id' => row['allele_id'] || nil,
                                                                          'design_id' => row['design_id'] || nil,
                                                                          'cassette' => row['cassette'] || nil,
                                                                          'allele_symbol_superscript_template' => row['es_cell_allele_symbol_superscript_template'] || nil,
                                                                          'mgi_allele_symbol_superscript' => row['es_cell_mgi_allele_symbol_superscript'] || nil
                                                                        })

      # Update allele doc
      #puts "Grab allele doc for #{allele_details['allele_symbol']} and update ES Cell information"
      doc = get_allele_doc(row, allele_details)
      es_cell_allele_update_doc(doc, row)
    end


    # pass 3/3

    ## append additional data based on already collated data
    @allele_data.each do |key, allele_data_row|
      allele_data_row['allele_description'] = TargRep::Allele.allele_description({
                                               'marker_symbol'               => allele_data_row['marker_symbol'],
                                               'cassette'                    => allele_data_row['cassette'],
                                               'allele_type'                 => allele_data_row['allele_type'],
                                               'allele_description_summary'  => allele_data_row['allele_description']
                                             })

      mutagenesis_url = TargRep::RealAllele.mutagenesis_url({'mgi_accession_id' => allele_data_row['mgi_accession_id'],
                                                             'allele_symbol' => allele_data_row['allele_name'],
                                                             'allele_type' => allele_data_row['allele_type'],
                                                             'pipeline' => allele_data_row['pipeline']
                                                            })

      mutagenesis_url = '' if allele_data_row['allele_name'] =~ /#{allele_data_row['cassette']}/
      allele_data_row['links'] <<   "mutagenesis_url:#{mutagenesis_url}" unless mutagenesis_url.blank?
    end

    ## append additional data based on already collated data
    @gene_data.each do |key, gene_data_row|

      gene_data_row['es_cell_status'] = 'No ES Cell Production' if gene_data_row['es_cell_status'].blank? && gene_data_row['feature_type'] == 'protein coding gene'

      gene_data_row['latest_es_cell_status'] = gene_data_row['es_cell_status']
      gene_data_row['latest_mouse_status'] = gene_data_row['mouse_status']
      gene_data_row['latest_phenotype_status'] = gene_data_row['phenotype_status']
      gene_data_row['latest_production_centre'] = gene_data_row['production_centre']
      gene_data_row['latest_phenotyping_centre'] = gene_data_row['phenotyping_centre']
      gene_data_row['latest_phenotype_started'] = (['Phenotyping Started', 'Phenotyping Complete'].include?(gene_data_row['phenotype_status']) ? true : false) unless gene_data_row['phenotype_status'].blank?
      gene_data_row['latest_phenotype_complete'] = (['Phenotyping Complete'].include?(gene_data_row['phenotype_status']) ? true : false) unless gene_data_row['phenotype_status'].blank?

      gene_data_row['latest_project_status'] = gene_data_row['es_cell_status']
      gene_data_row['latest_project_status'] = gene_data_row['mouse_status'] unless gene_data_row['mouse_status'].blank?
      gene_data_row['latest_project_status'] = gene_data_row['phenotype_status'] unless gene_data_row['phenotype_status'].blank?


      gene_data_row['latest_project_status_legacy'] = @translate_to_legacy_status[gene_data_row['latest_project_status']] if @translate_to_legacy_status.has_key?(gene_data_row['latest_project_status'])
    end

  end


  def get_allele_doc(data_row, allele_details)
    doc =  @allele_data["#{data_row['gene_mgi_accession_id']} #{allele_details['allele_symbol']}"] || create_new_default_allele_doc(data_row, allele_details)
    if doc.blank?
      raise "allele doc not found for #{data_row['gene_mgi_accession_id']} + #{allele_details['allele_symbol']}"
    else
      return doc
    end
  end

  def get_gene_doc(mgi_accession_id)
    #puts "GENE ID: #{mgi_accession_id}"
    doc =  @gene_data[mgi_accession_id]
    if doc.blank?
      raise "gene doc not found for #{mgi_accession_id}"
    else
      return doc
    end
  end

  def create_new_default_allele_doc(data_row, allele_details)

    southern_tools_url = TargRep::EsCell.southern_tools_url(data_row['es_cell_name']) unless data_row['excised'] == 't'
    lrpcr_genotype_primers = TargRep::RealAllele.lrpcr_genotype_primers(data_row['gene_mgi_accession_id'], allele_details['allele_symbol'], allele_details['allele_type'])
    genotype_primers_url = TargRep::RealAllele.lrpcr_genotype_primers(data_row['gene_mgi_accession_id'], allele_details['allele_symbol'], allele_details['allele_type'])

    links = []
    links <<   "southern_tools:#{southern_tools_url}" unless southern_tools_url.blank?
    links <<   "lrpcr_genotype_primers:#{lrpcr_genotype_primers}" unless lrpcr_genotype_primers.blank?
    links <<   "genotype_primers:#{genotype_primers_url}" unless genotype_primers_url.blank?

    @allele_data["#{data_row['gene_mgi_accession_id']} #{allele_details['allele_symbol']}"] = {
                                                       'marker_symbol' => data_row['gene_symbol'],
                                                       'mgi_accession_id' => data_row['gene_mgi_accession_id'],
                                                       'allele_name' => allele_details['allele_symbol'],
                                                       'allele_mgi_accession_id' => '',
                                                       'allele_type' => allele_details['allele_type'] ,
                                                       'allele_description' => '',
                                                       'genbank_file' => TargRep::Allele.genbank_file_url(data_row['allele_id'], "#{allele_details['allele_type'].blank? ? nil : allele_details['allele_type']}"),
                                                       'allele_image' => TargRep::Allele.allele_image_url(data_row['gene_symbol'], data_row['allele_id'], "#{allele_details['allele_type'].blank? ? nil : allele_details['allele_type']}"),
                                                       'allele_simple_image' => TargRep::Allele.simple_allele_image_url(data_row['gene_symbol'], data_row['allele_id'], "#{allele_details['allele_type'].blank? ? nil : allele_details['allele_type']}"),
                                                       'design_id' => '',
                                                       'cassette' => '',
                                                       'pipeline' => [],
                                                       'ikmc_project' => [],
                                                       'mouse_status' => '',
                                                       'phenotype_status' => '',
                                                       'es_cell_status' => '',
                                                       'production_centre' => '',
                                                       'phenotyping_centre' => '',
                                                       'production_centres' => [],
                                                       'phenotyping_centres' => [],
                                                       'links' => links,
                                                       'type' => 'Allele'
                                                                                            }

    return @allele_data["#{data_row['gene_mgi_accession_id']} #{allele_details['allele_symbol']}"]
  end

  def mouse_allele_update_doc(doc, data_row)

    doc['allele_mgi_accession_id'] = data_row['colony_mgi_allele_id'] unless data_row['colony_mgi_allele_id'].blank?
    doc['allele_description'] = data_row['auto_allele_description'].blank? ? data_row['allele_description_summary'] : data_row['auto_allele_description']

    # set Mouse status
    mouse_status = data_row['mouse_allele_status_name'] || data_row['mi_status_name']
    mouse_production_centre = data_row['mouse_allele_production_centre'] || data_row['mi_production_centre']

    if doc['mouse_status'].blank? || mouse_status_is_more_adavanced(mouse_status, doc['mouse_status'])
      doc['mouse_status'] = mouse_status
      doc['production_centre'] = mouse_production_centre
    end

    if doc['phenotype_status'].blank? || mouse_status_is_more_adavanced(data_row['phenotyping_status_name'], doc['phenotype_status'])
      doc['phenotype_status'] = data_row['phenotyping_status_name']
      doc['phenotyping_centre'] = data_row['phenotyping_centre']
    end

    doc['production_centres'] << data_row['mouse_allele_production_centre'] unless data_row['mouse_allele_production_centre'].blank?
    doc['production_centres'] << data_row['mi_production_centre'] unless data_row['mi_production_centre'].blank?
    self.class.convert_to_array(data_row['phenotyping_centres']).each{|phenotyping_centre| doc['phenotyping_centres'] << phenotyping_centre}

    doc['production_centres'] = doc['production_centres'].uniq
    doc['phenotyping_centres'] = doc['phenotyping_centres'].uniq

    return true
  end

  def es_cell_allele_update_doc(doc, data_row)
    doc['design_id'] = data_row['design_id']
    doc['cassette'] = data_row['cassette']
#    doc['links'] << "loa_link_id:#{data_row['targ_rep_alleles_id']}"

    # set ES Cell status
    if data_row['num_es_cells'].to_i > 0 || doc['es_cell_status'] == 'ES Cell Targeting Confirmed'
      doc['es_cell_status'] = 'ES Cell Targeting Confirmed'
    elsif data_row['num_targeting_vectors'].to_i > 0 || doc['es_cell_status'] == 'ES Cell Production in Progress'
      doc['es_cell_status'] = 'ES Cell Production in Progress'
    else
      doc['es_cell_status'] = 'No ES Cell Production'
    end

    doc['allele_mgi_accession_id'] = data_row['allele_mgi_accession_id']

    data_row['es_pipelines'].each{|pipeline| doc['pipeline'] << pipeline} unless data_row['es_pipelines'].blank?
    data_row['tv_pipelines'].each{|pipeline| doc['pipeline'] << pipeline} unless data_row['tv_pipelines'].blank?

    data_row['es_ikmc_projects'].each{|ikmc_project| doc['ikmc_project'] << ikmc_project} unless data_row['es_ikmc_projects'].blank?
    data_row['tv_ikmc_projects'].each{|ikmc_project| doc['ikmc_project'] << ikmc_project} unless data_row['tv_ikmc_projects'].blank?

    doc['pipeline']= doc['pipeline'].uniq
    doc['ikmc_project'] = doc['ikmc_project'].uniq
#    doc['links'] = doc['links'].uniq

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
                 'genetic_map_links' => [],
                 'sequence_map_links' => [],
                 'pipeline' => [],
                 'ikmc_project' => [],
                 'mouse_status' => '',
                 'phenotype_status' => '',
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
                 'latest_phenotype_status' => '',
                 'latest_es_cell_status' => '',
                 'latest_mouse_status' => ''
                }

    unless  data_row['chr'].blank? || data_row['start_coordinates'].blank? || data_row['end_coordinates'].blank?
      gene_doc['genetic_map_links'] = ["mgi:http://www.informatics.jax.org/searches/linkmap.cgi?chromosome=#{data_row['chr']}&midpoint=#{data_row['cm_position']}&cmrange=1.0&dsegments=1&syntenics=0"] if data_row['cm_position'].blank?
      vega_id = data_row['vega_ids'].blank? ? "" : "g=#{data_row['vega_ids'].split(',').sort{|s1, s2| s2 <=> s1}[0]};"
      ensum_id = data_row['ensembl_ids'].blank? ? "" :"g=#{data_row['ensembl_ids'].split(',').sort{|s1, s2| s2 <=> s1}[0]};"
      gene_doc['sequence_map_links']  << "vega:http://vega.sanger.ac.uk/Mus_musculus/Location/View?#{vega_id}r=#{data_row['chr']}:#{data_row['start_coordinates']}-#{data_row['end_coordinates']}"
      gene_doc['sequence_map_links']  << "ensembl:http://www.ensembl.org/Mus_musculus/Location/View?#{ensum_id}r=#{data_row['chr']}:#{data_row['start_coordinates']}-#{data_row['end_coordinates']}"
      gene_doc['sequence_map_links']  << "ucsc:http://genome.ucsc.edu/cgi-bin/hgTracks?db=mm10&position=chr#{data_row['chr']}%3A#{data_row['start_coordinates']}-#{data_row['end_coordinates']}"
      gene_doc['sequence_map_links']  << "ncbi:http://www.ncbi.nlm.nih.gov/mapview/maps.cgi?TAXID=10090&CHR=#{data_row['chr']}&MAPS=genes%5B#{data_row['start_coordinates']}:#{data_row['end_coordinates']}%5D"
    end

    return gene_doc
  end

  def mouse_gene_update_doc(doc, data_row)

    # set Mouse status
    mouse_status = data_row['mouse_allele_status_name'] || data_row['mi_status_name']
    mouse_production_centre = data_row['mouse_allele_production_centre'] || data_row['mi_production_centre']

    if doc['mouse_status'].blank? || mouse_status_is_more_adavanced(mouse_status, doc['mouse_status'])
      doc['mouse_status'] = mouse_status
      doc['production_centre'] = mouse_production_centre
    end

    if doc['phenotype_status'].blank? || mouse_status_is_more_adavanced(data_row['phenotyping_status_name'], doc['phenotype_status'])
      doc['phenotype_status'] = data_row['phenotyping_status_name']
      doc['phenotyping_centre'] = data_row['phenotyping_centre']
    end

    doc['production_centres'] << data_row['mouse_allele_production_centre'] unless data_row['mouse_allele_production_centre'].blank?
    doc['production_centres'] << data_row['mi_production_centre'] unless data_row['mi_production_centre'].blank?
    self.class.convert_to_array(data_row['phenotyping_centres']).each{|phenotyping_centre| doc['phenotyping_centres'] << phenotyping_centre}

    doc['production_centres'] = doc['production_centres'].uniq
    doc['phenotyping_centres'] = doc['phenotyping_centres'].uniq
  end

  def es_cell_gene_update_doc(doc, data_row)
    # set ES Cell status
    if data_row['num_es_cells'].to_i > 0 || doc['es_cell_status'] == 'ES Cell Targeting Confirmed'
      doc['es_cell_status'] = 'ES Cell Targeting Confirmed'
    elsif data_row['num_targeting_vectors'].to_i > 0 || doc['es_cell_status'] == 'ES Cell Production in Progress'
      doc['es_cell_status'] = 'ES Cell Production in Progress'
    else
      doc['es_cell_status'] = 'No ES Cell Production'
    end

    data_row['es_pipelines'].each{|pipeline| doc['pipeline'] << pipeline} unless data_row['es_pipelines'].blank?
    data_row['tv_pipelines'].each{|pipeline| doc['pipeline'] << pipeline} unless data_row['tv_pipelines'].blank?

    data_row['es_ikmc_projects'].each{|ikmc_project| doc['ikmc_project'] << ikmc_project} unless data_row['es_ikmc_projects'].blank?
    data_row['tv_ikmc_projects'].each{|ikmc_project| doc['ikmc_project'] << ikmc_project} unless data_row['tv_ikmc_projects'].blank?

    doc['pipeline']= doc['pipeline'].uniq
    doc['ikmc_project'] = doc['ikmc_project'].uniq
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
      WHERE a1.id = #{row1['targ_rep_alleles_id']} AND targ_rep_mutation_types.allele_code = '#{row1['mi_mouse_allele_type']}'
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



  ## NOTE 1 should really put this in a base class that the allele and product scripts can inherit from

  def save to_file
    require 'fileutils'
    puts "#### writing files..."

    FileUtils.mkdir_p "#{@root}"

    filename = "#{@root}/gene_data.csv"

    CSV.open(filename, "wb") do |csv|
      csv << @gene_data.first.keys
      @gene_data.each do |hash|
        csv << hash.values
      end
    end

    filename = "#{@root}/allele_data.csv"

    CSV.open(filename, "wb") do |csv|
      csv << @allele_data.first.keys
      @allele_data.each do |hash|
        csv << hash.values
      end
    end

    puts "#### done!"
  end


  def load_from_file
     raise 'Files do not exist' unless File.exist?("#{@root}/allele_data.csv") && File.exist?("#{@root}/gene_data.csv")

     filename = "#{@root}/gene_data.csv"
     file = CSV.open(filename, headers: true)
     file.each{|data| @gene_data[data['mgi_accession_id']] = data}

     filename = "#{@root}/allele_data.csv"
     file = CSV.open(filename, headers: true)
     file.each{|data| @allele_data["#{data['mgi_accession_id']} #{data['allele_symbol']}"] = data}

  end

  def update_solr

    if @allele_data.blank? && @gene_data.blank?
      return 'No data to update'
    elsif @gene_data.blank?
      raise 'Error. Inconsistent data.'
    end

    @proxy = SolrConnect::Proxy.new(@solr_url)
    delete_index
    send_to_index(build_json(@allele_data)) unless @allele_data.blank?
    send_to_index(build_json(@gene_data)) unless @gene_data.blank?
    commit_index_changes
  end


  ## NOTE 1 END

  def delete_index
    puts 'DELETE INDEX'

    if @marker_symbol.nil?
      @proxy.update({'delete' => {'query' => '*:*'}}.to_json, @solr_user, @solr_password)
    else
      @marker_symbol.each do |marker_symbol|
        @proxy.update({'delete' => {'query' => "marker_symbol_str:#{marker_symbol}"}}.to_json, @solr_user, @solr_password)
      end
    end

    puts 'DELETE INDEX - COMPLETED'
  end

  def send_to_index data
    puts 'SEND DATA TO INDEX'
    #pp data
    @proxy.update(data.join, @solr_user, @solr_password)

    puts 'SEND DATA TO INDEX - COMPLETED'
  end

  def commit_index_changes
    puts 'COMMITING DATA TO SOLR'

    @proxy.update({'commit' => {}}.to_json, @solr_user, @solr_password)

    puts 'DATA COMMITED'
  end

  def build_json data
    list = []
    data.each do |key, row|
      hash = nil

      # remove fields which contain null values.
      row = row.select{|key, value| ! value.blank?}

      item = {'add' => {'doc' => row }}
      list.push item.to_json
    end
    return list
  end


  def self.convert_to_array psql_array
    return [] if psql_array.blank? || psql_array.length <= 2

    new_array = psql_array[1, psql_array.length-2].gsub('"', '').split(',')
    new_array.delete('NULL')
    return new_array
  end

end



if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  puts "## Start Rebuild of the Allele 2 Core #{Time.now}"
  BuildAllele2.new
  puts "## Completed Rebuild of the Allele 2 Core#{Time.now}"

  puts "## Start Rebuild of the EUCOMMToolsCre Allele 2 Core#{Time.now}"
  BuildAllele2.new(true)
  puts "## Completed Rebuild of the EUCOMMToolsCre Allele 2 Core#{Time.now}"
end
