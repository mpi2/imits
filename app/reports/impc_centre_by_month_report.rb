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

  def by_month_clones
    @by_month_clones ||= ActiveRecord::Base.connection.execute(self.class.by_month_clones_sql).to_a
  end

  def by_month_report
    @by_month_report ||= ActiveRecord::Base.connection.execute(self.class.by_month_report_sql).to_a
  end

  def cumulative_report
    @cumulative_report ||= ActiveRecord::Base.connection.execute(self.class.cumulative_counts_sql).to_a
  end

  def cumulative_gene_count
    @cumulative_cre ||= ActiveRecord::Base.connection.execute(self.class.cumulative_gene_count_sql).to_a
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

    (cumulative_report + cumulative_gene_count).each do |report_row|
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

    (by_month_clones + by_month_report).each do |report_row|
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
        WITH
          injected_es_cells AS (
            SELECT
              targ_rep_es_cells.id AS es_cell_id,
              centres.name AS production_centre,
              count(*) AS mi_in_progress_count,
              SUM(mi_plans.number_of_es_cells_received) as es_cells_received

            FROM targ_rep_es_cells
            JOIN mi_attempts ON mi_attempts.es_cell_id = targ_rep_es_cells.id
            JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
            JOIN centres ON centres.id = mi_plans.production_centre_id
            JOIN consortia ON consortia.id = mi_plans.consortium_id

            JOIN mi_attempt_status_stamps as mip_stamps ON mi_attempts.id = mip_stamps.mi_attempt_id AND mip_stamps.status_id = 1 AND mip_stamps.created_at < '#{start_date}' 

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

            GROUP BY
              targ_rep_es_cells.id,
              centres.name
            ORDER BY
              centres.name ASC,
              es_cell_id ASC
        ), counts AS (
          SELECT
            injected_es_cells.production_centre,
            SUM(CASE
              WHEN injected_es_cells.mi_in_progress_count > 0
              THEN 1
              ELSE 0
            END) as mi_in_progress_count,
            SUM(injected_es_cells.es_cells_received) as es_cells_received

          FROM injected_es_cells
          GROUP BY
            injected_es_cells.production_centre
          ORDER BY injected_es_cells.production_centre ASC
        )

          

          SELECT
            counts.production_centre,
            counts.mi_in_progress_count,
            counts.es_cells_received,
            mip_goals.goal AS mi_in_progress_count_goal,
            eucomm_required_goals.goal as eucomm_required,
            komp_required_goals.goal as komp_required,
            norcomm_required_goals.goal as norcomm_required

          FROM counts

          JOIN centres ON centres.name = production_centre
          LEFT JOIN tracking_goals AS mip_goals ON mip_goals.date IS NULL AND centres.id = mip_goals.production_centre_id AND mip_goals.goal_type = 'total_injected_clones'

          LEFT JOIN tracking_goals AS eucomm_required_goals ON eucomm_required_goals.date IS NULL AND centres.id = eucomm_required_goals.production_centre_id AND eucomm_required_goals.goal_type = 'eucomm_required'
          LEFT JOIN tracking_goals AS komp_required_goals ON komp_required_goals.date IS NULL AND centres.id = komp_required_goals.production_centre_id AND komp_required_goals.goal_type = 'komp_required'
          LEFT JOIN tracking_goals AS norcomm_required_goals ON norcomm_required_goals.date IS NULL AND centres.id = norcomm_required_goals.production_centre_id AND norcomm_required_goals.goal_type = 'norcomm_required'

          ORDER BY
            production_centre ASC
      EOF
    end

    def cumulative_gene_count_sql
      <<-EOF

        WITH
           genes_with_plans AS (
                SELECT
                  genes.id AS gene_id,
                  mi_plans.id AS mi_plan_id,
                  centres.name AS production_centre_name,
                  consortia.name AS consortium_name
                FROM genes
                JOIN mi_plans ON mi_plans.gene_id = genes.id
                JOIN centres ON centres.id = mi_plans.production_centre_id
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

        ),

        gtc_gene_centres AS (
          SELECT
            genes_with_plans.gene_id as gene_id,
            genes_with_plans.production_centre_name as production_centre,
            count(*) as genotype_confirmed_count
          FROM genes_with_plans
          JOIN mi_attempts ON genes_with_plans.mi_plan_id = mi_attempts.mi_plan_id
          LEFT JOIN mi_attempt_status_stamps as gtc_stamps ON mi_attempts.id = gtc_stamps.mi_attempt_id AND gtc_stamps.status_id = 2 AND gtc_stamps.created_at < '#{start_date}'

          GROUP BY
            genes_with_plans.gene_id,
            genes_with_plans.production_centre_name
                  
          ORDER BY genes_with_plans.production_centre_name ASC
        ),

        gtc_centres AS (
          SELECT
            gtc_gene_centres.production_centre,
            SUM(CASE
              WHEN genotype_confirmed_count > 0
              THEN 1 ELSE 0
            END) as genotype_confirmed_count
          FROM gtc_gene_centres
          GROUP BY
            production_centre
          ORDER BY
            production_centre ASC
        ),

        phenotype_gene_centres AS (
          SELECT
            genes_with_plans.gene_id as gene_id,
            genes_with_plans.production_centre_name as production_centre,
            count(cre_stamps.*) as cre_excised_or_better_count,
            count(ps_stamps.*) as phenotype_started_or_better_count,
            count(pc_stamps.*) as phenotype_complete_count
          FROM genes_with_plans
          JOIN phenotype_attempts ON genes_with_plans.mi_plan_id = phenotype_attempts.mi_plan_id
          LEFT JOIN phenotype_attempt_status_stamps as cre_stamps ON phenotype_attempts.id = cre_stamps.phenotype_attempt_id AND cre_stamps.status_id = 6 AND cre_stamps.created_at < '#{start_date}'
          LEFT JOIN phenotype_attempt_status_stamps as ps_stamps ON phenotype_attempts.id = ps_stamps.phenotype_attempt_id AND ps_stamps.status_id = 7 AND ps_stamps.created_at < '#{start_date}'
          LEFT JOIN phenotype_attempt_status_stamps as pc_stamps ON phenotype_attempts.id = pc_stamps.phenotype_attempt_id AND pc_stamps.status_id = 8 AND pc_stamps.created_at < '#{start_date}'

          GROUP BY
            genes_with_plans.gene_id,
            genes_with_plans.production_centre_name
                  
          ORDER BY genes_with_plans.production_centre_name ASC
        ),

        phenotype_centres AS (
          SELECT
            phenotype_gene_centres.production_centre,
            SUM(CASE
              WHEN cre_excised_or_better_count > 0
              THEN 1 ELSE 0
            END) as cre_excised_or_better_count,
            SUM(CASE
              WHEN phenotype_started_or_better_count > 0
              THEN 1 ELSE 0
            END) as phenotype_started_or_better_count,
            SUM(CASE
              WHEN phenotype_complete_count > 0
              THEN 1 ELSE 0
            END) as phenotype_complete_count
          FROM phenotype_gene_centres
          GROUP BY
            production_centre
          ORDER BY
            production_centre ASC
        )



         SELECT
                  gtc_centres.production_centre,
                  gtc_centres.genotype_confirmed_count,
                  phenotype_centres.cre_excised_or_better_count,
                  phenotype_centres.phenotype_started_or_better_count,
                  phenotype_centres.phenotype_complete_count,

          cre_goals.goal as cre_excised_or_better_count_goal,
          ps_goals.goal as phenotype_started_or_better_count_goal,
          pc_goals.goal as phenotype_complete_count_goal

                FROM gtc_centres

                LEFT JOIN phenotype_centres ON phenotype_centres.production_centre = gtc_centres.production_centre
                JOIN centres ON centres.name = gtc_centres.production_centre

          LEFT JOIN tracking_goals AS cre_goals ON cre_goals.date IS NULL AND centres.id = cre_goals.production_centre_id AND cre_goals.goal_type = 'cre_exicised_genes'
          LEFT JOIN tracking_goals AS ps_goals ON ps_goals.date IS NULL AND centres.id = ps_goals.production_centre_id AND ps_goals.goal_type = 'phenotype_started_genes'
          LEFT JOIN tracking_goals AS pc_goals ON pc_goals.date IS NULL AND centres.id = pc_goals.production_centre_id AND pc_goals.goal_type = 'phenotype_complete_genes'



      EOF
    end

    def by_month_clones_sql
      <<-EOF
        WITH series AS (
          SELECT generate_series('#{start_date}', '#{end_date}', interval '1 month')::date as date
        ),
        clones_with_plans AS (
        SELECT
          targ_rep_es_cells.id AS es_cell_id,
          mi_plans.id AS mi_plan_id,
          centres.name AS production_centre,
          date_trunc('MONTH', mip_stamps.created_at) as mip_date
        FROM targ_rep_es_cells
        JOIN mi_attempts ON mi_attempts.es_cell_id = targ_rep_es_cells.id
        JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
        JOIN centres ON centres.id = mi_plans.production_centre_id
        JOIN consortia ON consortia.id = mi_plans.consortium_id

        JOIN mi_attempt_status_stamps as mip_stamps ON mi_attempts.id = mip_stamps.mi_attempt_id AND mip_stamps.status_id = 1 AND mip_stamps.created_at >= '#{start_date}' 

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

        GROUP BY
          targ_rep_es_cells.id,
          mi_plans.id,
          centres.name,
          mip_stamps.created_at
        ),

        counts AS (
          SELECT
            series.date,
            clones_with_plans.production_centre,
            SUM(CASE
              WHEN clones_with_plans.mip_date = series.date
              THEN 1
              ELSE 0
            END) as mi_in_progress_count

          FROM clones_with_plans
          CROSS JOIN series
          GROUP BY
            series.date,
            clones_with_plans.production_centre
          ORDER BY series.date ASC
        )


        SELECT
          counts.date,
          counts.production_centre,
          counts.mi_in_progress_count,
          mip_goals.goal AS mi_in_progress_count_goal

        FROM counts
        JOIN centres ON centres.name = counts.production_centre

        LEFT JOIN tracking_goals AS mip_goals ON counts.date = mip_goals.date AND centres.id = mip_goals.production_centre_id AND mip_goals.goal_type = 'total_injected_clones'

        ORDER BY counts.date ASC, counts.production_centre ASC
      EOF
    end

    def by_month_report_sql
      <<-EOF
        WITH series AS (
          SELECT generate_series('#{start_date}', '#{end_date}', interval '1 month')::date as date
        ),
        genes_with_plans AS (
        SELECT
          genes.id AS gene_id,
          mi_plans.id AS mi_plan_id,
          centres.name AS production_centre_name,
          consortia.name AS consortium_name
        FROM genes
        JOIN mi_plans ON mi_plans.gene_id = genes.id
        JOIN centres ON centres.id = mi_plans.production_centre_id
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
        ),

        gtc_gene_centres AS (
          SELECT
            genes_with_plans.gene_id as gene_id,
            genes_with_plans.production_centre_name as production_centre,
            date_trunc('MONTH', gtc_stamps.created_at) as gtc_date
          FROM genes_with_plans
          JOIN mi_attempts ON genes_with_plans.mi_plan_id = mi_attempts.mi_plan_id
          LEFT JOIN mi_attempt_status_stamps as gtc_stamps ON mi_attempts.id = gtc_stamps.mi_attempt_id AND gtc_stamps.status_id = 2 AND gtc_stamps.created_at >= '#{start_date}' 

          GROUP BY
            genes_with_plans.gene_id,
            genes_with_plans.production_centre_name,
            gtc_date
          
          ORDER BY genes_with_plans.production_centre_name ASC
        ),

        gtc_centres AS (
          SELECT
            series.date,
            gtc_gene_centres.production_centre,
            SUM(CASE
              WHEN gtc_gene_centres.gtc_date = series.date
              THEN 1
              ELSE 0
            END) as genotype_confirmed_count

          FROM gtc_gene_centres
          CROSS JOIN series
          GROUP BY
            series.date,
            gtc_gene_centres.production_centre
          ORDER BY series.date ASC
        ),

        phenotype_gene_centres AS (
          SELECT
            genes_with_plans.gene_id as gene_id,
            genes_with_plans.production_centre_name as production_centre,
            date_trunc('MONTH', cre_stamps.created_at) as cre_date,
            date_trunc('MONTH', ps_stamps.created_at) as ps_date,
            date_trunc('MONTH', pc_stamps.created_at) as pc_date
          FROM genes_with_plans
          JOIN phenotype_attempts ON genes_with_plans.mi_plan_id = phenotype_attempts.mi_plan_id
          LEFT JOIN phenotype_attempt_status_stamps as cre_stamps ON phenotype_attempts.id = cre_stamps.phenotype_attempt_id AND cre_stamps.status_id = 6 AND cre_stamps.created_at >= '#{start_date}' 
          LEFT JOIN phenotype_attempt_status_stamps as ps_stamps ON phenotype_attempts.id = ps_stamps.phenotype_attempt_id AND ps_stamps.status_id = 7 AND ps_stamps.created_at >= '#{start_date}' 
          LEFT JOIN phenotype_attempt_status_stamps as pc_stamps ON phenotype_attempts.id = pc_stamps.phenotype_attempt_id AND pc_stamps.status_id = 8 AND pc_stamps.created_at >= '#{start_date}' 

          GROUP BY
            genes_with_plans.gene_id,
            genes_with_plans.production_centre_name,
            cre_date,
            ps_date,
            pc_date
          ORDER BY genes_with_plans.production_centre_name ASC
        ),

        phenotype_centres AS (
          SELECT
            series.date,
            phenotype_gene_centres.production_centre,
            SUM(CASE
              WHEN phenotype_gene_centres.cre_date = series.date
              THEN 1
              ELSE 0
            END) as cre_excised_or_better_count,
            SUM(CASE
              WHEN phenotype_gene_centres.ps_date = series.date
              THEN 1
              ELSE 0
            END) as phenotype_started_or_better_count,
            SUM(CASE
              WHEN phenotype_gene_centres.pc_date = series.date
              THEN 1
              ELSE 0
            END) as phenotype_complete_count

          FROM phenotype_gene_centres
          CROSS JOIN series
          GROUP BY
            series.date,
            phenotype_gene_centres.production_centre
          ORDER BY series.date ASC
        )

        SELECT
          gtc_centres.date,
          gtc_centres.production_centre,
          gtc_centres.genotype_confirmed_count,
          phenotype_centres.cre_excised_or_better_count,
          phenotype_centres.phenotype_started_or_better_count,
          phenotype_centres.phenotype_complete_count,

          gtc_goals.goal  AS genotype_confirmed_count_goal,
          cre_goals.goal AS cre_excised_or_better_count_goal,
          ps_goals.goal  AS phenotype_started_or_better_count_goal,
          pc_goals.goal  AS phenotype_complete_count_goal,

          eucomm_required_goals.goal AS eucomm_required,
          komp_required_goals.goal AS komp_required,
          norcomm_required_goals.goal AS norcomm_required

        FROM gtc_centres

        LEFT JOIN phenotype_centres ON phenotype_centres.date = gtc_centres.date AND phenotype_centres.production_centre = gtc_centres.production_centre
        JOIN centres ON centres.name = gtc_centres.production_centre

        LEFT JOIN tracking_goals AS gtc_goals ON gtc_centres.date = gtc_goals.date AND centres.id = gtc_goals.production_centre_id AND gtc_goals.goal_type = 'total_glt_clones'

        LEFT JOIN tracking_goals AS cre_goals ON gtc_centres.date = cre_goals.date AND centres.id = cre_goals.production_centre_id AND cre_goals.goal_type = 'cre_exicised_genes'
        LEFT JOIN tracking_goals AS ps_goals ON gtc_centres.date = ps_goals.date AND centres.id = ps_goals.production_centre_id AND ps_goals.goal_type = 'phenotype_started_genes'
        LEFT JOIN tracking_goals AS pc_goals ON gtc_centres.date = pc_goals.date AND centres.id = pc_goals.production_centre_id AND pc_goals.goal_type = 'phenotype_complete_genes'

        LEFT JOIN tracking_goals AS eucomm_required_goals ON eucomm_required_goals.date = gtc_centres.date AND centres.id = eucomm_required_goals.production_centre_id AND eucomm_required_goals.goal_type = 'eucomm_required'
        LEFT JOIN tracking_goals AS komp_required_goals ON komp_required_goals.date = gtc_centres.date AND centres.id = komp_required_goals.production_centre_id AND komp_required_goals.goal_type = 'komp_required'
        LEFT JOIN tracking_goals AS norcomm_required_goals ON norcomm_required_goals.date = gtc_centres.date AND centres.id = norcomm_required_goals.production_centre_id AND norcomm_required_goals.goal_type = 'norcomm_required'


        ORDER BY gtc_centres.date ASC, gtc_centres.production_centre ASC
      EOF
    end

  end

end