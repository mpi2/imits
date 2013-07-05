class BaseProductionReport

  ##
  ## This is the base presenter for production specific reports grouped by
  ## consortium, centre, and status, while also displaying gene & clone efficiency data.
  ## Consortium/centre/status queries use the intermediate report, efficiency data comes from live tables.
  ##

  attr_accessor :consortium_by_status
  attr_accessor :consortium_centre_by_status
  attr_accessor :consortium_centre_micro_injecions_by_mi_attempt
  attr_accessor :consortium_centre_micro_injecions_by_clones
  attr_accessor :consortium_by_distinct_gene
  attr_accessor :gene_efficiency_totals
  attr_accessor :clone_efficiency_totals
  attr_accessor :most_advanced_gt_mi_for_gene
  attr_accessor :micro_injection_list

  def consortium_by_status
    @consortium_by_status ||= ActiveRecord::Base.connection.execute(self.class.consortium_by_status_sql)
  end

  def consortium_centre_by_status
    @consortium_centre_by_status ||= ActiveRecord::Base.connection.execute(self.class.consortium_centre_by_status_sql)
  end

  def consortium_centre_micro_injecions_by_mi_attempt
    @consortium_centre_micro_injecions_by_mi_attempt ||= ActiveRecord::Base.connection.execute(self.class.consortium_centre_micro_injecions_by_mi_attempt_sql)
  end

  def consortium_centre_micro_injecions_by_clones
    @consortium_centre_micro_injecions_by_clones ||= ActiveRecord::Base.connection.execute(self.class.consortium_centre_micro_injecions_by_clones_sql)
  end

  def consortium_centre_by_phenotyping_status(cre_excision_required)
    ActiveRecord::Base.connection.execute(self.class.consortium_centre_by_phenotyping_status_sql(cre_excision_required))
  end

  def consortium_by_distinct_gene
    @consortium_by_distinct_gene ||= ActiveRecord::Base.connection.execute(self.class.consortium_by_distinct_gene_sql)
  end

  def gene_efficiency_totals
    @gene_efficiency_totals ||= ActiveRecord::Base.connection.execute(self.class.gene_efficiency_totals_sql)
  end

  def clone_efficiency_totals
    @clone_efficiency_totals ||= ActiveRecord::Base.connection.execute(self.class.clone_efficiency_totals_sql)
  end

  def effort_efficiency_totals
    @effort_efficiency_totals ||= ActiveRecord::Base.connection.execute(self.class.effort_based_efficiency_totals_sql)
  end

  def most_advanced_gt_mi_for_genes
    @most_advanced_gt_mi_for_gene ||= ActiveRecord::Base.connection.execute(self.class.most_advanced_gt_mi_for_genes_sql)
  end

  def micro_injection_list
    @micro_injection_list ||= ActiveRecord::Base.connection.execute(self.class.micro_injection_list_sql)
  end


  def generate_consortium_by_status
    hash = {}

    consortium_by_status.each do |report_row|

      hash["#{report_row['consortium']}-ES Cell QC"] ||= 0
      hash["#{report_row['consortium']}-ES QC Confirmed"] ||= 0
      hash["#{report_row['consortium']}-ES QC Failed"] ||= 0

      non_cumulative_status = report_row['mi_plan_status']

      ## Support for ES Cell QC cumulative status
      if ['Assigned - ES Cell QC Complete', 'Assigned - ES Cell QC In Progress', 'Aborted - ES Cell QC Failed'].include?(non_cumulative_status)
        hash["#{report_row['consortium']}-ES Cell QC"] += report_row['count'].to_i
      end

      if 'Assigned - ES Cell QC Complete' == non_cumulative_status
        hash["#{report_row['consortium']}-ES QC Confirmed"] += report_row['count'].to_i
      end

      if 'Aborted - ES Cell QC Failed' == non_cumulative_status
        hash["#{report_row['consortium']}-ES QC Failed"] += report_row['count'].to_i
      end

    end

    hash
  end

  def generate_consortium_centre_by_status
    hash = {}

    consortium_centre_by_status.each do |report_row|
      next if report_row['production_centre'].blank?

      hash["#{report_row['consortium']}"] = hash["#{report_row['consortium']}"] || []
      if !hash["#{report_row['consortium']}"].include?(report_row['production_centre'])
        hash["#{report_row['consortium']}"] << report_row['production_centre']
      end

      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Microinjections"]  ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Chimeras"]         ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Genotype Confirmed Mice"]   ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Microinjection aborted"]    ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Micro-injection in progress"]    ||= 0

      non_cumulative_status = report_row['mi_attempt_status']

      if ['Micro-injection in progress', 'Micro-injection aborted', 'Chimeras obtained', 'Genotype confirmed'].include?(non_cumulative_status)
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Microinjections"] += report_row['count'].to_i
      end

      if 'Chimeras obtained' == non_cumulative_status
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Chimeras"] = report_row['count'].to_i
      end

      if 'Genotype confirmed' == non_cumulative_status
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Genotype Confirmed Mice"] = report_row['count'].to_i
      end

      if 'Micro-injection aborted' == non_cumulative_status
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Microinjection aborted"] = report_row['count'].to_i
      end

      if 'Micro-injection in progress' == non_cumulative_status
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Micro-injection in progress"] = report_row['count'].to_i
      end

    end


    consortium_centre_micro_injecions_by_mi_attempt.each do |report_row|
      next if report_row['production_centre'].blank?

      hash["#{report_row['consortium']}"] = hash["#{report_row['consortium']}"] || []
      if !hash["#{report_row['consortium']}"].include?(report_row['production_centre'])
        hash["#{report_row['consortium']}"] << report_row['production_centre']
      end

      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Microinjections-mi_attempt"]  ||= report_row['count'].to_i
            hash["#{report_row['consortium']}-#{report_row['production_centre']}-Microinjections-mi_attempt-in-progress"]  ||= report_row['count_mi_attempts_in_progress'].to_i
    end


    consortium_centre_micro_injecions_by_clones.each do |report_row|
      next if report_row['production_centre'].blank?

      hash["#{report_row['consortium']}"] = hash["#{report_row['consortium']}"] || []
      if !hash["#{report_row['consortium']}"].include?(report_row['production_centre'])
        hash["#{report_row['consortium']}"] << report_row['production_centre']
      end

      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Microinjections-clones"]  ||= report_row['count'].to_i
    end

    hash
  end

  def generate_consortium_centre_by_phenotyping_status(cre_excision_required = true)
    hash = {}

    consortium_centre_by_phenotyping_status(cre_excision_required).each do |report_row|
      next if report_row['production_centre'].blank?

      hash["#{report_row['consortium']}"] = hash["#{report_row['consortium']}"] || []
      if !hash["#{report_row['consortium']}"].include?(report_row['production_centre'])
        hash["#{report_row['consortium']}"] << report_row['production_centre']
      end

      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Intent to phenotype"]    ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Rederivation started"]   ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Rederivation completed"] ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Cre excision started"]   ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Cre excision completed"] ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping started"]    ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping completed"]  ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping aborted"]    ||= 0

      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Intent to phenotype"] += report_row["count"].to_i

      if report_row['phenotype_attempt_status'] == 'Rederivation Started'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Rederivation started"] += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Rederivation Complete'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Rederivation completed"] += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Cre Excision Started'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Cre excision started"] += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Cre Excision Complete'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Cre excision completed"] += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Phenotyping Started'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping started"] += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Phenotyping Complete'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping completed"] += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Phenotype Attempt Aborted'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping aborted"] += report_row["count"].to_i
      end

    end

    hash
  end

  def generate_gene_efficiency_totals
    hash = {}

    gene_efficiency_totals.each do |report_row|
      hash["#{report_row['consortium_name']}-#{report_row['production_centre_name']}-count"]     = report_row['total_mice'].to_f
      hash["#{report_row['consortium_name']}-#{report_row['production_centre_name']}-gtc_count"] = report_row['gtc_mice'].to_f
    end

    hash
  end

  def generate_clone_efficiency_totals
    hash = {}

    clone_efficiency_totals.each do |report_row|
      hash["#{report_row['consortium_name']}-#{report_row['production_centre_name']}-count"]     = report_row['total_mice'].to_f
      hash["#{report_row['consortium_name']}-#{report_row['production_centre_name']}-gtc_count"] = report_row['gtc_mice'].to_f
    end

    hash
  end

  def generate_effort_efficiency_totals
    hash = {}

    effort_efficiency_totals.each do |report_row|

      gtc_gene_count   = report_row['gene_count'].to_f
      total_injections = report_row['total_injections'].to_f

      efficiency = if gtc_gene_count > 0.0 && total_injections > 0.0
        gtc_gene_count / total_injections
      end.to_f

      hash["#{report_row['consortium_name']}-#{report_row['production_centre_name']}-gtc_count_efficiency"] = gtc_gene_count
      hash["#{report_row['consortium_name']}-#{report_row['production_centre_name']}-total_count_efficiency"] = total_injections
      hash["#{report_row['consortium_name']}-#{report_row['production_centre_name']}-effort_efficiency"] = efficiency
    end

    hash
  end

  class << self

    def mi_plan_statuses
      ['ES Cell QC', 'ES QC Confirmed', 'ES QC Failed']
    end

    def title
      "Production summary"
    end

    def available_consortia
      (@available_consortia && !@available_consortia.empty?) ? @available_consortia : []
    end

    def available_consortia=(array)
      @available_consortia = array
    end

    def available_production_centres
      (@available_production_centres && !@available_production_centres.empty?) ? @available_production_centres : []
    end

    def available_production_centres=(array)
      @available_production_centres = array
    end

    def consortium_by_distinct_gene_sql
      sql = <<-EOF
        SELECT
        consortium,
        COUNT(distinct(gene))
        FROM new_gene_intermediate_report
        WHERE consortium in ('#{available_consortia.join('\', \'')}')
        GROUP BY consortium;
      EOF
    end

    # WHAT DOES THIS DO
    def consortium_by_status_sql
      sql = <<-EOF
        SELECT
        consortia.name AS consortium,
        mi_plan_statuses.name AS mi_plan_status,
        COUNT(*)
        FROM (
        SELECT DISTINCT most_advanced_mi_plan_id_by_consortia AS mi_plan_id FROM new_gene_intermediate_report
        ) AS mp
        JOIN mi_plans ON mi_plans.id = mp.mi_plan_id
        JOIN consortia ON consortia.id = mi_plans.consortium_id
        JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plans.status_id
        WHERE consortia.name in ('#{available_consortia.join('\', \'')}')
        GROUP BY consortia.name, mi_plan_statuses.name
        ORDER BY consortia.name;
      EOF
    end

    def consortium_centre_micro_injecions_by_clones_sql
      sql = <<-EOF
        SELECT
        consortia.name AS consortium,
        centres.name AS production_centre,
        COUNT(DISTINCT(targ_rep_es_cells.id)) AS count
        FROM targ_rep_es_cells
        JOIN mi_attempts ON mi_attempts.es_cell_id = targ_rep_es_cells.id
        JOIN mi_attempt_status_stamps ON mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id AND mi_attempt_status_stamps.status_id = 1
        JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
        JOIN consortia ON consortia.id = mi_plans.consortium_id
        JOIN centres ON centres.id = mi_plans.production_centre_id
        WHERE consortia.name in ('#{available_consortia.join('\', \'')}')
        GROUP BY consortia.name, centres.name
        ORDER BY consortia.name, centres.name;
      EOF
    end

    def consortium_centre_by_status_sql
      sql = <<-EOF
        SELECT
        consortium,
        production_centre,
        mi_attempt_status,
        COUNT(*) AS count
        FROM new_gene_intermediate_report
        WHERE consortium in ('#{available_consortia.join('\', \'')}')
        GROUP BY consortium, production_centre, mi_attempt_status
        ORDER BY consortium, production_centre;
      EOF
    end

    def consortium_centre_micro_injecions_by_mi_attempt_sql
      sql = <<-EOF
        SELECT
        consortia.name AS consortium,
        centres.name AS production_centre,
        COUNT(*) AS count,
        SUM(CASE WHEN mi_attempts.status_id = 1 THEN 1 ELSE 0 END) As count_mi_attempts_in_progress
        FROM mi_attempts
        JOIN mi_attempt_status_stamps ON mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id AND mi_attempt_status_stamps.status_id = 1
        JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
        JOIN consortia ON consortia.id = mi_plans.consortium_id
        JOIN centres ON centres.id = mi_plans.production_centre_id
        WHERE consortia.name in ('#{available_consortia.join('\', \'')}')
        GROUP BY consortia.name, centres.name
        ORDER BY consortia.name, centres.name;
      EOF
    end

    def consortium_centre_by_phenotyping_status_sql(cre_excision_required = true)
      sql = <<-EOF
        -- Phenotyping counts
        SELECT
        consortium,
        production_centre,
        phenotype_attempt_status,
        COUNT(*)
        FROM new_gene_intermediate_report
        JOIN phenotype_attempts ON new_gene_intermediate_report.phenotype_attempt_colony_name = phenotype_attempts.colony_name AND phenotype_attempts.cre_excision_required is #{cre_excision_required}
        WHERE consortium in ('#{available_consortia.join('\', \'')}')
        GROUP BY consortium, production_centre, phenotype_attempt_status
        ORDER BY consortium, production_centre;
        -- Phenotyping counts END
      EOF
    end

    def gene_efficiency_totals_sql
      sql = <<-EOF
        SELECT
        counts.consortium_name,
        counts.production_centre_name,
        sum(case when counts.gtc_count > 0 then 1 else 0 end) as gtc_mice,
        sum(c) as total_mice
        FROM (
          SELECT
          genes.id as gene_id,
          consortia.name as consortium_name,
          centres.name as production_centre_name,
          sum(case when mi_attempts.status_id = 2 then 1 else 0 end) as gtc_count,
          1 as c
          FROM genes
          JOIN targ_rep_alleles ON genes.id = targ_rep_alleles.gene_id
          JOIN targ_rep_es_cells ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
          JOIN mi_attempts ON targ_rep_es_cells.id = mi_attempts.es_cell_id
          JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
          JOIN consortia ON consortia.id = mi_plans.consortium_id
          JOIN mi_attempt_status_stamps ON mi_attempts.id = mi_attempt_status_stamps.mi_attempt_id AND mi_attempt_status_stamps.status_id = 1
          LEFT JOIN centres ON centres.id = mi_plans.production_centre_id
          WHERE mi_attempt_status_stamps.created_at < '#{6.months.ago.to_s(:db)}'
            AND consortia.name in ('#{available_consortia.join('\', \'')}')
          GROUP BY genes.id, consortium_name, production_centre_name
        ) as counts
        GROUP BY counts.consortium_name, counts.production_centre_name
      EOF
    end

    def clone_efficiency_totals_sql
      sql = <<-EOF
        SELECT
        counts.consortium_name,
        counts.production_centre_name,
        sum(case when counts.gtc_count > 0 then 1 else 0 end) as gtc_mice,
        sum(c) as total_mice
        FROM (
          SELECT
          targ_rep_es_cells.id as cell,
          consortia.name as consortium_name,
          centres.name as production_centre_name,
          sum(case when mi_attempts.status_id = 2 then 1 else 0 end) as gtc_count,
          1 as c
          FROM targ_rep_es_cells
          JOIN mi_attempts ON targ_rep_es_cells.id = mi_attempts.es_cell_id
          JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
          JOIN consortia ON consortia.id = mi_plans.consortium_id
          JOIN mi_attempt_status_stamps ON mi_attempts.id = mi_attempt_status_stamps.mi_attempt_id AND mi_attempt_status_stamps.status_id = 1
          LEFT JOIN centres ON centres.id = mi_plans.production_centre_id
          WHERE mi_attempt_status_stamps.created_at < '#{6.months.ago.to_s(:db)}'
            AND consortia.name in ('#{available_consortia.join('\', \'')}')
          GROUP BY targ_rep_es_cells.id, consortium_name, production_centre_name
        ) as counts
        GROUP BY counts.consortium_name, counts.production_centre_name
      EOF
    end

    def effort_based_efficiency_totals_sql
      <<-EOF
        WITH distinct_microinjected_genes AS (
          SELECT
            counts.consortium_name,
            counts.production_centre_name,
            SUM(CASE
              WHEN gtc_count > 0
              THEN 1 ELSE 0
            END) as gene_count
          FROM (
            SELECT
              genes.id as gene_id,
              consortia.name as consortium_name,
              centres.name as production_centre_name,
              sum(case when mi_attempts.status_id = 2 then 1 else 0 end) as gtc_count,
              1 as gene
            FROM genes
            JOIN targ_rep_alleles ON genes.id = targ_rep_alleles.gene_id
            JOIN targ_rep_es_cells ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
            JOIN mi_attempts ON targ_rep_es_cells.id = mi_attempts.es_cell_id
            JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
            JOIN consortia ON consortia.id = mi_plans.consortium_id
            LEFT JOIN centres ON centres.id = mi_plans.production_centre_id

            WHERE
              mi_attempts.mi_date <= '#{6.months.ago.to_s(:db)}'
            AND
              consortia.name in ('#{available_consortia.join('\', \'')}')

            GROUP BY
              genes.id,
              consortium_name,
              production_centre_name

            ORDER BY genes.id
          ) as counts

          GROUP BY
            counts.consortium_name,
            counts.production_centre_name
        ),

        total_microinjections AS (
          SELECT
            consortia.name AS consortium_name,
            centres.name AS production_centre_name,
            count(*) AS total_injections
          FROM mi_attempts
          JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
          JOIN consortia ON consortia.id = mi_plans.consortium_id
          LEFT JOIN centres ON centres.id = mi_plans.production_centre_id

          WHERE
            mi_attempts.mi_date <= '#{6.months.ago.to_s(:db)}'
          AND
            consortia.name in ('#{available_consortia.join('\', \'')}')

          GROUP BY
            consortium_name,
            production_centre_name

        )

        SELECT
          total_microinjections.consortium_name,
          total_microinjections.production_centre_name,
          distinct_microinjected_genes.gene_count,
          total_microinjections.total_injections
        FROM distinct_microinjected_genes
        JOIN total_microinjections ON total_microinjections.consortium_name = distinct_microinjected_genes.consortium_name AND total_microinjections.production_centre_name = distinct_microinjected_genes.production_centre_name

      EOF
    end

    def most_advanced_gt_mi_for_genes_sql
      <<-EOF
            SELECT
              best_mi_attempts.id AS mi_attempts_id,
              mi_attempt_statuses.name AS mi_attempt_status,
              best_mi_attempts.mi_plan_id AS mi_plan_id,
              best_mi_attempts.colony_name AS mi_attempt_colony_name,
              targ_rep_es_cells.ikmc_project_id  AS ikmc_project_id,
              targ_rep_mutation_types.name AS mutation_sub_type,
              targ_rep_es_cells.mgi_allele_symbol_superscript AS allele_symbol_superscript,
              targ_rep_es_cells.allele_symbol_superscript_template AS allele_symbol_superscript_template,
              best_mi_attempts.mouse_allele_type AS mi_mouse_allele_type,
              strains.name AS genetic_background,
              in_progress_stamps.created_at::date AS micro_injection_in_progress_date,
              chimearic_stamps.created_at::date   AS chimeras_obtained_date,
              gc_stamps.created_at::date          AS genotype_confirmed_date,
              aborted_stamps.created_at::date     AS micro_injection_aborted_date,
              genes.marker_symbol AS marker_symbol,
              genes.mgi_accession_id AS mgi_accession_id,
              mi_plans.is_bespoke_allele AS bespoke_allele,
              mi_plans.is_conditional_allele AS conditional_allele,
              mi_plans.is_deletion_allele AS deletion_allele,
              mi_plans.is_cre_knock_in_allele AS cre_knock_in_allele,
              mi_plans.is_cre_bac_allele AS cre_bac_allele,
              mi_plans.conditional_tm1c AS conditional_tm1c,
              mi_plans.ignore_available_mice AS ignore_available_mice,
              mi_plan_statuses.name AS mi_plan_status,
              assigned.created_at::date AS assigned_date,
              assigned_es_cell_qc_in_progress.created_at::date AS assigned_es_cell_qc_in_progress_date,
              assigned_es_cell_qc_complete.created_at::date AS assigned_es_cell_qc_complete_date,
              aborted.created_at::date AS aborted_date,
              mi_plan_priorities.name AS priority,
              consortia.name AS consortium,
              centres.name AS production_centre

            FROM (
              SELECT DISTINCT mi_attempts.*
              FROM mi_attempts
              JOIN (
                SELECT
                  best_attempts_for_plan_and_status.gene_id,
                  best_attempts_for_plan_and_status.order_by,
                  first_value(best_attempts_for_plan_and_status.mi_attempt_id) OVER (PARTITION BY best_attempts_for_plan_and_status.gene_id) AS mi_attempt_id
                FROM (
                  SELECT
                    mi_plans.gene_id AS gene_id,
                    mi_attempt_statuses.order_by,
                    mi_attempts.id as mi_attempt_id

                  FROM mi_attempts
                  JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id AND mi_attempt_statuses.id = 2
                  JOIN mi_attempt_status_stamps ON mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id AND mi_attempt_status_stamps.status_id = 1
                  JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
                  JOIN consortia ON consortia.id = mi_plans.consortium_id
                  JOIN centres On centres.id = mi_plans.production_centre_id
                  WHERE
                    mi_attempts.mi_date <= '#{6.months.ago.to_s(:db)}'
                    AND consortia.name  in ('#{available_consortia.join('\', \'')}')
                    AND centres.name  in ('#{available_production_centres.join('\', \'')}')
                  ORDER BY
                    mi_plans.gene_id,
                    mi_attempt_statuses.order_by DESC,
                    mi_attempt_status_stamps.created_at ASC
                ) as best_attempts_for_plan_and_status
              ) AS att ON mi_attempts.id = att.mi_attempt_id

            ) best_mi_attempts

            JOIN targ_rep_es_cells ON targ_rep_es_cells.id = best_mi_attempts.es_cell_id
            JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
            JOIN genes ON genes.id = targ_rep_alleles.gene_id
            JOIN mi_attempt_statuses ON mi_attempt_statuses.id = best_mi_attempts.status_id
            LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
            LEFT JOIN strains ON best_mi_attempts.colony_background_strain_id = strains.id
            LEFT JOIN mi_attempt_status_stamps AS in_progress_stamps ON in_progress_stamps.mi_attempt_id = best_mi_attempts.id AND in_progress_stamps.status_id = 1
            LEFT JOIN mi_attempt_status_stamps AS gc_stamps          ON gc_stamps.mi_attempt_id = best_mi_attempts.id          AND gc_stamps.status_id = 2
            LEFT JOIN mi_attempt_status_stamps AS aborted_stamps     ON aborted_stamps.mi_attempt_id = best_mi_attempts.id     AND aborted_stamps.status_id = 3
            LEFT JOIN mi_attempt_status_stamps AS chimearic_stamps   ON chimearic_stamps.mi_attempt_id = best_mi_attempts.id   AND chimearic_stamps.status_id = 4
            JOIN mi_plans ON mi_plans.id = best_mi_attempts.mi_plan_id
            JOIN consortia ON consortia.id = mi_plans.consortium_id
            LEFT JOIN centres ON centres.id = mi_plans.production_centre_id
            JOIN mi_plan_statuses ON mi_plans.status_id = mi_plan_statuses.id
            LEFT JOIN mi_plan_status_stamps AS assigned ON mi_plans.id = assigned.mi_plan_id AND assigned.status_id = 1
            LEFT JOIN mi_plan_status_stamps AS assigned_es_cell_qc_in_progress ON mi_plans.id = assigned_es_cell_qc_in_progress.mi_plan_id AND assigned_es_cell_qc_in_progress.status_id = 8
            LEFT JOIN mi_plan_status_stamps AS assigned_es_cell_qc_complete ON mi_plans.id = assigned_es_cell_qc_complete.mi_plan_id AND assigned_es_cell_qc_complete.status_id = 9
            LEFT JOIN mi_plan_status_stamps AS aborted ON mi_plans.id = aborted.mi_plan_id AND aborted.status_id = 10
            LEFT JOIN mi_plan_priorities ON mi_plan_priorities.id = mi_plans.priority_id
            ORDER BY genes.marker_symbol
      EOF
    end

    def micro_injection_list_sql
      <<-EOF
          SELECT
            mi_attempts.id AS mi_attempts_id,
            mi_attempt_statuses.name AS mi_attempt_status,
            mi_attempts.mi_plan_id AS mi_plan_id,
            mi_attempts.colony_name AS mi_attempt_colony_name,
            targ_rep_es_cells.ikmc_project_id AS ikmc_project_id,
            targ_rep_mutation_types.name AS mutation_sub_type,
            targ_rep_es_cells.mgi_allele_symbol_superscript AS allele_symbol_superscript,
            targ_rep_es_cells.allele_symbol_superscript_template AS allele_symbol_superscript_template,
            mi_attempts.mouse_allele_type AS mi_mouse_allele_type,
            strains.name AS genetic_background,
            in_progress_stamps.created_at::date AS micro_injection_in_progress_date,
            chimearic_stamps.created_at::date   AS chimeras_obtained_date,
            gc_stamps.created_at::date          AS genotype_confirmed_date,
            aborted_stamps.created_at::date     AS micro_injection_aborted_date,
            genes.marker_symbol AS marker_symbol,
            genes.mgi_accession_id AS mgi_accession_id,
            mi_plans.is_bespoke_allele AS bespoke_allele,
            mi_plans.is_conditional_allele AS conditional_allele,
            mi_plans.is_deletion_allele AS deletion_allele,
            mi_plans.is_cre_knock_in_allele AS cre_knock_in_allele,
            mi_plans.is_cre_bac_allele AS cre_bac_allele,
            mi_plans.conditional_tm1c AS conditional_tm1c,
            mi_plans.ignore_available_mice AS ignore_available_mice,
            mi_plan_statuses.name AS mi_plan_status,
            assigned.created_at::date AS assigned_date,
            assigned_es_cell_qc_in_progress.created_at::date AS assigned_es_cell_qc_in_progress_date,
            assigned_es_cell_qc_complete.created_at::date AS assigned_es_cell_qc_complete_date,
            aborted.created_at::date AS aborted_date,
            mi_plan_priorities.name AS priority,
            consortia.name AS consortium,
            centres.name AS production_centre

          FROM mi_attempts
            JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
            JOIN consortia ON consortia.id = mi_plans.consortium_id
            LEFT JOIN centres ON centres.id = mi_plans.production_centre_id
            JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
            JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
            JOIN genes ON genes.id = targ_rep_alleles.gene_id
            JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
            LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
            LEFT JOIN strains ON mi_attempts.colony_background_strain_id = strains.id
            LEFT JOIN mi_attempt_status_stamps AS in_progress_stamps ON in_progress_stamps.mi_attempt_id = mi_attempts.id AND in_progress_stamps.status_id = 1
            LEFT JOIN mi_attempt_status_stamps AS gc_stamps          ON gc_stamps.mi_attempt_id = mi_attempts.id          AND gc_stamps.status_id = 2
            LEFT JOIN mi_attempt_status_stamps AS aborted_stamps     ON aborted_stamps.mi_attempt_id = mi_attempts.id     AND aborted_stamps.status_id = 3
            LEFT JOIN mi_attempt_status_stamps AS chimearic_stamps   ON chimearic_stamps.mi_attempt_id = mi_attempts.id   AND chimearic_stamps.status_id = 4
            JOIN mi_plan_statuses ON mi_plans.status_id = mi_plan_statuses.id
            LEFT JOIN mi_plan_status_stamps AS assigned ON mi_plans.id = assigned.mi_plan_id AND assigned.status_id = 1
            LEFT JOIN mi_plan_status_stamps AS assigned_es_cell_qc_in_progress ON mi_plans.id = assigned_es_cell_qc_in_progress.mi_plan_id AND assigned_es_cell_qc_in_progress.status_id = 8
            LEFT JOIN mi_plan_status_stamps AS assigned_es_cell_qc_complete ON mi_plans.id = assigned_es_cell_qc_complete.mi_plan_id AND assigned_es_cell_qc_complete.status_id = 9
            LEFT JOIN mi_plan_status_stamps AS aborted ON mi_plans.id = aborted.mi_plan_id AND aborted.status_id = 10
            LEFT JOIN mi_plan_priorities ON mi_plan_priorities.id = mi_plans.priority_id

          WHERE
            mi_attempts.mi_date <= '#{6.months.ago.to_s(:db)}'
            AND consortia.name  in ('#{available_consortia.join('\', \'')}')
            AND centres.name  in ('#{available_production_centres.join('\', \'')}')
      EOF
    end
  end

end