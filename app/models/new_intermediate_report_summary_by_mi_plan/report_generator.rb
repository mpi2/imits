module NewIntermediateReportSummaryByMiPlan::ReportGenerator
  class Generate
    attr_accessor :report_rows, :size, :clone_efficiencies, :gene_efficiencies

    def initialize
      @report_rows = []
      @clone_efficiencies = {}
      @gene_efficiencies = {}

      create_clone_efficiency_hash
      create_gene_efficiency_hash
      parse_raw_report

      nil
    end

    def raw_report
      @raw_report ||= ActiveRecord::Base.connection.execute(self.class.report_sql).to_a
    end

    def raw_clone_efficiencies
      @raw_clone_efficiencies ||= ActiveRecord::Base.connection.execute(self.class.clone_efficiency_sql).to_a
    end

    def raw_gene_efficiencies
      @raw_gene_efficiencies ||= ActiveRecord::Base.connection.execute(self.class.gene_efficiency_sql).to_a
    end

    def create_clone_efficiency_hash
      raw_clone_efficiencies.each do |ce|
        @clone_efficiencies[ce['mi_plan_id']] = {
          :distinct_genotype_confirmed_es_cells => ce['gtc_count'],
          :distinct_non_genotype_confirmed_es_cells => ce['non_gtc_count'],
          :distinct_old_genotype_confirmed_es_cells => ce['old_gtc_count'],
          :distinct_old_non_genotype_confirmed_es_cells => ce['old_non_gtc_count']
        }
      end

      nil
    end

    def create_gene_efficiency_hash
      raw_gene_efficiencies.each do |ge|
        @gene_efficiencies[ge['mi_plan_id']] = {
          :total_pipeline_efficiency_gene_count => ge['total_count'],
          :gc_pipeline_efficiency_gene_count => ge['gtc_count'],
          :total_old_pipeline_efficiency_gene_count => ge['old_total_count'],
          :gc_old_pipeline_efficiency_gene_count => ge['old_gtc_count']
        }
      end

      nil
    end

    def parse_raw_report

      raw_report.each do |report_row|

        ## Use the MiAttempt mouse_allele_type combined with the EsCell
        mouse_allele_symbol_superscript = if !report_row['mi_mouse_allele_type'].blank? && !report_row['allele_symbol_superscript_template'].blank?
          report_row['allele_symbol_superscript_template'].sub!(TargRep::EsCell::TEMPLATE_CHARACTER, report_row['mi_mouse_allele_type'])
        end

        unless mouse_allele_symbol_superscript.blank?
          report_row['allele_symbol'] = "#{report_row['gene']}<sup>#{mouse_allele_symbol_superscript}</sup>"
        end

        ## Use the PhenotypeAttempt mouse_allele_type combined with the EsCell (via PhenotypeAttempt -> MiAttempt -> TargRep::EsCell)
        ## allele_symbol_superscript in order to create the allele_symbol
        allowed_pa_statuses = ["Cre Excision Complete", "Phenotyping Started", "Phenotyping Complete"]

        phenotype_allele_symbol_superscript = if allowed_pa_statuses.include?(report_row['phenotype_attempt_status']) &&
                                                  !report_row['pa_mouse_allele_type'].blank? &&
                                                  !report_row['pa_allele_symbol_superscript_template'].blank?

          report_row['pa_allele_symbol_superscript_template'].sub!(TargRep::EsCell::TEMPLATE_CHARACTER, report_row['pa_mouse_allele_type'])
        end

        unless phenotype_allele_symbol_superscript.blank?
          report_row['allele_symbol'] = "#{report_row['gene']}<sup>#{phenotype_allele_symbol_superscript}</sup>"
        end

        ## If there's no mouse_allele_type on the MiAttempt use the EsCell's allele_symbol_superscript
        if report_row['allele_symbol'].blank? && !report_row['allele_symbol_superscript'].blank?
          report_row['allele_symbol'] = "#{report_row['gene']}<sup>#{report_row['allele_symbol_superscript']}</sup>"
        end

        ##
        ## If there's no direct link to an MiAttempt
        ## and the PhenotypeAttempt is not Cre-complete or better
        ## use EsCell's allele_symbol_superscript via PhenotypeAttempt's MI
        if report_row['allele_symbol'].blank? && !report_row['pa_allele_symbol_superscript'].blank?
          report_row['allele_symbol'] = "#{report_row['gene']}<sup>#{report_row['pa_allele_symbol_superscript']}</sup>"
        end

        if hash = @clone_efficiencies[report_row['mi_plan_id']]
          report_row['distinct_genotype_confirmed_es_cells']     = hash[:distinct_genotype_confirmed_es_cells]
          report_row['distinct_non_genotype_confirmed_es_cells'] = hash[:distinct_non_genotype_confirmed_es_cells]
          report_row['distinct_old_genotype_confirmed_es_cells'] = hash[:distinct_old_genotype_confirmed_es_cells]
          report_row['distinct_old_non_genotype_confirmed_es_cells'] = hash[:distinct_old_non_genotype_confirmed_es_cells]
        end

        if hash = @gene_efficiencies[report_row['mi_plan_id']]
          report_row['gc_pipeline_efficiency_gene_count']    = hash[:gc_pipeline_efficiency_gene_count]
          report_row['total_pipeline_efficiency_gene_count'] = hash[:total_pipeline_efficiency_gene_count]
          report_row['total_old_pipeline_efficiency_gene_count'] = hash[:total_old_pipeline_efficiency_gene_count]
          report_row['gc_old_pipeline_efficiency_gene_count']    = hash[:gc_old_pipeline_efficiency_gene_count]
        end

        report_row['distinct_genotype_confirmed_es_cells']         = report_row['distinct_genotype_confirmed_es_cells'].to_i
        report_row['distinct_old_non_genotype_confirmed_es_cells'] = report_row['distinct_old_non_genotype_confirmed_es_cells'].to_i
        report_row['distinct_old_genotype_confirmed_es_cells']     = report_row['distinct_old_genotype_confirmed_es_cells'].to_i
        report_row['distinct_old_non_genotype_confirmed_es_cells'] = report_row['distinct_old_non_genotype_confirmed_es_cells'].to_i
        report_row['gc_pipeline_efficiency_gene_count']            = report_row['gc_pipeline_efficiency_gene_count'].to_i
        report_row['total_pipeline_efficiency_gene_count']         = report_row['total_pipeline_efficiency_gene_count'].to_i
        report_row['total_old_pipeline_efficiency_gene_count']     = report_row['total_old_pipeline_efficiency_gene_count'].to_i
        report_row['gc_old_pipeline_efficiency_gene_count']        = report_row['gc_old_pipeline_efficiency_gene_count'].to_i

        report_row['created_at'] = Time.now.to_s(:db)

        report_row.delete('pa_mouse_allele_type')
        report_row.delete('pa_allele_symbol_superscript_template')
        report_row.delete('pa_mgi_allele_symbol_superscript')
        report_row.delete('mi_mouse_allele_type')
        report_row.delete('allele_symbol_superscript')
        report_row.delete('allele_symbol_superscript_template')

        @report_rows << report_row
      end

      true
    end

    def size
      @size ||= report_rows.size
    end

    def to_s
      "#<NewIntermediateReportSummaryByMiPlan::Generate size: #{size}>"
    end

    def insert_report
      begin
        sql =  <<-EOF
          BEGIN;

          TRUNCATE new_intermediate_report_summary_by_mi_plan;

          INSERT INTO new_intermediate_report_summary_by_mi_plan (#{self.class.columns.join(', ')}) VALUES
        EOF

        values = Array.new.tap do |v|
          report_rows.each do |report_row|
            v << "(#{self.class.row_for_sql(report_row)})"
          end
        end

        sql << values.join(",\n")

        return if values.empty?

        sql << "; COMMIT;"

        ActiveRecord::Base.connection.execute(sql)

        INTERMEDIATE_REPORT_LOG.info "[#{Time.now}] Report generation successful."
        puts "[#{Time.now}] Report generation successful."

      rescue => e
        puts "[#{Time.now}] ERROR"
        puts e.inspect
        puts e.backtrace.join("\n")

        INTERMEDIATE_REPORT_LOG.info "[#{Time.now}] ERROR - Report generation failed."
        INTERMEDIATE_REPORT_LOG.info e.inspect
        INTERMEDIATE_REPORT_LOG.info e.backtrace.join("\n")

        unless @retrying
          ActiveRecord::Base.connection.reconnect!
          @retrying = true

          puts "[#{Time.now}] Reconnecting database and retrying..."
          INTERMEDIATE_REPORT_LOG.info "[#{Time.now}] Reconnecting database and retrying..."

          retry
        end

        raise Tarmits::ReportGenerationFailed
      end

      nil
    end

    ##
    ## Class methods
    ##

    class << self

      def cache
        puts "[#{Time.now}] Report generation started."
        INTERMEDIATE_REPORT_LOG.info "[#{Time.now}] Report generation started."

        report = self.new
        report.insert_report
      end

      def row_for_sql(report_row)
        columns.map {|c| data_for_sql(c, report_row)}.join(', ')
      end

      def data_for_sql(column, report_row)

        data = report_row[column]

        if data.blank?
          data = 'NULL'
        elsif data.is_a?(String)
          data = "\'#{data}\'"
        end

        data
      end

      def report_sql
        <<-EOF
          -- get the best_mi_attempts per plan in a CTE using WITH
WITH best_mi_attempts AS (
            SELECT
              best_mi_attempts.id AS mi_attempts_id,
              mi_attempt_statuses.name AS mi_attempt_status,
              best_mi_attempts.mi_plan_id,
              best_mi_attempts.colony_name AS colony_name,
              targ_rep_es_cells.ikmc_project_id,
              targ_rep_mutation_types.name AS mutation_sub_type,
              targ_rep_es_cells.mgi_allele_symbol_superscript AS allele_symbol_superscript,
              targ_rep_es_cells.allele_symbol_superscript_template AS allele_symbol_superscript_template,
              best_mi_attempts.mouse_allele_type AS mi_mouse_allele_type,
              strains.name AS genetic_background,
              in_progress_stamps.created_at::date AS micro_injection_in_progress_date,
              chimearic_stamps.created_at::date   AS chimeras_obtained_date,
              gc_stamps.created_at::date          AS genotype_confirmed_date,
              aborted_stamps.created_at::date     AS micro_injection_aborted_date

            FROM (
              SELECT DISTINCT mi_attempts.*
              FROM mi_attempts
              JOIN (
                SELECT
                  best_attempts_for_plan_and_status.mi_plan_id,
                  best_attempts_for_plan_and_status.order_by,
                  first_value(best_attempts_for_plan_and_status.mi_attempt_id) OVER (PARTITION BY best_attempts_for_plan_and_status.mi_plan_id) AS mi_attempt_id
                FROM (
                  SELECT
                    mi_attempts.mi_plan_id,
                    mi_attempt_statuses.order_by,
                    mi_attempts.id as mi_attempt_id

                  FROM mi_attempts
                  JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
                  JOIN mi_attempt_status_stamps ON mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id AND mi_attempt_status_stamps.status_id = 1
                  ORDER BY
                    mi_attempts.mi_plan_id,
                    mi_attempt_statuses.order_by DESC,
                    mi_attempt_status_stamps.created_at ASC
                ) as best_attempts_for_plan_and_status
              ) AS att ON mi_attempts.id = att.mi_attempt_id

            ) best_mi_attempts

            JOIN targ_rep_es_cells ON targ_rep_es_cells.id = best_mi_attempts.es_cell_id
            JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
            JOIN mi_attempt_statuses ON mi_attempt_statuses.id = best_mi_attempts.status_id
            LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
            LEFT JOIN strains ON best_mi_attempts.colony_background_strain_id = strains.id
            LEFT JOIN mi_attempt_status_stamps AS in_progress_stamps ON in_progress_stamps.mi_attempt_id = best_mi_attempts.id AND in_progress_stamps.status_id = 1
            LEFT JOIN mi_attempt_status_stamps AS gc_stamps          ON gc_stamps.mi_attempt_id = best_mi_attempts.id          AND gc_stamps.status_id = 2
            LEFT JOIN mi_attempt_status_stamps AS aborted_stamps     ON aborted_stamps.mi_attempt_id = best_mi_attempts.id     AND aborted_stamps.status_id = 3
            LEFT JOIN mi_attempt_status_stamps AS chimearic_stamps   ON chimearic_stamps.mi_attempt_id = best_mi_attempts.id   AND chimearic_stamps.status_id = 4

            ORDER BY mi_plan_id
          ),


          -- get the best_overall_mouse allele modification per plan
          best_overall_mouse_allele_modification AS (
            SELECT
              best_mouse_allele_mods.id as mouse_allele_mod_id,
              best_mouse_allele_mods.mi_plan_id,
              best_mouse_allele_mods.mi_attempt_id,
              mouse_allele_mod_statuses.name AS mouse_allele_mod_status,
              mouse_allele_mod_statuses.order_by,
              best_mouse_allele_mods.colony_name AS colony_name,
              registered_statuses.created_at::date as phenotype_attempt_registered_date,
              re_started_statuses.created_at::date as rederivation_started_date,
              re_complete_statuses.created_at::date as rederivation_complete_date,
              cre_started_statuses.created_at::date as cre_excision_started_date,
              cre_complete_statuses.created_at::date as cre_excision_complete_date,
              aborted_statuses.created_at::date as phenotype_attempt_aborted_date,
              mi_attempts.colony_name AS pa_mi_attempt_colony_name,
              centres.name AS phenotyping_mi_attempt_production_centre,
              consortia.name AS phenotyping_mi_attempt_consortium,
              best_mouse_allele_mods.mouse_allele_type AS pa_mouse_allele_type,
              targ_rep_es_cells.allele_symbol_superscript_template AS pa_allele_symbol_superscript_template,
              targ_rep_es_cells.mgi_allele_symbol_superscript AS pa_allele_symbol_superscript

            FROM (

              SELECT DISTINCT mouse_allele_mods.*
              FROM mouse_allele_mods
              JOIN (
                SELECT
                  best_allele_mod_for_plan_and_status.mi_plan_id,
                  best_allele_mod_for_plan_and_status.order_by,
                  first_value(best_allele_mod_for_plan_and_status.mouse_allele_mod_id) OVER (PARTITION BY best_allele_mod_for_plan_and_status.mi_plan_id) AS mouse_allele_mod_id
                FROM (
                  SELECT
                    mouse_allele_mods.mi_plan_id,
                    mouse_allele_mod_statuses.order_by,
                    mouse_allele_mods.id as mouse_allele_mod_id
                    FROM mouse_allele_mods
                    JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
                    ORDER BY
                      mouse_allele_mods.mi_plan_id,
                      mouse_allele_mod_statuses.order_by DESC
                ) AS best_allele_mod_for_plan_and_status
              ) AS attempts_join ON mouse_allele_mods.id = attempts_join.mouse_allele_mod_id
            ) best_mouse_allele_mods

            LEFT JOIN mi_attempts ON best_mouse_allele_mods.mi_attempt_id = mi_attempts.id
            LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
            LEFT JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
            LEFT JOIN consortia ON consortia.id = mi_plans.consortium_id
            LEFT JOIN centres ON centres.id = mi_plans.production_centre_id
            JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = best_mouse_allele_mods.status_id
            LEFT JOIN mouse_allele_mod_status_stamps AS aborted_statuses ON aborted_statuses.mouse_allele_mod_id = best_mouse_allele_mods.id AND aborted_statuses.status_id = 7
            LEFT JOIN mouse_allele_mod_status_stamps AS registered_statuses ON registered_statuses.mouse_allele_mod_id = best_mouse_allele_mods.id AND registered_statuses.status_id = 1
            LEFT JOIN mouse_allele_mod_status_stamps AS re_started_statuses ON re_started_statuses.mouse_allele_mod_id = best_mouse_allele_mods.id AND re_started_statuses.status_id = 3
            LEFT JOIN mouse_allele_mod_status_stamps AS re_complete_statuses ON re_complete_statuses.mouse_allele_mod_id = best_mouse_allele_mods.id AND re_complete_statuses.status_id = 4
            LEFT JOIN mouse_allele_mod_status_stamps AS cre_started_statuses ON cre_started_statuses.mouse_allele_mod_id = best_mouse_allele_mods.id AND cre_started_statuses.status_id = 5
            LEFT JOIN mouse_allele_mod_status_stamps AS cre_complete_statuses ON cre_complete_statuses.mouse_allele_mod_id = best_mouse_allele_mods.id AND cre_complete_statuses.status_id = 6

            ORDER BY mi_plan_id
          ),


          -- get the best overall_phenotyping_production for each allele category
          best_overall_phenotyping_production_by_allele AS (
            SELECT
              best_phenotyping_production_by_allele.mi_plan_id,
              best_phenotyping_production_by_allele.colony_name AS colony_name,
              best_phenotyping_production_by_allele.id as phenotyping_production_id,
              phenotyping_production_statuses.name AS phenotyping_production_status,
              phenotyping_production_statuses.order_by,
              registered_statuses.created_at::date as phenotype_attempt_registered_date,
              started_statuses.created_at::date as phenotyping_started_date,
              best_phenotyping_production_by_allele.phenotyping_experiments_started::date as phenotyping_experiments_started_date,
              complete_statuses.created_at::date as phenotyping_complete_date,
              aborted_statuses.created_at::date as phenotype_attempt_aborted_date
            FROM (
              SELECT DISTINCT phenotyping_productions.*
              FROM phenotyping_productions
              JOIN (
                SELECT
                  phenotype_production_ordered_by_allele_and_status.mi_plan_id,
                  phenotype_production_ordered_by_allele_and_status.order_by,
                  first_value(phenotype_production_ordered_by_allele_and_status.phenotype_productions_id) OVER
                    (PARTITION BY phenotype_production_ordered_by_allele_and_status.mi_plan_id) AS phenotyping_production_id
                FROM (
                  SELECT
                    phenotyping_productions.mi_plan_id,
                    phenotyping_production_statuses.order_by,
                    phenotyping_productions.id as phenotype_productions_id
                  FROM phenotyping_productions
                    JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = phenotyping_productions.status_id
                    JOIN mouse_allele_mods ON mouse_allele_mods.id = phenotyping_productions.mouse_allele_mod_id
                  ORDER BY
                    phenotyping_productions.mi_plan_id,
                    phenotyping_production_statuses.order_by DESC
                ) AS phenotype_production_ordered_by_allele_and_status
              ) AS production_join ON phenotyping_productions.id = production_join.phenotyping_production_id
            ) AS best_phenotyping_production_by_allele

            JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = best_phenotyping_production_by_allele.status_id
            LEFT JOIN phenotyping_production_status_stamps AS aborted_statuses ON aborted_statuses.phenotyping_production_id = best_phenotyping_production_by_allele.id AND aborted_statuses.status_id = 5
            LEFT JOIN phenotyping_production_status_stamps AS registered_statuses ON registered_statuses.phenotyping_production_id = best_phenotyping_production_by_allele.id AND registered_statuses.status_id = 1
            LEFT JOIN phenotyping_production_status_stamps AS started_statuses ON started_statuses.phenotyping_production_id = best_phenotyping_production_by_allele.id AND started_statuses.status_id = 3
            LEFT JOIN phenotyping_production_status_stamps AS complete_statuses ON complete_statuses.phenotyping_production_id = best_phenotyping_production_by_allele.id AND complete_statuses.status_id = 4

            ORDER BY mi_plan_id
          ),


          -- get the best_mouse allele modification per plan
          best_mouse_allele_modification AS (
            SELECT
              best_mouse_allele_mods.id as mouse_allele_mod_id,
              best_mouse_allele_mods.mi_plan_id,
              best_mouse_allele_mods.allele_category,
              best_mouse_allele_mods.mi_attempt_id,
              mouse_allele_mod_statuses.name AS mouse_allele_mod_status,
              mouse_allele_mod_statuses.order_by,
              best_mouse_allele_mods.colony_name AS phenotype_attempt_colony_name,
              registered_statuses.created_at::date as phenotype_attempt_registered_date,
              re_started_statuses.created_at::date as rederivation_started_date,
              re_complete_statuses.created_at::date as rederivation_complete_date,
              cre_started_statuses.created_at::date as cre_excision_started_date,
              cre_complete_statuses.created_at::date as cre_excision_complete_date,
              aborted_statuses.created_at::date as phenotype_attempt_aborted_date,
              mi_attempts.colony_name AS pa_mi_attempt_colony_name,
              centres.name AS phenotyping_mi_attempt_production_centre,
              consortia.name AS phenotyping_mi_attempt_consortium,
              best_mouse_allele_mods.mouse_allele_type AS pa_mouse_allele_type,
              targ_rep_es_cells.allele_symbol_superscript_template AS pa_allele_symbol_superscript_template,
              targ_rep_es_cells.mgi_allele_symbol_superscript AS pa_allele_symbol_superscript

            FROM (

              SELECT DISTINCT mouse_allele_mods.*
              FROM mouse_allele_mods
              JOIN (
                SELECT
                  best_allele_mod_for_plan_and_status.mi_plan_id,
                  best_allele_mod_for_plan_and_status.order_by,
                  first_value(best_allele_mod_for_plan_and_status.mouse_allele_mod_id) OVER (PARTITION BY best_allele_mod_for_plan_and_status.mi_plan_id, best_allele_mod_for_plan_and_status.allele_category) AS mouse_allele_mod_id
                FROM (
                  SELECT
                    mouse_allele_mods.mi_plan_id,
                    mouse_allele_mods.allele_category,
                    mouse_allele_mod_statuses.order_by,
                    mouse_allele_mods.id as mouse_allele_mod_id
                    FROM mouse_allele_mods
                    JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
                    ORDER BY
                      mouse_allele_mods.mi_plan_id,
                      mouse_allele_mods.allele_category,
                      mouse_allele_mod_statuses.order_by DESC
                ) AS best_allele_mod_for_plan_and_status
              ) AS attempts_join ON mouse_allele_mods.id = attempts_join.mouse_allele_mod_id
            ) best_mouse_allele_mods

            LEFT JOIN mi_attempts ON best_mouse_allele_mods.mi_attempt_id = mi_attempts.id
            LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
            LEFT JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
            LEFT JOIN consortia ON consortia.id = mi_plans.consortium_id
            LEFT JOIN centres ON centres.id = mi_plans.production_centre_id
            JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = best_mouse_allele_mods.status_id
            LEFT JOIN mouse_allele_mod_status_stamps AS aborted_statuses ON aborted_statuses.mouse_allele_mod_id = best_mouse_allele_mods.id AND aborted_statuses.status_id = 7
            LEFT JOIN mouse_allele_mod_status_stamps AS registered_statuses ON registered_statuses.mouse_allele_mod_id = best_mouse_allele_mods.id AND registered_statuses.status_id = 1
            LEFT JOIN mouse_allele_mod_status_stamps AS re_started_statuses ON re_started_statuses.mouse_allele_mod_id = best_mouse_allele_mods.id AND re_started_statuses.status_id = 3
            LEFT JOIN mouse_allele_mod_status_stamps AS re_complete_statuses ON re_complete_statuses.mouse_allele_mod_id = best_mouse_allele_mods.id AND re_complete_statuses.status_id = 4
            LEFT JOIN mouse_allele_mod_status_stamps AS cre_started_statuses ON cre_started_statuses.mouse_allele_mod_id = best_mouse_allele_mods.id AND cre_started_statuses.status_id = 5
            LEFT JOIN mouse_allele_mod_status_stamps AS cre_complete_statuses ON cre_complete_statuses.mouse_allele_mod_id = best_mouse_allele_mods.id AND cre_complete_statuses.status_id = 6

            ORDER BY mi_plan_id
          ),

          -- get the best mouse allele mod for tm1a
          best_mouse_allele_mod_for_tm1a AS (
            SELECT best_mouse_allele_modification.*
            FROM best_mouse_allele_modification
            WHERE allele_category = 'tm1a'
           ),

          -- get the best mouse alelle mod for tm1b
          best_mouse_allele_mod_for_tm1b AS (
            SELECT best_mouse_allele_modification.*
            FROM best_mouse_allele_modification
            WHERE allele_category = 'tm1b'
           ),

          -- get the best phenotyping_production for each allele category
          phenotyping_production_by_allele AS (
            SELECT
              best_phenotyping_production_by_allele.mi_plan_id,
              best_phenotyping_production_by_allele.allele_category AS allele_category,
              best_phenotyping_production_by_allele.colony_name AS phenotype_attempt_colony_name,
              best_phenotyping_production_by_allele.id as phenotyping_production_id,
              phenotyping_production_statuses.name AS phenotyping_production_status,
              phenotyping_production_statuses.order_by,
              registered_statuses.created_at::date as phenotype_attempt_registered_date,
              started_statuses.created_at::date as phenotyping_started_date,
              best_phenotyping_production_by_allele.phenotyping_experiments_started::date as phenotyping_experiments_started_date,
              complete_statuses.created_at::date as phenotyping_complete_date,
              aborted_statuses.created_at::date as phenotype_attempt_aborted_date
            FROM (
              SELECT DISTINCT phenotyping_productions.*, production_join.allele_category
              FROM phenotyping_productions
              JOIN (
                SELECT
                  phenotype_production_ordered_by_allele_and_status.mi_plan_id,
                  phenotype_production_ordered_by_allele_and_status.allele_category,
                  phenotype_production_ordered_by_allele_and_status.order_by,
                  first_value(phenotype_production_ordered_by_allele_and_status.phenotype_productions_id) OVER
                    (PARTITION BY phenotype_production_ordered_by_allele_and_status.mi_plan_id, phenotype_production_ordered_by_allele_and_status.allele_category) AS phenotyping_production_id
                FROM (
                  SELECT
                    phenotyping_productions.mi_plan_id,
                    mouse_allele_mods.allele_category,
                    phenotyping_production_statuses.order_by,
                    phenotyping_productions.id as phenotype_productions_id
                  FROM phenotyping_productions
                    JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = phenotyping_productions.status_id
                    JOIN mouse_allele_mods ON mouse_allele_mods.id = phenotyping_productions.mouse_allele_mod_id
                  ORDER BY
                    phenotyping_productions.mi_plan_id,
                    mouse_allele_mods.allele_category,
                    phenotyping_production_statuses.order_by DESC
                ) AS phenotype_production_ordered_by_allele_and_status
              ) AS production_join ON phenotyping_productions.id = production_join.phenotyping_production_id
            ) AS best_phenotyping_production_by_allele

            JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = best_phenotyping_production_by_allele.status_id
            LEFT JOIN phenotyping_production_status_stamps AS aborted_statuses ON aborted_statuses.phenotyping_production_id = best_phenotyping_production_by_allele.id AND aborted_statuses.status_id = 5
            LEFT JOIN phenotyping_production_status_stamps AS registered_statuses ON registered_statuses.phenotyping_production_id = best_phenotyping_production_by_allele.id AND registered_statuses.status_id = 1
            LEFT JOIN phenotyping_production_status_stamps AS started_statuses ON started_statuses.phenotyping_production_id = best_phenotyping_production_by_allele.id AND started_statuses.status_id = 3
            LEFT JOIN phenotyping_production_status_stamps AS complete_statuses ON complete_statuses.phenotyping_production_id = best_phenotyping_production_by_allele.id AND complete_statuses.status_id = 4

            ORDER BY mi_plan_id
          ),

          -- get the best phenotyping_production for tm1a
          best_phenotyping_production_for_tm1a AS (
            SELECT phenotyping_production_by_allele.*
            FROM phenotyping_production_by_allele
            WHERE allele_category = 'tm1a'
           ),

          -- get the best phenotyping_production for tm1b
          best_phenotyping_production_for_tm1b AS (
            SELECT phenotyping_production_by_allele.*
            FROM phenotyping_production_by_allele
            WHERE allele_category = 'tm1b'
           )

          -- build intermediate report


          SELECT
            mi_plans.id AS mi_plan_id,
            CASE
              WHEN best_overall_phenotyping_production_by_allele.phenotyping_production_status = 'Phenotype Production Aborted' AND (best_overall_mouse_allele_modification.mouse_allele_mod_status IS NULL OR best_overall_mouse_allele_modification.mouse_allele_mod_status = 'Mouse Allele Modification Aborted')
                THEN 'Phenotype Attempt Aborted'
              WHEN best_overall_phenotyping_production_by_allele.phenotyping_production_status IS NOT NULL AND (best_overall_mouse_allele_modification.mouse_allele_mod_status IS NULL OR best_overall_phenotyping_production_by_allele.order_by > best_overall_mouse_allele_modification.order_by)
                THEN best_overall_phenotyping_production_by_allele.phenotyping_production_status
              WHEN best_overall_mouse_allele_modification.mouse_allele_mod_status = 'Mouse Allele Modification Aborted'
                THEN 'Phenotype Attempt Aborted'
              WHEN best_overall_mouse_allele_modification.mouse_allele_mod_status IS NOT NULL
                THEN best_overall_mouse_allele_modification.mouse_allele_mod_status
              WHEN best_mi_attempts.mi_attempt_status IS NOT NULL
                THEN best_mi_attempts.mi_attempt_status
              WHEN mi_plan_statuses.name IS NOT NULL
                THEN mi_plan_statuses.name
              ELSE
                NULL
            END AS overall_status,

            mi_plan_statuses.name AS mi_plan_status,
            best_mi_attempts.mi_attempt_status,

            CASE
              WHEN best_overall_phenotyping_production_by_allele.phenotyping_production_status = 'Phenotype Production Aborted' AND (best_overall_mouse_allele_modification.mouse_allele_mod_status IS NULL OR best_overall_mouse_allele_modification.mouse_allele_mod_status = 'Mouse Allele Modification Aborted')
                THEN 'Phenotype Attempt Aborted'
              WHEN best_overall_phenotyping_production_by_allele.phenotyping_production_status IS NOT NULL AND (best_overall_mouse_allele_modification.mouse_allele_mod_status IS NULL OR best_overall_phenotyping_production_by_allele.order_by > best_overall_mouse_allele_modification.order_by)
                THEN best_overall_phenotyping_production_by_allele.phenotyping_production_status
              WHEN best_overall_mouse_allele_modification.mouse_allele_mod_status = 'Mouse Allele Modification Aborted'
                THEN 'Phenotype Attempt Aborted'
              ELSE best_overall_mouse_allele_modification.mouse_allele_mod_status
            END AS phenotype_attempt_status,

            consortia.name AS consortium,
            mi_plan_sub_projects.name AS sub_project,
            mi_plan_priorities.name AS priority,
            centres.name AS production_centre,
            genes.marker_symbol AS gene,
            genes.mgi_accession_id,
            mi_plans.is_bespoke_allele,
            best_mi_attempts.ikmc_project_id,
            best_mi_attempts.mutation_sub_type,
            best_mi_attempts.allele_symbol_superscript,
            best_mi_attempts.allele_symbol_superscript_template,
            best_mi_attempts.mi_mouse_allele_type,
            best_mi_attempts.genetic_background,
            best_mi_attempts.colony_name AS mi_attempt_colony_name,
            best_overall_mouse_allele_modification.colony_name AS mouse_allele_mod_colony_name,
            best_overall_phenotyping_production_by_allele.colony_name AS production_colony_name,
            assigned_stamps.created_at::date AS assigned_date,
            in_progress_stamps.created_at::date AS assigned_es_cell_qc_in_progress_date,
            complete_stamps.created_at::date AS assigned_es_cell_qc_complete_date,
            aborted_stamps.created_at::date AS aborted_es_cell_qc_failed_date,

            CASE
              WHEN best_overall_mouse_allele_modification.phenotype_attempt_registered_date IS NULL AND best_overall_phenotyping_production_by_allele.phenotype_attempt_aborted_date IS NOT NULL
                THEN best_overall_phenotyping_production_by_allele.phenotype_attempt_aborted_date
              ELSE best_overall_mouse_allele_modification.phenotype_attempt_aborted_date
            END AS micro_injection_aborted_date,

            best_mi_attempts.micro_injection_in_progress_date AS micro_injection_in_progress_date,
            best_mi_attempts.chimeras_obtained_date AS chimeras_obtained_date,
            best_mi_attempts.genotype_confirmed_date AS genotype_confirmed_date,
            best_overall_mouse_allele_modification.phenotyping_mi_attempt_production_centre AS phenotyping_mi_attempt_production_centre,
            best_overall_mouse_allele_modification.phenotyping_mi_attempt_consortium AS phenotyping_mi_attempt_consortium,
            best_overall_mouse_allele_modification.phenotype_attempt_registered_date AS phenotype_attempt_registered_date,
            best_overall_mouse_allele_modification.rederivation_started_date AS rederivation_started_date,
            best_overall_mouse_allele_modification.rederivation_complete_date AS rederivation_complete_date,
            best_overall_mouse_allele_modification.cre_excision_started_date AS cre_excision_started_date,
            best_overall_mouse_allele_modification.cre_excision_complete_date AS cre_excision_complete_date,
            best_overall_phenotyping_production_by_allele.phenotyping_started_date AS phenotyping_started_date,
            best_overall_phenotyping_production_by_allele.phenotyping_complete_date AS phenotyping_complete_date,
            best_overall_phenotyping_production_by_allele.phenotype_attempt_aborted_date AS phenotype_attempt_aborted_date,
            best_overall_phenotyping_production_by_allele.phenotyping_experiments_started_date AS phenotyping_experiments_started_date,

            CASE
              WHEN best_phenotyping_production_for_tm1b.phenotyping_production_status = 'Phenotype Production Aborted' AND (best_mouse_allele_mod_for_tm1b.mouse_allele_mod_status IS NULL OR best_mouse_allele_mod_for_tm1b.mouse_allele_mod_status = 'Mouse Allele Modification Aborted')
                THEN 'Phenotype Attempt Aborted'
              WHEN best_phenotyping_production_for_tm1b.phenotyping_production_status IS NOT NULL AND (best_mouse_allele_mod_for_tm1b.mouse_allele_mod_status IS NULL OR best_phenotyping_production_for_tm1b.order_by > best_mouse_allele_mod_for_tm1b.order_by)
                THEN best_phenotyping_production_for_tm1b.phenotyping_production_status
              WHEN best_mouse_allele_mod_for_tm1b.mouse_allele_mod_status = 'Mouse Allele Modification Aborted'
                THEN 'Phenotype Attempt Aborted'
              ELSE best_mouse_allele_mod_for_tm1b.mouse_allele_mod_status
            END AS tm1b_phenotype_attempt_status,

            best_mouse_allele_mod_for_tm1b.phenotype_attempt_registered_date AS tm1b_phenotype_attempt_registered_date,
            best_mouse_allele_mod_for_tm1b.rederivation_started_date AS tm1b_rederivation_started_date,
            best_mouse_allele_mod_for_tm1b.rederivation_complete_date AS tm1b_rederivation_complete_date,
            best_mouse_allele_mod_for_tm1b.cre_excision_started_date AS tm1b_cre_excision_started_date,
            best_mouse_allele_mod_for_tm1b.cre_excision_complete_date AS tm1b_cre_excision_complete_date,
            best_phenotyping_production_for_tm1b.phenotyping_experiments_started_date AS tm1b_phenotyping_experiments_started_date,
            best_phenotyping_production_for_tm1b.phenotyping_started_date AS tm1b_phenotyping_started_date,
            best_phenotyping_production_for_tm1b.phenotyping_complete_date AS tm1b_phenotyping_complete_date,

            CASE
              WHEN best_mouse_allele_mod_for_tm1b.phenotype_attempt_registered_date IS NULL AND best_phenotyping_production_for_tm1b.phenotype_attempt_aborted_date IS NOT NULL
                THEN best_phenotyping_production_for_tm1b.phenotype_attempt_aborted_date
              ELSE best_mouse_allele_mod_for_tm1b.phenotype_attempt_aborted_date
            END AS tm1b_phenotype_attempt_aborted_date,

            best_mouse_allele_mod_for_tm1b.phenotype_attempt_colony_name AS tm1b_colony_name,
            best_phenotyping_production_for_tm1b.phenotype_attempt_colony_name AS tm1b_phenotyping_production_colony_name,
            best_mouse_allele_mod_for_tm1b.phenotyping_mi_attempt_production_centre AS tm1b_phenotyping_mi_attempt_production_centre,
            best_mouse_allele_mod_for_tm1b.phenotyping_mi_attempt_consortium AS tm1b_phenotyping_mi_attempt_consortium,

            CASE
              WHEN best_phenotyping_production_for_tm1a.phenotyping_production_status = 'Phenotype Production Aborted' AND (best_mouse_allele_mod_for_tm1a.mouse_allele_mod_status IS NULL OR best_mouse_allele_mod_for_tm1a.mouse_allele_mod_status = 'Mouse Allele Modification Aborted')
                THEN 'Phenotype Attempt Aborted'
              WHEN best_phenotyping_production_for_tm1a.phenotyping_production_status IS NOT NULL AND (best_mouse_allele_mod_for_tm1a.mouse_allele_mod_status IS NULL OR best_phenotyping_production_for_tm1a.order_by > best_mouse_allele_mod_for_tm1a.order_by)
                THEN best_phenotyping_production_for_tm1a.phenotyping_production_status
              WHEN best_mouse_allele_mod_for_tm1a.mouse_allele_mod_status = 'Mouse Allele Modification Aborted'
                THEN 'Phenotype Attempt Aborted'
              ELSE best_mouse_allele_mod_for_tm1a.mouse_allele_mod_status
            END AS tm1a_phenotype_attempt_status,

            best_mouse_allele_mod_for_tm1a.phenotype_attempt_registered_date AS tm1a_phenotype_attempt_registered_date,
            best_mouse_allele_mod_for_tm1a.rederivation_started_date AS tm1a_rederivation_started_date,
            best_mouse_allele_mod_for_tm1a.rederivation_complete_date AS tm1a_rederivation_complete_date,
            best_mouse_allele_mod_for_tm1a.cre_excision_started_date AS tm1a_cre_excision_started_date,
            best_mouse_allele_mod_for_tm1a.cre_excision_complete_date AS tm1a_cre_excision_complete_date,
            best_phenotyping_production_for_tm1a.phenotyping_started_date AS tm1a_phenotyping_started_date,
            best_phenotyping_production_for_tm1a.phenotyping_experiments_started_date AS tm1a_phenotyping_experiments_started_date,
            best_phenotyping_production_for_tm1a.phenotyping_complete_date AS tm1a_phenotyping_complete_date,

            CASE
              WHEN best_mouse_allele_mod_for_tm1a.phenotype_attempt_registered_date IS NULL AND best_phenotyping_production_for_tm1a.phenotype_attempt_aborted_date IS NOT NULL
                THEN best_phenotyping_production_for_tm1a.phenotype_attempt_aborted_date
              ELSE best_mouse_allele_mod_for_tm1a.phenotype_attempt_aborted_date
            END AS tm1a_phenotype_attempt_aborted_date,

            best_mouse_allele_mod_for_tm1a.phenotype_attempt_colony_name AS tm1a_colony_name,
            best_phenotyping_production_for_tm1a.phenotype_attempt_colony_name AS tm1a_phenotyping_production_colony_name,
            best_mouse_allele_mod_for_tm1a.phenotyping_mi_attempt_production_centre AS tm1a_phenotyping_mi_attempt_production_centre,
            best_mouse_allele_mod_for_tm1a.phenotyping_mi_attempt_consortium AS tm1a_phenotyping_mi_attempt_consortium

          FROM mi_plans
            JOIN consortia ON consortia.id = mi_plans.consortium_id
            JOIN mi_plan_sub_projects ON mi_plan_sub_projects.id = mi_plans.sub_project_id
            JOIN mi_plan_priorities ON mi_plan_priorities.id = mi_plans.priority_id
            JOIN genes ON genes.id = mi_plans.gene_id
            JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plans.status_id
            LEFT JOIN centres ON centres.id = mi_plans.production_centre_id
            LEFT JOIN mi_plan_status_stamps AS assigned_stamps    ON assigned_stamps.mi_plan_id = mi_plans.id AND assigned_stamps.status_id = 1
            LEFT JOIN mi_plan_status_stamps AS in_progress_stamps ON in_progress_stamps.mi_plan_id = mi_plans.id AND in_progress_stamps.status_id = 8
            LEFT JOIN mi_plan_status_stamps AS complete_stamps    ON complete_stamps.mi_plan_id = mi_plans.id AND complete_stamps.status_id = 9
            LEFT JOIN mi_plan_status_stamps AS aborted_stamps     ON aborted_stamps.mi_plan_id  = mi_plans.id AND aborted_stamps.status_id = 10
            LEFT JOIN best_mi_attempts ON best_mi_attempts.mi_plan_id = mi_plans.id
            LEFT JOIN best_overall_mouse_allele_modification ON best_overall_mouse_allele_modification.mi_plan_id = mi_plans.id
            LEFT JOIN best_overall_phenotyping_production_by_allele ON best_overall_phenotyping_production_by_allele.mi_plan_id = mi_plans.id
            LEFT JOIN best_phenotyping_production_for_tm1b ON best_phenotyping_production_for_tm1b.mi_plan_id = mi_plans.id
            LEFT JOIN best_phenotyping_production_for_tm1a ON best_phenotyping_production_for_tm1a.mi_plan_id = mi_plans.id
            LEFT JOIN best_mouse_allele_mod_for_tm1a ON best_mouse_allele_mod_for_tm1a.mi_plan_id = mi_plans.id
            LEFT JOIN best_mouse_allele_mod_for_tm1b ON best_mouse_allele_mod_for_tm1b.mi_plan_id = mi_plans.id

          ORDER BY mi_plans.id
        EOF
      end

      def clone_efficiency_sql
        <<-EOF
          SELECT
            mi_plans.id AS mi_plan_id,

            SUM(CASE
              WHEN mi_attempts.status_id = 2 AND mi_attempt_status_stamps.created_at < '#{6.months.ago.to_s(:db)}'
              THEN 1 ELSE 0
            END) AS gtc_old_count,

            SUM(CASE
              WHEN mi_attempts.status_id != 2 AND mi_attempt_status_stamps.created_at < '#{6.months.ago.to_s(:db)}'
              THEN 1 ELSE 0
            END) AS old_non_gtc_count,

            SUM(CASE
              WHEN mi_attempts.status_id = 2
              THEN 1 ELSE 0
            END) AS gtc_count,

            SUM(CASE
              WHEN mi_attempts.status_id != 2
              THEN 1 ELSE 0
            END) AS non_gtc_count

          FROM targ_rep_es_cells

          JOIN mi_attempts ON targ_rep_es_cells.id = mi_attempts.es_cell_id
          JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
          JOIN consortia ON consortia.id = mi_plans.consortium_id
          JOIN mi_attempt_status_stamps ON mi_attempts.id = mi_attempt_status_stamps.mi_attempt_id AND mi_attempt_status_stamps.status_id = 1
          LEFT JOIN centres ON centres.id = mi_plans.production_centre_id

          GROUP BY mi_plans.id
        EOF
      end

      def gene_efficiency_sql
        <<-EOF
          WITH counts AS (
            SELECT
              genes.id AS gene_id,
              mi_plans.id AS mi_plan_id,

              SUM(CASE
                WHEN mi_attempts.status_id = 2 AND mi_attempt_status_stamps.created_at < '#{6.months.ago.to_s(:db)}'
                THEN 1 ELSE 0
              END) AS old_gtc_count,

              SUM(CASE
                WHEN mi_attempt_status_stamps.created_at < '#{6.months.ago.to_s(:db)}'
                THEN 1 ELSE 0
              END) AS old_total_count,

              SUM(CASE
                WHEN mi_attempts.status_id = 2
                THEN 1 ELSE 0
              END) AS gtc_count,

              COUNT(*) AS total_count

            FROM genes

            JOIN targ_rep_alleles ON genes.id = targ_rep_alleles.gene_id
            JOIN targ_rep_es_cells ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
            JOIN mi_attempts ON targ_rep_es_cells.id = mi_attempts.es_cell_id
            JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
            JOIN consortia ON consortia.id = mi_plans.consortium_id
            JOIN mi_attempt_status_stamps ON mi_attempts.id = mi_attempt_status_stamps.mi_attempt_id AND mi_attempt_status_stamps.status_id = 1
            LEFT JOIN centres ON centres.id = mi_plans.production_centre_id

            GROUP BY genes.id, mi_plans.id
            ORDER BY mi_plans.id asc
          )

          SELECT
            gene_id,
            mi_plan_id,
            SUM(case when old_gtc_count > 0 then 1 else 0 end) AS old_gtc_count,
            SUM(case when old_total_count > 0 then 1 else 0 end) AS old_total_count,
            SUM(case when gtc_count > 0 then 1 else 0 end) AS gtc_count,
            SUM(case when total_count > 0 then 1 else 0 end) AS total_count

          FROM counts
          GROUP BY gene_id, mi_plan_id
        EOF
      end

      def columns
        [ 'mi_plan_id',                               # ids
          'overall_status',                           #statuses
          'mi_plan_status',
          'mi_attempt_status',
          'phenotype_attempt_status',
          'consortium',                               # plan data
          'production_centre',
          'sub_project',
          'priority',
          'gene',
          'mgi_accession_id',
          'is_bespoke_allele',
          'ikmc_project_id',                          # es_cell data
          'mutation_sub_type',
          'allele_symbol',
          'genetic_background',
          'mi_attempt_colony_name',                   # colonies
          'mouse_allele_mod_colony_name',
          'production_colony_name',
          'assigned_date',                            # mi_plan statuses
          'assigned_es_cell_qc_in_progress_date',
          'assigned_es_cell_qc_complete_date',
          'aborted_es_cell_qc_failed_date',
          'micro_injection_aborted_date',             # mi_attempt_statuses
          'micro_injection_in_progress_date',
          'chimeras_obtained_date',
          'genotype_confirmed_date',
          'phenotype_attempt_registered_date',        # phenotype_attempt_statuses
          'rederivation_started_date',
          'rederivation_complete_date',
          'cre_excision_started_date',
          'cre_excision_complete_date',
          'phenotyping_started_date',
          'phenotyping_complete_date',
          'phenotype_attempt_aborted_date',
          'phenotyping_mi_attempt_production_centre',
          'phenotyping_mi_attempt_consortium',
          'phenotyping_experiments_started_date',
          'tm1b_phenotype_attempt_status',            # tm1b statuses
          'tm1b_phenotype_attempt_registered_date',
          'tm1b_rederivation_started_date',
          'tm1b_rederivation_complete_date',
          'tm1b_cre_excision_started_date',
          'tm1b_cre_excision_complete_date',
          'tm1b_phenotyping_started_date',
          'tm1b_phenotyping_experiments_started_date',
          'tm1b_phenotyping_complete_date',
          'tm1b_phenotype_attempt_aborted_date',
          'tm1b_colony_name',                         # tm1b colonies
          'tm1b_phenotyping_production_colony_name',
          'tm1b_phenotyping_mi_attempt_production_centre',
          'tm1b_phenotyping_mi_attempt_consortium',
          'tm1a_phenotype_attempt_status',            # tm1a statuses
          'tm1a_phenotype_attempt_registered_date',
          'tm1a_rederivation_started_date',
          'tm1a_rederivation_complete_date',
          'tm1a_cre_excision_started_date',
          'tm1a_cre_excision_complete_date',
          'tm1a_phenotyping_started_date',
          'tm1a_phenotyping_experiments_started_date',
          'tm1a_phenotyping_complete_date',
          'tm1a_phenotype_attempt_aborted_date',
          'tm1a_colony_name',                         # tm1a colonies
          'tm1a_phenotyping_production_colony_name',
          'tm1a_phenotyping_mi_attempt_production_centre',
          'tm1a_phenotyping_mi_attempt_consortium',
          'total_pipeline_efficiency_gene_count',     # efficiencies
          'gc_pipeline_efficiency_gene_count',
          'total_old_pipeline_efficiency_gene_count',
          'gc_old_pipeline_efficiency_gene_count',
          'distinct_genotype_confirmed_es_cells',     # distinct
          'distinct_non_genotype_confirmed_es_cells',
          'distinct_old_genotype_confirmed_es_cells',
          'distinct_old_non_genotype_confirmed_es_cells',
          'created_at'                                # created date
        ]
      end
    end
  end
end
