module NewGeneIntermediateReport::ReportGenerator
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

        @clone_efficiencies[{'gene' => ce['gene_id'], 'consortium' => ce['consortium_id'], 'production_centre' => ce['production_centre_id'] }] = {
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
        @gene_efficiencies[{'gene' => ge['gene_id'], 'consortium' => ge['consortium_id'], 'production_centre' => ge['production_centre_id'] }] = {
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

        if hash = @clone_efficiencies[{'gene' => report_row['gene_id'],'consortium' => report_row['consortium_id'], 'production_centre' => report_row['production_centre_id']}]
          report_row['distinct_genotype_confirmed_es_cells']     = hash[:distinct_genotype_confirmed_es_cells]
          report_row['distinct_non_genotype_confirmed_es_cells'] = hash[:distinct_non_genotype_confirmed_es_cells]
          report_row['distinct_old_genotype_confirmed_es_cells'] = hash[:distinct_old_genotype_confirmed_es_cells]
          report_row['distinct_old_non_genotype_confirmed_es_cells'] = hash[:distinct_old_non_genotype_confirmed_es_cells]
        end

        if hash = @gene_efficiencies[{'gene' => report_row['gene_id'],'consortium' => report_row['consortium_id'], 'production_centre' => report_row['production_centre_id']}]
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
      "#<NewGeneIntermediateReport::Generate size: #{size}>"
    end

    def insert_report
      begin
        sql =  <<-EOF
          BEGIN;

          TRUNCATE new_gene_intermediate_report;

          INSERT INTO new_gene_intermediate_report (#{self.class.columns.join(', ')}) VALUES
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
              mi_plans.gene_id AS gene_id,
              mi_plans.consortium_id AS consortium_id,
              mi_plans.production_centre_id AS production_centre_id,
              best_mi_attempts.colony_name AS mi_attempt_colony_name,
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
                  best_attempts_for_gene_consortia_centre_and_status.gene_id,
                  best_attempts_for_gene_consortia_centre_and_status.consortium_id,
                  best_attempts_for_gene_consortia_centre_and_status.production_centre_id,
                  best_attempts_for_gene_consortia_centre_and_status.order_by,
                  first_value(best_attempts_for_gene_consortia_centre_and_status.mi_attempt_id) OVER (PARTITION BY best_attempts_for_gene_consortia_centre_and_status.gene_id, best_attempts_for_gene_consortia_centre_and_status.consortium_id, best_attempts_for_gene_consortia_centre_and_status.production_centre_id) AS mi_attempt_id
                FROM (
                  SELECT
                    mi_plans.gene_id,
                    mi_plans.consortium_id,
                    mi_plans.production_centre_id,
                    mi_attempt_statuses.order_by,
                    mi_attempts.id as mi_attempt_id
                  FROM mi_plans
                  JOIN mi_attempts ON mi_plans.id = mi_attempts.mi_plan_id
                  JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
                  JOIN mi_attempt_status_stamps ON mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id AND mi_attempt_status_stamps.status_id = 1
                  ORDER BY
                    mi_plans.gene_id,
                    mi_plans.consortium_id,
                    mi_plans.production_centre_id,
                    mi_attempt_statuses.order_by DESC,
                    mi_attempt_status_stamps.created_at ASC
                ) as best_attempts_for_gene_consortia_centre_and_status
              ) AS att ON mi_attempts.id = att.mi_attempt_id
            ) best_mi_attempts

            JOIN targ_rep_es_cells ON targ_rep_es_cells.id = best_mi_attempts.es_cell_id
            JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
            JOIN mi_plans ON mi_plans.id = best_mi_attempts.mi_plan_id
            JOIN mi_attempt_statuses ON mi_attempt_statuses.id = best_mi_attempts.status_id
            LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
            LEFT JOIN strains ON best_mi_attempts.colony_background_strain_id = strains.id
            LEFT JOIN mi_attempt_status_stamps AS in_progress_stamps ON in_progress_stamps.mi_attempt_id = best_mi_attempts.id AND in_progress_stamps.status_id = 1
            LEFT JOIN mi_attempt_status_stamps AS gc_stamps          ON gc_stamps.mi_attempt_id = best_mi_attempts.id          AND gc_stamps.status_id = 2
            LEFT JOIN mi_attempt_status_stamps AS aborted_stamps     ON aborted_stamps.mi_attempt_id = best_mi_attempts.id     AND aborted_stamps.status_id = 3
            LEFT JOIN mi_attempt_status_stamps AS chimearic_stamps   ON chimearic_stamps.mi_attempt_id = best_mi_attempts.id   AND chimearic_stamps.status_id = 4

            ORDER BY mi_plan_id
          ),


          -- get the best_phenotype_attempts per plan in a CTE using WITH
          best_phenotype_attempts AS (
            SELECT
              best_phenotype_attempts.colony_name AS phenotype_attempt_colony_name,
              best_phenotype_attempts.id as phenotype_attempt_id,
              phenotype_attempt_statuses.name AS phenotype_attempt_status,
              best_phenotype_attempts.mi_plan_id,
              mi_plans.gene_id AS gene_id,
              mi_plans.consortium_id AS consortium_id,
              mi_plans.production_centre_id AS production_centre_id,
              mi_attempts.colony_name AS pa_mi_attempt_colony_name,
              centres.name AS pa_mi_attempt_production_centre,
              consortia.name AS pa_mi_attempt_consortium,
              registered_statuses.created_at::date as phenotype_attempt_registered_date,
              re_started_statuses.created_at::date as rederivation_started_date,
              re_complete_statuses.created_at::date as rederivation_complete_date,
              cre_started_statuses.created_at::date as cre_excision_started_date,
              cre_complete_statuses.created_at::date as cre_excision_complete_date,
              started_statuses.created_at::date as phenotyping_started_date,
              complete_statuses.created_at::date as phenotyping_complete_date,
              aborted_statuses.created_at::date as phenotype_attempt_aborted_date,
              best_phenotype_attempts.mouse_allele_type AS pa_mouse_allele_type,
              targ_rep_es_cells.allele_symbol_superscript_template AS pa_allele_symbol_superscript_template,
              targ_rep_es_cells.mgi_allele_symbol_superscript AS pa_allele_symbol_superscript

            FROM (
              SELECT DISTINCT phenotype_attempts.*
              FROM phenotype_attempts
              JOIN (
                SELECT
                  best_attempts_for_gene_consortia_centre_and_status.gene_id,
                  best_attempts_for_gene_consortia_centre_and_status.consortium_id,
                  best_attempts_for_gene_consortia_centre_and_status.production_centre_id,
                  best_attempts_for_gene_consortia_centre_and_status.order_by,
                  first_value(best_attempts_for_gene_consortia_centre_and_status.phenotype_attempt_id) OVER (PARTITION BY best_attempts_for_gene_consortia_centre_and_status.gene_id, best_attempts_for_gene_consortia_centre_and_status.consortium_id, best_attempts_for_gene_consortia_centre_and_status.production_centre_id) AS phenotype_attempt_id
                FROM (
                  SELECT
                    mi_plans.gene_id,
                    mi_plans.consortium_id,
                    mi_plans.production_centre_id,
                    phenotype_attempt_statuses.order_by,
                    phenotype_attempts.id as phenotype_attempt_id
                    FROM mi_plans
                    JOIN phenotype_attempts ON mi_plans.id = phenotype_attempts.mi_plan_id
                    JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempts.status_id
                    ORDER BY
                      mi_plans.gene_id,
                      mi_plans.consortium_id,
                      mi_plans.production_centre_id,
                      phenotype_attempt_statuses.order_by DESC
                ) AS best_attempts_for_gene_consortia_centre_and_status
              ) AS attempts_join ON phenotype_attempts.id = attempts_join.phenotype_attempt_id
            ) best_phenotype_attempts
            JOIN mi_plans ON mi_plans.id = best_phenotype_attempts.mi_plan_id
            LEFT JOIN mi_attempts ON best_phenotype_attempts.mi_attempt_id = mi_attempts.id
            LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
            LEFT JOIN mi_plans AS mi_attempt_mi_plans ON mi_attempt_mi_plans.id = mi_attempts.mi_plan_id
            LEFT JOIN consortia ON consortia.id = mi_attempt_mi_plans.consortium_id
            LEFT JOIN centres ON centres.id = mi_attempt_mi_plans.production_centre_id
            JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = best_phenotype_attempts.status_id

            LEFT JOIN phenotype_attempt_status_stamps AS aborted_statuses ON aborted_statuses.phenotype_attempt_id = best_phenotype_attempts.id AND aborted_statuses.status_id = 1
            LEFT JOIN phenotype_attempt_status_stamps AS registered_statuses ON registered_statuses.phenotype_attempt_id = best_phenotype_attempts.id AND registered_statuses.status_id = 2
            LEFT JOIN phenotype_attempt_status_stamps AS re_started_statuses ON re_started_statuses.phenotype_attempt_id = best_phenotype_attempts.id AND re_started_statuses.status_id = 3
            LEFT JOIN phenotype_attempt_status_stamps AS re_complete_statuses ON re_complete_statuses.phenotype_attempt_id = best_phenotype_attempts.id AND re_complete_statuses.status_id = 4
            LEFT JOIN phenotype_attempt_status_stamps AS cre_started_statuses ON cre_started_statuses.phenotype_attempt_id = best_phenotype_attempts.id AND cre_started_statuses.status_id = 5
            LEFT JOIN phenotype_attempt_status_stamps AS cre_complete_statuses ON cre_complete_statuses.phenotype_attempt_id = best_phenotype_attempts.id AND cre_complete_statuses.status_id = 6
            LEFT JOIN phenotype_attempt_status_stamps AS started_statuses ON started_statuses.phenotype_attempt_id = best_phenotype_attempts.id AND started_statuses.status_id = 7
            LEFT JOIN phenotype_attempt_status_stamps AS complete_statuses ON complete_statuses.phenotype_attempt_id = best_phenotype_attempts.id AND complete_statuses.status_id = 8

            ORDER BY mi_plan_id
          )


          -- build intermediate report

          SELECT
            consortia.name AS consortium,
            centres.name AS production_centre,
            genes.marker_symbol AS gene,
            genes.mgi_accession_id,
            CASE
              WHEN best_phenotype_attempts.phenotype_attempt_status is null AND best_mi_attempts.mi_attempt_status is null
                THEN 'no_attempts'
              WHEN best_phenotype_attempts.phenotype_attempt_status is null
                THEN best_mi_attempts.mi_attempt_status
              ELSE best_phenotype_attempts.phenotype_attempt_status
            END AS overall_status,
            best_mi_attempts.mi_attempt_status,
            best_phenotype_attempts.phenotype_attempt_status,
            best_mi_attempts.ikmc_project_id,
            best_mi_attempts.mutation_sub_type,
            best_mi_attempts.allele_symbol_superscript,
            best_mi_attempts.allele_symbol_superscript_template,
            best_mi_attempts.mi_mouse_allele_type,
            best_mi_attempts.genetic_background,
            best_mi_attempts.chimeras_obtained_date,
            best_mi_attempts.genotype_confirmed_date,
            best_mi_attempts.micro_injection_aborted_date,
            best_phenotype_attempts.phenotype_attempt_registered_date,
            best_phenotype_attempts.rederivation_started_date,
            best_phenotype_attempts.rederivation_complete_date,
            best_phenotype_attempts.cre_excision_started_date,
            best_phenotype_attempts.cre_excision_complete_date,
            best_phenotype_attempts.phenotyping_started_date,
            best_phenotype_attempts.phenotyping_complete_date,
            best_phenotype_attempts.phenotype_attempt_aborted_date,
            best_phenotype_attempts.pa_mouse_allele_type,
            best_phenotype_attempts.pa_allele_symbol_superscript_template,
            best_phenotype_attempts.pa_allele_symbol_superscript,
            case
              when best_mi_attempts.mi_attempt_colony_name is null
              then best_phenotype_attempts.pa_mi_attempt_colony_name
              else best_mi_attempts.mi_attempt_colony_name
            end AS mi_attempt_colony_name,
            best_phenotype_attempts.pa_mi_attempt_consortium AS mi_attempt_consortium,
            best_phenotype_attempts.pa_mi_attempt_production_centre AS mi_attempt_production_centre,
            best_phenotype_attempts.phenotype_attempt_colony_name

          FROM (SELECT DISTINCT mi_plans.gene_id, mi_plans.consortium_id, mi_plans.production_centre_id FROM mi_plans) AS unique_gene_plans

          JOIN consortia ON consortia.id = unique_gene_plans.consortium_id
          JOIN genes ON genes.id = unique_gene_plans.gene_id
          LEFT JOIN centres ON centres.id = unique_gene_plans.production_centre_id
          LEFT JOIN best_mi_attempts ON best_mi_attempts.gene_id = unique_gene_plans.gene_id AND  best_mi_attempts.consortium_id = unique_gene_plans.consortium_id AND  best_mi_attempts.production_centre_id = unique_gene_plans.production_centre_id
          LEFT JOIN best_phenotype_attempts ON best_phenotype_attempts.gene_id = unique_gene_plans.gene_id AND best_phenotype_attempts.consortium_id = unique_gene_plans.consortium_id AND  best_phenotype_attempts.production_centre_id = unique_gene_plans.production_centre_id

          ORDER BY unique_gene_plans.gene_id, unique_gene_plans.consortium_id, unique_gene_plans.production_centre_id
        EOF
      end

      def clone_efficiency_sql
        <<-EOF
          SELECT
            mi_plans.gene_id AS gene_id,
            mi_plans.consortium_id As consortium_id,
            mi_plans.production_centre_id AS production_centre_id,

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

          GROUP BY mi_plans.gene_id, mi_plans.consortium_id, mi_plans.production_centre_id
        EOF
      end

      def gene_efficiency_sql
        <<-EOF
          WITH counts AS (
            SELECT
              genes.id AS gene_id,
              mi_plans.consortium_id AS consortium_id,
              mi_plans.production_centre_id AS production_centre_id,

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

            GROUP BY genes.id, mi_plans.consortium_id, mi_plans.production_centre_id
            ORDER BY genes.id, mi_plans.consortium_id, mi_plans.production_centre_id
          )

          SELECT
            gene_id,
            consortium_id,
            production_centre_id,
            SUM(case when old_gtc_count > 0 then 1 else 0 end) AS old_gtc_count,
            SUM(case when old_total_count > 0 then 1 else 0 end) AS old_total_count,
            SUM(case when gtc_count > 0 then 1 else 0 end) AS gtc_count,
            SUM(case when total_count > 0 then 1 else 0 end) AS total_count

          FROM counts
          GROUP BY gene_id, consortium_id, production_centre_id
        EOF
      end

      def columns
        [
          'consortium',
          'production_centre',
          'gene',
          'mgi_accession_id',
          'overall_status',
          'mi_attempt_status',
          'phenotype_attempt_status',
          'ikmc_project_id',
          'mutation_sub_type',
          'allele_symbol',
          'genetic_background',
          'micro_injection_in_progress_date',
          'chimeras_obtained_date',
          'genotype_confirmed_date',
          'micro_injection_aborted_date',
          'phenotype_attempt_registered_date',
          'rederivation_started_date',
          'rederivation_complete_date',
          'cre_excision_started_date',
          'cre_excision_complete_date',
          'phenotyping_started_date',
          'phenotyping_complete_date',
          'phenotype_attempt_aborted_date',
          'distinct_genotype_confirmed_es_cells',
          'distinct_non_genotype_confirmed_es_cells',
          'distinct_old_genotype_confirmed_es_cells',
          'distinct_old_non_genotype_confirmed_es_cells',
          'total_pipeline_efficiency_gene_count',
          'gc_pipeline_efficiency_gene_count',
          'total_old_pipeline_efficiency_gene_count',
          'gc_old_pipeline_efficiency_gene_count',
          'mi_attempt_colony_name',
          'mi_attempt_consortium',
          'mi_attempt_production_centre',
          'phenotype_attempt_colony_name',
          'created_at'
        ]

      end
    end
  end
end
