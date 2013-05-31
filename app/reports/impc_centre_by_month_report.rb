class ImpcCentreByMonthReport 

  attr_accessor :report_rows

  def initialize
    ## It's easier to display the report, if we create all the report rows while building the report.
    @report_rows = {
      ## Store an array of uniq dates to display in the report.
      :dates => []
    }

    self.generate_report
  end

  def by_month_all_injections_and_gtc_genes
    @by_month_2_columns ||= ActiveRecord::Base.connection.execute(self.class.by_month_all_injections_and_gtc_genes_sql).to_a
  end

  def by_month_report_remaining_columns
    @by_month_report ||= ActiveRecord::Base.connection.execute(self.class.by_month_report_sql).to_a
  end

  def cumulative_report
    @cumulative_report ||= ActiveRecord::Base.connection.execute(self.class.cumulative_counts_sql).to_a
  end

  def cumulative_cre
    @cumulative_cre ||= ActiveRecord::Base.connection.execute(self.class.cumulative_cre_count_sql).to_a
  end

  def cumulative_phenotype_started
    @cumulative_phenotype_started ||= ActiveRecord::Base.connection.execute(self.class.cumulative_phenotype_started_count_sql).to_a
  end

  def cumulative_phenotype_complete
    @cumulative_phenotype_complete ||= ActiveRecord::Base.connection.execute(self.class.cumulative_phenotype_complete_count_sql).to_a
  end

  def generate_report

    start_date = self.class.formatted_start_date

    @report_rows[:dates] << "To #{start_date}"

    (cumulative_report + cumulative_cre + cumulative_phenotype_started + cumulative_phenotype_complete).each do |report_row|
      centre = report_row['production_centre']

      self.class.es_cell_supply_columns.each do |column, key|
        if report_row[key] || @report_rows["To #{start_date}-#{centre}-#{column}"].blank?
          @report_rows["To #{start_date}-#{centre}-#{column}"] = report_row[key].to_i if report_row[key].to_i > 0
        end        
      end

      self.class.columns.each do |column, key|
        if report_row[key] || @report_rows["To #{start_date}-#{centre}-#{column}"].blank?
          @report_rows["To #{start_date}-#{centre}-#{column}"] = report_row[key].to_i if report_row[key].to_i > 0
        end

        if report_row["#{key}_goal"].to_i > 0
          @report_rows["To #{start_date}-#{centre}-#{column}_goal"] = report_row["#{key}_goal"]
        end
      end     
    end

    (by_month_all_injections_and_gtc_genes + by_month_report_remaining_columns).each do |report_row|
      date = Date.parse(report_row['date']).strftime('%b %Y')
      centre = report_row['production_centre']

      unless @report_rows[:dates].include?(date)
        @report_rows[:dates] << date
      end

      self.class.es_cell_supply_columns.each do |column, key|
        @report_rows["#{date}-#{centre}-#{column}"] = report_row[key].to_i if report_row[key].to_i > 0
      end

      self.class.columns.each do |column, key|
        @report_rows["#{date}-#{centre}-#{column}"] = report_row[key].to_i if report_row[key].to_i > 0

        if report_row["#{key}_goal"].to_i > 0
          @report_rows["#{date}-#{centre}-#{column}_goal"] = report_row["#{key}_goal"]
        end
      end

    end

  end

  class << self

    def es_cell_supply_columns
      {
        'ES Cell Received' => 'es_cells_received',
        'Required from EUMMCR' => 'eucomm_required',
        'Required from KOMP' => 'komp_required',
        'Required from NorCOMM' => 'norcomm_required'
      }
    end

    def columns
      {
        'Total injected clones' => 'mi_in_progress_count',
        'Total genotype confirmed genes' => 'genotype_confirmed_count',
        'Cre excised genes (or better)' => 'cre_excised_or_better_count',
        'Phenotype started genes (or better)' => 'phenotype_started_or_better_count',
        'Phenotype complete genes' => 'phenotype_complete_count'
      }
    end

    ## Start date is the first of March for that year (Except January/February where it's the previous year)
    def start_date
      year = Time.now.year

      if Time.now.month <= 2
        year = Time.now.year - 1
      end

      Date.parse("#{year}-03-01").to_s(:db)
    end

    def formatted_start_date
      (Date.parse(start_date) - 1.month).strftime('%b %Y')
    end

    ## Don't report incomplete month
    def end_date
      end_date = Time.now.to_date
      ## But do report it if it's the last day of the month.
      end_date = end_date - 1.month unless end_date == end_date.end_of_month

      end_date.to_s(:db)
    end

    def centres
      [
        'BCM',
        'HMGU',
        'Harwell',
        'ICS',
        'JAX',
        'Monterotondo',
        'RIKEN BRC',
        'TCP',
        'UCD',
        'WTSI'
      ]
    end

    def cumulative_counts_sql
      <<-EOF

      SELECT
        counts.production_centre,
        counts.mi_in_progress_count,
        counts.genotype_confirmed_count,
        counts.es_cells_received,
        mip_goals.goal AS mi_in_progress_count_goal,
        gtc_goals.goal AS genotype_confirmed_count_goal,
        eucomm_required_goals.goal as eucomm_required,
        komp_required_goals.goal as komp_required,
        norcomm_required_goals.goal as norcomm_required

      FROM (
        SELECT
          production_centre,
          SUM(CASE
            WHEN micro_injection_in_progress_date < '#{start_date}'
            THEN distinct_genotype_confirmed_es_cells
            ELSE 0
          END) +
          SUM(CASE
            WHEN micro_injection_in_progress_date < '#{start_date}'
            THEN distinct_non_genotype_confirmed_es_cells
            ELSE 0
          END) AS mi_in_progress_count,
          SUM(CASE
            WHEN genotype_confirmed_date < '#{start_date}'
            THEN gc_pipeline_efficiency_gene_count
            ELSE 0
          END) AS genotype_confirmed_count,
          SUM(mi_plans.number_of_es_cells_received) as es_cells_received

        FROM new_intermediate_report
        JOIN mi_plans ON mi_plans.id = new_intermediate_report.mi_plan_id
      
      WHERE
          production_centre = 'HMGU' AND consortium = 'Helmholtz GMC'
        OR
          production_centre = 'ICS' AND consortium IN ('Phenomin', 'Helmholtz GMC')
        OR
          production_centre in ('BCM', 'TCP', 'JAX', 'RIKEN BRC')
        OR
          production_centre = 'Harwell' AND consortium IN ('BaSH', 'MRC')
        OR
          production_centre = 'UCD' AND consortium = 'DTCC'
        OR
          production_centre = 'WTSI' AND consortium IN ('MGP', 'BaSH')
        OR
          production_centre = 'Monterotondo' AND consortium = 'Monterotondo'

        GROUP BY production_centre
        ORDER BY production_centre ASC
      ) AS counts

      JOIN centres ON centres.name = production_centre
      LEFT JOIN tracking_goals AS mip_goals ON mip_goals.date IS NULL AND centres.id = mip_goals.production_centre_id AND mip_goals.goal_type = 'total_injected_clones'
      LEFT JOIN tracking_goals AS gtc_goals ON gtc_goals.date IS NULL AND centres.id = gtc_goals.production_centre_id AND gtc_goals.goal_type = 'total_glt_clones'

      LEFT JOIN tracking_goals AS eucomm_required_goals ON eucomm_required_goals.date IS NULL AND centres.id = eucomm_required_goals.production_centre_id AND eucomm_required_goals.goal_type = 'eucomm_required'
      LEFT JOIN tracking_goals AS komp_required_goals ON komp_required_goals.date IS NULL AND centres.id = komp_required_goals.production_centre_id AND komp_required_goals.goal_type = 'komp_required'
      LEFT JOIN tracking_goals AS norcomm_required_goals ON norcomm_required_goals.date IS NULL AND centres.id = norcomm_required_goals.production_centre_id AND norcomm_required_goals.goal_type = 'norcomm_required'

      ORDER BY production_centre ASC

      EOF
    end

    def cumulative_cre_count_sql
      <<-EOF
        SELECT
          counts.name as production_centre,
          count as cre_excised_or_better_count,
          goal as cre_excised_or_better_count_goal

        FROM (
          SELECT
          plan_counts.name,
          count(*)
          FROM (
            SELECT
            centres.name,
            genes.id,
            count(mi_plans)
            FROM genes
            JOIN mi_plans ON mi_plans.gene_id = genes.id
            JOIN phenotype_attempts ON phenotype_attempts.mi_plan_id = mi_plans.id
            JOIN phenotype_attempt_status_stamps ON phenotype_attempt_status_stamps.phenotype_attempt_id = phenotype_attempts.id and phenotype_attempt_status_stamps.status_id = 6
            JOIN centres ON centres.id = mi_plans.production_centre_id

            WHERE
            phenotype_attempts.status_id in (6, 7, 8)
            AND
            phenotype_attempt_status_stamps.created_at < '#{start_date}'

            GROUP BY centres.name, genes.id
          ) as plan_counts


          GROUP BY plan_counts.name
        ) as counts

        JOIN centres ON centres.name = counts.name

        LEFT JOIN tracking_goals AS cre_goals ON cre_goals.date IS NULL AND centres.id = cre_goals.production_centre_id AND cre_goals.goal_type = 'cre_exicised_genes'
      EOF
    end

    def cumulative_phenotype_started_count_sql
      <<-EOF
        SELECT
          counts.name as production_centre,
          count as cre_excised_or_better_count,
          goal as cre_excised_or_better_count_goal

        FROM (
          SELECT
          plan_counts.name,
          count(*)
          FROM (
            SELECT
            centres.name,
            genes.id,
            count(mi_plans)
            FROM genes
            JOIN mi_plans ON mi_plans.gene_id = genes.id
            JOIN phenotype_attempts ON phenotype_attempts.mi_plan_id = mi_plans.id
            JOIN phenotype_attempt_status_stamps ON phenotype_attempt_status_stamps.phenotype_attempt_id = phenotype_attempts.id and phenotype_attempt_status_stamps.status_id = 7
            JOIN centres ON centres.id = mi_plans.production_centre_id

            WHERE
            phenotype_attempts.status_id in (7, 8)
            AND
            phenotype_attempt_status_stamps.created_at < '#{start_date}'

            GROUP BY centres.name, genes.id
          ) as plan_counts


          GROUP BY plan_counts.name
        ) as counts

        JOIN centres ON centres.name = counts.name

        LEFT JOIN tracking_goals AS cre_goals ON cre_goals.date IS NULL AND centres.id = cre_goals.production_centre_id AND cre_goals.goal_type = 'phenotype_started_genes'
      EOF
    end

    def cumulative_phenotype_complete_count_sql
      <<-EOF
        SELECT
          counts.name as production_centre,
          count as cre_excised_or_better_count,
          goal as cre_excised_or_better_count_goal

        FROM (
          SELECT
          plan_counts.name,
          count(*)
          FROM (
            SELECT
            centres.name,
            genes.id,
            count(mi_plans)
            FROM genes
            JOIN mi_plans ON mi_plans.gene_id = genes.id
            JOIN phenotype_attempts ON phenotype_attempts.mi_plan_id = mi_plans.id
            JOIN phenotype_attempt_status_stamps ON phenotype_attempt_status_stamps.phenotype_attempt_id = phenotype_attempts.id and phenotype_attempt_status_stamps.status_id = 8
            JOIN centres ON centres.id = mi_plans.production_centre_id

            WHERE
            phenotype_attempts.status_id = 8
            AND
            phenotype_attempt_status_stamps.created_at < '#{start_date}'

            GROUP BY centres.name, genes.id
          ) as plan_counts


          GROUP BY plan_counts.name
        ) as counts

        JOIN centres ON centres.name = counts.name

        LEFT JOIN tracking_goals AS cre_goals ON cre_goals.date IS NULL AND centres.id = cre_goals.production_centre_id AND cre_goals.goal_type = 'phenotype_complete_genes'
      EOF
    end

    def by_month_all_injections_and_gtc_genes_sql
      <<-EOF
        WITH
          series AS (
            SELECT generate_series('#{start_date}', '#{end_date}', interval '1 month')::date as date
          ),
          counts AS (
            SELECT
            series.date,
            production_centre,
            SUM(CASE
              WHEN micro_injection_in_progress_date >= series.date AND micro_injection_in_progress_date < date(series.date + interval '1 month')
              THEN distinct_genotype_confirmed_es_cells
              ELSE 0
            END) +
            SUM(CASE
              WHEN micro_injection_in_progress_date >= series.date AND micro_injection_in_progress_date < date(series.date + interval '1 month')
              THEN distinct_non_genotype_confirmed_es_cells
              ELSE 0
            END) AS mi_in_progress_count,
            SUM(CASE
              WHEN genotype_confirmed_date >= series.date AND genotype_confirmed_date < date(series.date + interval '1 month')
              THEN gc_pipeline_efficiency_gene_count
              ELSE 0
            END) AS genotype_confirmed_count,
            SUM(CASE
              WHEN mi_plans.es_cells_received_on >= series.date AND mi_plans.es_cells_received_on < date(series.date + interval '1 month')
              THEN mi_plans.number_of_es_cells_received
              ELSE 0
            END) AS es_cells_received
            
          FROM series
          CROSS JOIN new_intermediate_report
          JOIN mi_plans ON mi_plans.id = new_intermediate_report.mi_plan_id

          WHERE
            production_centre = 'HMGU' AND consortium = 'Helmholtz GMC'
          OR
            production_centre = 'ICS' AND consortium IN ('Phenomin', 'Helmholtz GMC')
          OR
            production_centre in ('BCM', 'TCP', 'JAX', 'RIKEN BRC')
          OR
            production_centre = 'Harwell' AND consortium IN ('BaSH', 'MRC')
          OR
            production_centre = 'UCD' AND consortium = 'DTCC'
          OR
            production_centre = 'WTSI' AND consortium IN ('MGP', 'BaSH')
          OR
            production_centre = 'Monterotondo' AND consortium = 'Monterotondo'

          GROUP BY
            series.date,
            production_centre
          ORDER BY series.date ASC, production_centre ASC
        )

        SELECT
          counts.date,
          counts.production_centre,
          counts.mi_in_progress_count,
          counts.genotype_confirmed_count,
          counts.es_cells_received,
          mip_goals.goal AS mi_in_progress_count_goal,
          gtc_goals.goal  AS genotype_confirmed_count_goal,
          eucomm_required_goals.goal AS eucomm_required,
          komp_required_goals.goal AS komp_required,
          norcomm_required_goals.goal AS norcomm_required

        FROM counts

        LEFT JOIN centres ON centres.name = counts.production_centre
        LEFT JOIN tracking_goals AS mip_goals ON counts.date = mip_goals.date AND centres.id = mip_goals.production_centre_id AND mip_goals.goal_type = 'total_injected_clones'
        LEFT JOIN tracking_goals AS gtc_goals ON counts.date = gtc_goals.date AND centres.id = gtc_goals.production_centre_id AND gtc_goals.goal_type = 'total_glt_clones'

        LEFT JOIN tracking_goals AS eucomm_required_goals ON eucomm_required_goals.date = counts.date AND centres.id = eucomm_required_goals.production_centre_id AND eucomm_required_goals.goal_type = 'eucomm_required'
        LEFT JOIN tracking_goals AS komp_required_goals ON komp_required_goals.date = counts.date AND centres.id = komp_required_goals.production_centre_id AND komp_required_goals.goal_type = 'komp_required'
        LEFT JOIN tracking_goals AS norcomm_required_goals ON norcomm_required_goals.date = counts.date AND centres.id = norcomm_required_goals.production_centre_id AND norcomm_required_goals.goal_type = 'norcomm_required'


        ORDER BY counts.date ASC
      EOF
    end

    def by_month_report_sql
      <<-EOF
        WITH
          series AS (
            SELECT generate_series('#{start_date}', '#{end_date}', interval '1 month')::date as date
          ),
          counts AS (
          
            SELECT
              series.date,
              production_centre,
              SUM(CASE
                WHEN counts.count > 0 AND cre_date >= series.date AND cre_date < date(series.date + interval '1 month')
                THEN 1
                ELSE 0
              END) as cre_excised_or_better_count,
                SUM(CASE
                WHEN counts.count > 0 AND ps_date >= series.date AND ps_date < date(series.date + interval '1 month')
                THEN 1
                ELSE 0
              END) as phenotype_started_or_better_count,
              SUM(CASE
                WHEN counts.count > 0 AND pc_date >= series.date AND pc_date < date(series.date + interval '1 month')
                THEN 1
                ELSE 0
              END) as phenotype_complete_count
            FROM (
              SELECT
                genes.id as gene_id,
                centres.name as production_centre,
                cre_stamps.created_at as cre_date,
                ps_stamps.created_at as ps_date,
                pc_stamps.created_at as pc_date,
                count(*)
              FROM genes
              JOIN mi_plans ON mi_plans.gene_id = genes.id
              JOIN phenotype_attempts ON mi_plans.id = phenotype_attempts.mi_plan_id
              JOIN centres ON centres.id = mi_plans.production_centre_id
              LEFT JOIN phenotype_attempt_status_stamps as cre_stamps ON phenotype_attempts.id = cre_stamps.phenotype_attempt_id AND cre_stamps.status_id = 6 AND cre_stamps.created_at >= '#{start_date}' 
              LEFT JOIN phenotype_attempt_status_stamps as ps_stamps ON phenotype_attempts.id = ps_stamps.phenotype_attempt_id AND ps_stamps.status_id = 7 AND ps_stamps.created_at >= '#{start_date}' 
              LEFT JOIN phenotype_attempt_status_stamps as pc_stamps ON phenotype_attempts.id = pc_stamps.phenotype_attempt_id AND pc_stamps.status_id = 8 AND pc_stamps.created_at >= '#{start_date}' 
              JOIN consortia ON consortia.id = mi_plans.consortium_id

              WHERE
                centres.name = 'HMGU' AND consortia.name = 'Helmholtz GMC'
              OR
                centres.name = 'ICS' AND consortia.name IN ('Phenomin', 'Helmholtz GMC')
              OR
                centres.name in ('BCM', 'TCP', 'JAX', 'RIKEN BRC')
              OR
                centres.name = 'Harwell' AND consortia.name IN ('BaSH', 'MRC')
              OR
                centres.name = 'UCD' AND consortia.name = 'DTCC'
              OR
                centres.name = 'WTSI' AND consortia.name IN ('MGP', 'BaSH')
              OR
                centres.name = 'Monterotondo' AND consortia.name = 'Monterotondo'   
              GROUP BY genes.id, production_centre, cre_date, ps_date, pc_date
              ORDER BY production_centre ASC
            ) as counts
            CROSS JOIN series
            GROUP BY series.date, counts.production_centre
          )

          SELECT
            counts.date,
            counts.production_centre,
            counts.cre_excised_or_better_count,
            counts.phenotype_started_or_better_count,
            counts.phenotype_complete_count,
            cre_goals.goal AS cre_excised_or_better_count_goal,
            ps_goals.goal  AS phenotype_started_or_better_count_goal,
            pc_goals.goal  AS phenotype_complete_count_goal

          FROM counts

          LEFT JOIN centres ON centres.name = counts.production_centre
          LEFT JOIN tracking_goals AS cre_goals ON counts.date = cre_goals.date AND centres.id = cre_goals.production_centre_id AND cre_goals.goal_type = 'cre_exicised_genes'
          LEFT JOIN tracking_goals AS ps_goals ON counts.date = ps_goals.date AND centres.id = ps_goals.production_centre_id AND ps_goals.goal_type = 'phenotype_started_genes'
          LEFT JOIN tracking_goals AS pc_goals ON counts.date = pc_goals.date AND centres.id = pc_goals.production_centre_id AND pc_goals.goal_type = 'phenotype_complete_genes'

      EOF
    end

  end

end