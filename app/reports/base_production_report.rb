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
  attr_accessor :consortium_centre_by_phenotyping_status_tm1b
  attr_accessor :consortium_centre_by_phenotyping_status_tm1a
  attr_accessor :mi_attempt_distribution_centre_counts
  attr_accessor :phenotyping_counts
  attr_accessor :phenotype_attempt_distribution_centre_counts

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

  def consortium_centre_by_phenotyping_status_tm1b
    @consortium_centre_by_phenotyping_status_tm1b ||= ActiveRecord::Base.connection.execute(self.class.consortium_centre_by_phenotyping_status_tm1b_sql)
  end

  def consortium_centre_by_phenotyping_status_tm1a
    @consortium_centre_by_phenotyping_status_tm1a ||= ActiveRecord::Base.connection.execute(self.class.consortium_centre_by_phenotyping_status_tm1a_sql)
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

  def mi_attempt_distribution_centre_counts
    @mi_attempt_distribution_centre_counts ||= ActiveRecord::Base.connection.execute(self.class.mi_attempt_distribution_centre_counts_sql)
  end

  def phenotyping_counts
    @phenotyping_counts ||= ActiveRecord::Base.connection.execute(self.class.phenotyping_counts_sql)
  end

  def phenotype_attempt_distribution_centre_counts
    @phenotype_attempt_distribution_centre_counts ||= ActiveRecord::Base.connection.execute(self.class.phenotype_attempt_distribution_centre_counts_sql)
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
    prefix = ''
    data = {}

    if cre_excision_required
      data = consortium_centre_by_phenotyping_status_tm1b
      prefix = 'Tm1b'
      prefix_key = 'tm1b'
    else
      data = consortium_centre_by_phenotyping_status_tm1a
      prefix = 'Tm1a'
      prefix_key = 'tm1a'
    end

    data.each do |report_row|
      next if report_row['production_centre'].blank?

      hash["#{report_row['consortium']}"] = hash["#{report_row['consortium']}"] || []
      if !hash["#{report_row['consortium']}"].include?(report_row['production_centre'])
        hash["#{report_row['consortium']}"] << report_row['production_centre']
      end

      hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Intent to phenotype"]    ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Rederivation started"]   ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Rederivation completed"] ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Cre excision started"]   ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Cre excision completed"] ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Phenotyping started"]    ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Phenotyping completed"]  ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Phenotyping aborted"]    ||= 0

      hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Intent to phenotype"] += report_row["count"].to_i

      if report_row["#{prefix_key}_phenotype_attempt_status"] == 'Rederivation Started'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Rederivation started"] += report_row["count"].to_i
      end

      if report_row["#{prefix_key}_phenotype_attempt_status"] == 'Rederivation Complete'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Rederivation completed"] += report_row["count"].to_i
      end

      if report_row["#{prefix_key}_phenotype_attempt_status"] == 'Cre Excision Started'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Cre excision started"] += report_row["count"].to_i
      end

      if report_row["#{prefix_key}_phenotype_attempt_status"] == 'Cre Excision Complete'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Cre excision completed"] += report_row["count"].to_i
      end

      if report_row["#{prefix_key}_phenotype_attempt_status"] == 'Phenotyping Started'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Phenotyping started"] += report_row["count"].to_i
      end

      if report_row["#{prefix_key}_phenotype_attempt_status"] == 'Phenotyping Complete'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Phenotyping completed"] += report_row["count"].to_i
      end

      if report_row["#{prefix_key}_phenotype_attempt_status"] == 'Phenotype Attempt Aborted'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{prefix} Phenotyping aborted"] += report_row["count"].to_i
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


  def generate_distribution_centre_counts
    hash = {}

    mi_attempt_distribution_centre_counts.each do |report_row|
      hash["mi_attempt-#{report_row['consortium']}-#{report_row['centre']}-emma"] = report_row['emma']
      hash["mi_attempt-#{report_row['consortium']}-#{report_row['centre']}-komp"] = report_row['komp']
      hash["mi_attempt-#{report_row['consortium']}-#{report_row['centre']}-shelf"] = report_row['shelf']
    end

    phenotype_attempt_distribution_centre_counts.each do |report_row|
      hash["phenotype_attempt-#{report_row['phenotype_type']}-#{report_row['consortium']}-#{report_row['centre']}-emma"] = report_row['emma']
      hash["phenotype_attempt-#{report_row['phenotype_type']}-#{report_row['consortium']}-#{report_row['centre']}-komp"] = report_row['komp']
      hash["phenotype_attempt-#{report_row['phenotype_type']}-#{report_row['consortium']}-#{report_row['centre']}-shelf"] = report_row['shelf']
    end

    hash
  end

  def generate_phenotyping_counts
    hash = {}

    phenotyping_counts.each do |report_row|
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping Experiments Started"] = report_row['phenotyping_experiments_started_count']
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Tm1b Phenotype Experiments Started"] = report_row['tm1b_phenotyping_experiments_started_count']
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Tm1a Phenotype Experiments Started"] = report_row['tm1a_phenotyping_experiments_started_count']
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Tm1b Phenotype Attempt Mi Attempt Plan Confliction"] = report_row['tm1b_phenotype_attempt_mi_attempt_plan_confliction']
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Tm1a Phenotype Attempt Mi Attempt Plan Confliction"] = report_row['tm1a_phenotype_attempt_mi_attempt_plan_confliction']
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
        FROM new_intermediate_report_summary_by_centre_and_consortia
        WHERE consortium in ('#{available_consortia.join('\', \'')}')
        GROUP BY consortium;
      EOF
    end

    # WHAT DOES THIS DO
    def consortium_by_status_sql
      sql = <<-EOF
        SELECT
        consortium AS consortium,
        mi_plan_status AS mi_plan_status,
        COUNT(*)
        FROM new_intermediate_report_summary_by_consortia, mi_plans
        WHERE consortium in ('#{available_consortia.join('\', \'')}')
          AND new_intermediate_report_summary_by_consortia.mi_plan_id = mi_plans.id
          AND mi_plans.mutagenesis_via_crispr_cas9 = false
        GROUP BY consortium, mi_plan_status
        ORDER BY consortium;
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
        WHERE consortia.name in ('#{available_consortia.join('\', \'')}') AND mi_plans.mutagenesis_via_crispr_cas9 = false
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
        FROM new_intermediate_report_summary_by_centre_and_consortia
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

    def consortium_centre_by_phenotyping_status_tm1a_sql
      sql = <<-EOF
        -- Phenotyping counts
        SELECT
        consortium,
        production_centre,
        tm1a_phenotype_attempt_status,
        COUNT(*)
        FROM new_intermediate_report_summary_by_centre_and_consortia
        WHERE consortium in ('#{available_consortia.join('\', \'')}') AND tm1a_phenotype_attempt_status IS NOT NULL
        GROUP BY consortium, production_centre, tm1a_phenotype_attempt_status
        ORDER BY consortium, production_centre;
        -- Phenotyping counts END
      EOF
    end

    def consortium_centre_by_phenotyping_status_tm1b_sql
      sql = <<-EOF
        -- Phenotyping counts
        SELECT
        consortium,
        production_centre,
        tm1b_phenotype_attempt_status,
        COUNT(*)
        FROM new_intermediate_report_summary_by_centre_and_consortia
        WHERE consortium in ('#{available_consortia.join('\', \'')}') AND tm1b_phenotype_attempt_status IS NOT NULL
        GROUP BY consortium, production_centre, tm1b_phenotype_attempt_status
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
            AND mi_plans.mutagenesis_via_crispr_cas9 = false
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
            AND mi_plans.mutagenesis_via_crispr_cas9 = false
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
            AND
              mi_plans.mutagenesis_via_crispr_cas9 = false
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
          AND
            mi_plans.mutagenesis_via_crispr_cas9 = false
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
                    AND mi_plans.mutagenesis_via_crispr_cas9 = false
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
            JOIN mi_plans ON mi_plans.id = best_mi_attempts.mi_plan_id AND mi_plans.mutagenesis_via_crispr_cas9 = false
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

    def mi_attempt_distribution_centre_counts_sql
      <<-EOF
      SELECT
        distribution_data.consortium AS consortium,
        distribution_data.centre AS centre,
        SUM(CASE WHEN distribution_data.emma > 0 THEN 1 ELSE 0 END) AS emma,
        SUM(CASE WHEN distribution_data.komp > 0 THEN 1 ELSE 0 END) AS komp,
        SUM(CASE WHEN distribution_data.shelf > 0 THEN 1 ELSE 0 END) AS shelf
      FROM
      (
        SELECT
          mi_plans.gene_id,
          consortia.name AS consortium,
          centres.name AS centre,
          SUM(CASE WHEN mi_attempt_distribution_centres.is_distributed_by_emma = true THEN 1 ELSE 0 END) AS emma,
          SUM(CASE WHEN dis_centre.name IN ('UCD', 'KOMP Repo') AND (mi_attempt_distribution_centres.distribution_network != 'MMRRC' OR mi_attempt_distribution_centres.distribution_network IS NULL) THEN 1 ELSE 0 END) AS KOMP,
          SUM(CASE WHEN (dis_centre.name NOT IN ('UCD', 'KOMP Repo') OR mi_attempt_distribution_centres.distribution_network = 'MMRRC') AND mi_attempt_distribution_centres.is_distributed_by_emma = false THEN 1 ELSE 0 END) AS shelf
        FROM mi_attempt_distribution_centres
          JOIN centres AS dis_centre ON dis_centre.id = mi_attempt_distribution_centres.centre_id
          JOIN mi_attempts ON mi_attempts.id = mi_attempt_distribution_centres.mi_attempt_id
          JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id AND mi_plans.mutagenesis_via_crispr_cas9 = false
          JOIN consortia ON consortia.id  = mi_plans.consortium_id
          JOIN centres ON centres.id = mi_plans.production_centre_id
        GROUP BY mi_plans.gene_id, consortia.name, centres.name
      ) AS distribution_data
      GROUP BY distribution_data.consortium, distribution_data.centre
      EOF
    end

    def phenotyping_counts_sql
      <<-EOF
      SELECT
        consortium,
        production_centre,
        SUM(CASE WHEN tm1a_phenotype_attempt_registered_date IS NOT NULL AND ((consortium != tm1a_phenotyping_mi_attempt_consortium) OR (production_centre != tm1a_phenotyping_mi_attempt_production_centre)) THEN 1 ELSE 0 END) AS tm1a_phenotype_attempt_mi_attempt_plan_confliction,
        SUM(CASE WHEN tm1b_phenotype_attempt_registered_date IS NOT NULL AND ((consortium != tm1b_phenotyping_mi_attempt_consortium) OR (production_centre != tm1b_phenotyping_mi_attempt_production_centre)) THEN 1 ELSE 0 END) AS tm1b_phenotype_attempt_mi_attempt_plan_confliction,
        SUM(CASE WHEN phenotyping_experiments_started_date IS NOT NULL THEN 1 ELSE 0 END) AS phenotyping_experiments_started_count,
        SUM(CASE WHEN tm1b_phenotyping_experiments_started_date IS NOT NULL THEN 1 ELSE 0 END) AS tm1b_phenotyping_experiments_started_count,
        SUM(CASE WHEN tm1a_phenotyping_experiments_started_date IS NOT NULL THEN 1 ELSE 0 END) AS tm1a_phenotyping_experiments_started_count
      FROM
        new_intermediate_report_summary_by_centre_and_consortia
      WHERE
        consortium in ('#{available_consortia.join('\', \'')}')
      GROUP BY
        consortium, production_centre
      EOF
    end

    def phenotype_attempt_distribution_centre_counts_sql
      <<-EOF
      SELECT
        distribution_data.phenotype_type AS phenotype_type,
        distribution_data.consortium AS consortium,
        distribution_data.centre AS centre,
        SUM(CASE WHEN distribution_data.emma > 0 THEN 1 ELSE 0 END) AS emma,
        SUM(CASE WHEN distribution_data.komp > 0 THEN 1 ELSE 0 END) AS komp,
        SUM(CASE WHEN distribution_data.shelf > 0 THEN 1 ELSE 0 END) AS shelf
      FROM
      (
        SELECT
          mi_plans.gene_id,
          allele_category AS phenotype_type,
          consortia.name AS consortium,
          centres.name AS centre,
          SUM(CASE WHEN phenotype_attempt_distribution_centres.is_distributed_by_emma = true THEN 1 ELSE 0 END) AS emma,
          SUM(CASE WHEN dis_centre.name IN ('UCD', 'KOMP Repo') AND (phenotype_attempt_distribution_centres.distribution_network != 'MMRRC' OR phenotype_attempt_distribution_centres.distribution_network IS NULL) THEN 1 ELSE 0 END) AS KOMP,
          SUM(CASE WHEN (dis_centre.name NOT IN ('UCD', 'KOMP Repo') OR (phenotype_attempt_distribution_centres.distribution_network = 'MMRRC')) AND phenotype_attempt_distribution_centres.is_distributed_by_emma = false THEN 1 ELSE 0 END) AS shelf
        FROM phenotype_attempt_distribution_centres
          JOIN centres AS dis_centre ON dis_centre.id = phenotype_attempt_distribution_centres.centre_id
          JOIN mouse_allele_mods ON mouse_allele_mods.id = phenotype_attempt_distribution_centres.mouse_allele_mod_id
          JOIN mi_plans ON mi_plans.id = mouse_allele_mods.mi_plan_id AND mi_plans.mutagenesis_via_crispr_cas9 = false
          JOIN consortia ON consortia.id  = mi_plans.consortium_id
          JOIN centres ON centres.id = mi_plans.production_centre_id
        GROUP BY phenotype_type, mi_plans.gene_id, consortia.name, centres.name
      ) AS distribution_data
      GROUP BY phenotype_type, distribution_data.consortium, distribution_data.centre
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
            AND mi_plans.mutagenesis_via_crispr_cas9 = false
      EOF
    end
  end

end