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

  def by_month_genes
    @by_month_genes ||= ActiveRecord::Base.connection.execute(self.class.by_month_genes_sql).to_a
  end

  def cumulative_clones
    @cumulative_clones ||= ActiveRecord::Base.connection.execute(self.class.cumulative_clones_sql(self.class.real_start_date) ).to_a
  end

  def cumulative_genes
    @cumulative_cre ||= ActiveRecord::Base.connection.execute(self.class.cumulative_genes_sql(self.class.real_start_date) ).to_a
  end

  def cumulative_received
    @cumulative_received ||= ActiveRecord::Base.connection.execute(self.class.cumulative_received_sql(self.class.real_start_date) ).to_a
  end

  def by_month_received
    @by_month_received ||= ActiveRecord::Base.connection.execute(self.class.by_month_received_sql).to_a
  end

  def cumulative_totals
    @total_to_date ||= generate_cumulatives
  end

  def generate_cumulatives
    total_to_date = {}

    to_date_cumulative ||= ActiveRecord::Base.connection.execute(self.class.cumulative_genes_sql(self.class.end_date) ).to_a
    to_date_clones = ActiveRecord::Base.connection.execute(self.class.cumulative_clones_sql(self.class.end_date) ).to_a
    to_date_received = ActiveRecord::Base.connection.execute(self.class.cumulative_received_sql(self.class.end_date) ).to_a

    (to_date_clones + to_date_cumulative).each do |report_row|
      centre = report_row['production_centre']
      total_to_date[centre] = {} if ! total_to_date[centre]
      self.class.columns.each do |column, key|
        total_to_date[centre]["#{key}_cumulative"] = report_row[key].to_i if report_row[key].to_i > 0

        if report_row["#{key}_goal"].to_i > 0
          total_to_date[centre]["#{key}_goal_cumulative"] = report_row["#{key}_goal"]
        end
      end
    end

    to_date_received.each do |report_row|
      centre = report_row['production_centre']
      total_to_date[centre] = {} if ! total_to_date[centre]
      self.class.es_cell_supply_columns.each do |column, key|
        total_to_date[centre]["#{key}_cumulative"] = report_row[key].to_i if report_row[key].to_i > 0
      end
    end

    return total_to_date
  end

  def generate_report

    start_date = self.class.formatted_start_date

    @report_rows[:dates] << "To #{start_date}"

    (cumulative_clones + cumulative_genes).each do |report_row|
      centre = report_row['production_centre']

      self.class.columns.each do |column, key|
        if report_row[key] || @report_rows["To #{start_date}-#{centre}-#{column}"].blank?
          @report_rows["To #{start_date}-#{centre}-#{column}"] = report_row[key].to_i if report_row[key].to_i > 0
        end

        if report_row["#{key}_goal"].to_i > 0
          @report_rows["To #{start_date}-#{centre}-#{column}_goal"] = report_row["#{key}_goal"]
        end
      end
    end

    (by_month_clones + by_month_genes).each do |report_row|
      date = Date.parse(report_row['date']).strftime('%b %Y')
      centre = report_row['production_centre']

      unless @report_rows[:dates].include?(date)
        @report_rows[:dates] << date
      end

      self.class.columns.each do |column, key|
        @report_rows["#{date}-#{centre}-#{column}"] = report_row[key].to_i if report_row[key].to_i > 0

        if report_row["#{key}_goal"].to_i > 0
          @report_rows["#{date}-#{centre}-#{column}_goal"] = report_row["#{key}_goal"]
        end
      end

    end

    cumulative_received.each do |report_row|
      centre = report_row['production_centre']

      self.class.es_cell_supply_columns.each do |column, key|
        if report_row[key] || @report_rows["To #{start_date}-#{centre}-#{column}"].blank?
          @report_rows["To #{start_date}-#{centre}-#{column}"] = report_row[key].to_i if report_row[key].to_i > 0
        end
      end
    end

    by_month_received.each do |report_row|
      date = Date.parse(report_row['date']).strftime('%b %Y')
      centre = report_row['production_centre']

      unless @report_rows[:dates].include?(date)
        @report_rows[:dates] << date
      end

      self.class.es_cell_supply_columns.each do |column, key|
        @report_rows["#{date}-#{centre}-#{column}"] = report_row[key].to_i if report_row[key].to_i > 0
      end
    end

  end

  class << self

    def es_cell_supply_columns
      {
        'ES Cell Received' => 'es_cells_received',
        'Required from EUMMCR' => 'eucomm_required',
        'Required from KOMP' => 'komp_required',
        'Required from NorCOMM' => 'norcomm_required',
        'Required from WTSI' => 'wtsi_required'
      }
    end

    def columns
      {
        'Total injected clones' => 'mi_in_progress_count',
        'Total genotype confirmed genes' => 'genotype_confirmed_count',
        'Cre excised genes' => 'cre_excised_or_better_count',
        'Phenotype started genes' => 'phenotype_started_or_better_count',
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

    def real_start_date
      Date.parse(start_date) - 1.month
    end

    def formatted_start_date
      Date.parse(real_start_date.to_s).strftime('%b %Y')
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

    def cumulative_clones_sql(cut_off_date)
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

            JOIN mi_attempt_status_stamps as mip_stamps ON mi_attempts.id = mip_stamps.mi_attempt_id AND mip_stamps.status_id = 1 AND mip_stamps.created_at < '#{cut_off_date}'

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
            clone_goals.mip_goals AS mi_in_progress_count_goal

          FROM counts

          JOIN centres ON centres.name = production_centre
          LEFT JOIN
          (
          SELECT
            production_centre_id,
            SUM(CASE WHEN tracking_goals.goal_type = 'total_injected_clones' THEN tracking_goals.goal ELSE 0 END) AS mip_goals
          FROM tracking_goals
          WHERE tracking_goals.date IS NULL OR to_number(to_char(tracking_goals.date, 'YYYYMM'),'999999' ) <= (#{(cut_off_date.to_date.strftime('%Y%m'))})
                AND tracking_goals.goal_type = 'total_injected_clones'
          GROUP BY production_centre_id

        ) AS clone_goals ON clone_goals.production_centre_id = centres.id

          ORDER BY
            production_centre ASC
      EOF
    end

    def cumulative_genes_sql (cut_off_date)
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
            count(gtc_stamps.*) as genotype_confirmed_count
          FROM genes_with_plans
          JOIN mi_attempts ON genes_with_plans.mi_plan_id = mi_attempts.mi_plan_id and mi_attempts.status_id != 3
          LEFT JOIN mi_attempt_status_stamps as gtc_stamps ON mi_attempts.id = gtc_stamps.mi_attempt_id AND gtc_stamps.status_id = 2 AND gtc_stamps.created_at < '#{cut_off_date}'

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
          JOIN phenotype_attempts ON genes_with_plans.mi_plan_id = phenotype_attempts.mi_plan_id AND phenotype_attempts.status_id != 1
          LEFT JOIN phenotype_attempt_status_stamps as cre_stamps ON phenotype_attempts.id = cre_stamps.phenotype_attempt_id AND cre_stamps.status_id = 6 AND cre_stamps.created_at < '#{cut_off_date}'
          LEFT JOIN phenotype_attempt_status_stamps as ps_stamps ON phenotype_attempts.id = ps_stamps.phenotype_attempt_id AND ps_stamps.status_id = 7 AND ps_stamps.created_at < '#{cut_off_date}'
          LEFT JOIN phenotype_attempt_status_stamps as pc_stamps ON phenotype_attempts.id = pc_stamps.phenotype_attempt_id AND pc_stamps.status_id = 8 AND pc_stamps.created_at < '#{cut_off_date}'

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

          gene_goals.gtc_goals as genotype_confirmed_count_goal,
          gene_goals.cre_goals as cre_excised_or_better_count_goal,
          gene_goals.ps_goals as phenotype_started_or_better_count_goal,
          gene_goals.pc_goals as phenotype_complete_count_goal

                FROM gtc_centres

                LEFT JOIN phenotype_centres ON phenotype_centres.production_centre = gtc_centres.production_centre
                JOIN centres ON centres.name = gtc_centres.production_centre

          LEFT JOIN
          (
          SELECT
            production_centre_id,
            SUM(CASE WHEN tracking_goals.goal_type = 'total_glt_clones' THEN tracking_goals.goal ELSE 0 END) AS gtc_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'cre_exicised_genes' THEN tracking_goals.goal ELSE 0 END) AS cre_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'phenotype_started_genes' THEN tracking_goals.goal ELSE 0 END) AS ps_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'phenotype_complete_genes' THEN tracking_goals.goal ELSE 0 END) AS pc_goals
          FROM tracking_goals
          WHERE tracking_goals.date IS NULL OR to_number(to_char(tracking_goals.date, 'YYYYMM'),'999999' ) <= (#{(cut_off_date.to_date.strftime('%Y%m'))})
                AND tracking_goals.goal_type IN ('total_glt_clones', 'cre_exicised_genes', 'phenotype_started_genes', 'phenotype_complete_genes' )
          GROUP BY production_centre_id

        ) AS gene_goals ON gene_goals.production_centre_id = centres.id

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

    def by_month_genes_sql
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
          JOIN mi_attempts ON genes_with_plans.mi_plan_id = mi_attempts.mi_plan_id AND mi_attempts.status_id != 3
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
          JOIN phenotype_attempts ON genes_with_plans.mi_plan_id = phenotype_attempts.mi_plan_id AND phenotype_attempts.status_id != 1
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
          pc_goals.goal  AS phenotype_complete_count_goal

        FROM gtc_centres

        LEFT JOIN phenotype_centres ON phenotype_centres.date = gtc_centres.date AND phenotype_centres.production_centre = gtc_centres.production_centre
        JOIN centres ON centres.name = gtc_centres.production_centre

        LEFT JOIN tracking_goals AS gtc_goals ON gtc_centres.date = gtc_goals.date AND centres.id = gtc_goals.production_centre_id AND gtc_goals.goal_type = 'total_glt_clones'

        LEFT JOIN tracking_goals AS cre_goals ON gtc_centres.date = cre_goals.date AND centres.id = cre_goals.production_centre_id AND cre_goals.goal_type = 'cre_exicised_genes'
        LEFT JOIN tracking_goals AS ps_goals ON gtc_centres.date = ps_goals.date AND centres.id = ps_goals.production_centre_id AND ps_goals.goal_type = 'phenotype_started_genes'
        LEFT JOIN tracking_goals AS pc_goals ON gtc_centres.date = pc_goals.date AND centres.id = pc_goals.production_centre_id AND pc_goals.goal_type = 'phenotype_complete_genes'

        ORDER BY gtc_centres.date ASC, gtc_centres.production_centre ASC
      EOF
    end

    def cumulative_received_sql (cut_off_date)
      <<-EOF
        SELECT
          production_centre,
          es_cells_received,
          required_goals.eucomm_required_goals as eucomm_required,
          required_goals.komp_required_goals as komp_required,
          required_goals.norcomm_required_goals as norcomm_required,
          required_goals.wtsi_required_goals as wtsi_required

        FROM (
        SELECT
          centres.name as production_centre,
          centres.id as production_centre_id,
          SUM(number_of_es_cells_received) as es_cells_received

        FROM mi_plans

        JOIN centres ON centres.id = mi_plans.production_centre_id
        JOIN consortia ON consortia.id = mi_plans.consortium_id

          WHERE
            (
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
            )

            AND mi_plans.es_cells_received_on < '#{cut_off_date}'

        GROUP BY
          centres.name,
          centres.id
        ) AS counts

        LEFT JOIN (
          SELECT
            production_centre_id,
            SUM(CASE WHEN tracking_goals.goal_type = 'eucomm_required' THEN tracking_goals.goal ELSE 0 END) AS eucomm_required_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'komp_required' THEN tracking_goals.goal ELSE 0 END) AS komp_required_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'norcomm_required' THEN tracking_goals.goal ELSE 0 END) AS norcomm_required_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'wtsi_required' THEN tracking_goals.goal ELSE 0 END) AS wtsi_required_goals
          FROM tracking_goals
          WHERE tracking_goals.date IS NULL OR to_number(to_char(tracking_goals.date, 'YYYYMM'),'999999' ) <= (#{(cut_off_date.to_date.strftime('%Y%m'))})
                AND tracking_goals.goal_type IN ('eucomm_required', 'komp_required', 'norcomm_required', 'wtsi_required' )
          GROUP BY production_centre_id

        ) AS required_goals ON required_goals.production_centre_id = counts.production_centre_id

      EOF
    end

    def by_month_received_sql
      <<-EOF
        WITH series AS (
          SELECT generate_series('#{start_date}', '#{end_date}', interval '1 month')::date as date
        ),

        counts AS (
          SELECT
            series.date,
            centres.name as production_centre,
            centres.id as production_centre_id,
            SUM(CASE
              WHEN date_trunc('MONTH', es_cells_received_on) = series.date
              THEN number_of_es_cells_received ELSE 0
            END) as es_cells_received

          FROM mi_plans
          CROSS JOIN series

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

          GROUP BY
            series.date,
            centres.name,
            centres.id
        )

        SELECT
          counts.date,
          production_centre,
          es_cells_received,
          eucomm_required_goals.goal as eucomm_required,
          komp_required_goals.goal as komp_required,
          norcomm_required_goals.goal as norcomm_required,
          wtsi_required_goals.goal as wtsi_required

        FROM counts

        LEFT JOIN tracking_goals AS eucomm_required_goals ON eucomm_required_goals.date = counts.date AND counts.production_centre_id = eucomm_required_goals.production_centre_id AND eucomm_required_goals.goal_type = 'eucomm_required'
        LEFT JOIN tracking_goals AS komp_required_goals ON komp_required_goals.date = counts.date AND counts.production_centre_id = komp_required_goals.production_centre_id AND komp_required_goals.goal_type = 'komp_required'
        LEFT JOIN tracking_goals AS norcomm_required_goals ON norcomm_required_goals.date = counts.date AND counts.production_centre_id = norcomm_required_goals.production_centre_id AND norcomm_required_goals.goal_type = 'norcomm_required'
        LEFT JOIN tracking_goals AS wtsi_required_goals ON wtsi_required_goals.date = counts.date AND counts.production_centre_id = wtsi_required_goals.production_centre_id AND wtsi_required_goals.goal_type = 'wtsi_required'
      EOF
    end

  end

end