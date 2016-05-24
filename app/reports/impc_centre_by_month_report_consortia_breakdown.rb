class ImpcCentreByMonthReportConsortiaBreakdown

  attr_accessor :report_rows, :centre

  def initialize(filter_by_centre)
    self.centre = filter_by_centre
    ## It's easier to display the report, if we create all the report rows while building the report.
    @report_rows = {
      ## Store an array of uniq dates to display in the report.
      :dates => []
    }

    self.generate_report
  end

  def by_month_clones
    @by_month_clones ||= ActiveRecord::Base.connection.execute(self.class.by_month_clones_sql(self.centre)).to_a
  end

  def by_month_genes
    @by_month_genes ||= ActiveRecord::Base.connection.execute(self.class.by_month_genes_sql(self.centre)).to_a
  end

  def cumulative_clones
    @cumulative_clones ||= ActiveRecord::Base.connection.execute(self.class.cumulative_clones_sql(self.class.real_start_date, self.centre) ).to_a
  end

  def cumulative_genes
    @cumulative_cre ||= ActiveRecord::Base.connection.execute(self.class.cumulative_genes_sql(self.class.real_start_date, self.centre) ).to_a
  end

  def cumulative_received
    @cumulative_received ||= ActiveRecord::Base.connection.execute(self.class.cumulative_received_sql(self.class.real_start_date, self.centre) ).to_a
  end

  def by_month_received
    @by_month_received ||= ActiveRecord::Base.connection.execute(self.class.by_month_received_sql(self.centre)).to_a
  end

  def cumulative_totals
    @total_to_date ||= generate_cumulatives
  end


  def generate_cumulatives
    total_to_date = {}

    to_date_cumulative ||= ActiveRecord::Base.connection.execute(self.class.cumulative_genes_sql(self.class.end_date, self.centre) ).to_a
    to_date_clones = ActiveRecord::Base.connection.execute(self.class.cumulative_clones_sql(self.class.end_date, self.centre) ).to_a
    to_date_received = ActiveRecord::Base.connection.execute(self.class.cumulative_received_sql(self.class.end_date, self.centre) ).to_a

    (to_date_clones + to_date_cumulative).each do |report_row|
      consortium = report_row['consortium']
      total_to_date[consortium] = {} if ! total_to_date[consortium]
      self.class.columns.each do |column, key|
        total_to_date[consortium]["#{key}_cumulative"] = report_row[key].to_i if report_row[key].to_i > 0

        if report_row["#{key}_goal"].to_i > 0
          total_to_date[consortium]["#{key}_goal_cumulative"] = report_row["#{key}_goal"]
        end
      end
    end

    to_date_received.each do |report_row|
      consortium = report_row['consortium']
      total_to_date[consortium] = {} if ! total_to_date[consortium]
      self.class.es_cell_supply_columns.each do |column, key|
        total_to_date[consortium]["#{key[0]}_cumulative"] = report_row[key[0]].to_i if report_row[key[0]].to_i > 0
        total_to_date[consortium]["#{key[1]}_cumulative"] = report_row[key[1]].to_i if report_row[key[1]].to_i > 0
      end
    end

    return total_to_date
  end

  def generate_report

    start_date = self.class.formatted_start_date

    @report_rows[:dates] << "To #{start_date}"

    (cumulative_clones + cumulative_genes).each do |report_row|
      consortium = report_row['consortium']

      self.class.columns.each do |column, key|
        if report_row[key] || @report_rows["To #{start_date}-#{consortium}-#{column}"].blank?
          @report_rows["To #{start_date}-#{consortium}-#{column}"] = report_row[key].to_i if report_row[key].to_i > 0
        end

        if report_row["#{key}_goal"].to_i > 0
          @report_rows["To #{start_date}-#{consortium}-#{column}_goal"] = report_row["#{key}_goal"]
        end
      end
    end

    (by_month_clones + by_month_genes).each do |report_row|
      date = Date.parse(report_row['date']).strftime('%b %Y')
      consortium = report_row['consortium']

      unless @report_rows[:dates].include?(date)
        @report_rows[:dates] << date
      end

      self.class.columns.each do |column, key|
        @report_rows["#{date}-#{consortium}-#{column}"] = report_row[key].to_i if report_row[key].to_i > 0

        if report_row["#{key}_goal"].to_i > 0
          @report_rows["#{date}-#{consortium}-#{column}_goal"] = report_row["#{key}_goal"]
        end
      end

    end

    cumulative_received.each do |report_row|
      consortium = report_row['consortium']

      self.class.es_cell_supply_columns.each do |column, key|
        if report_row[key[0]] || @report_rows["To #{start_date}-#{consortium}-#{column}-required"].blank?
          @report_rows["To #{start_date}-#{consortium}-#{column}-required"] = report_row[key[0]].to_i if report_row[key[0]].to_i > 0
        end
        if report_row[key[1]] || @report_rows["To #{start_date}-#{consortium}-#{column}-received"].blank?
          @report_rows["To #{start_date}-#{consortium}-#{column}-received"] = report_row[key[1]].to_i if report_row[key[1]].to_i > 0
        end
      end
    end

    by_month_received.each do |report_row|
      date = Date.parse(report_row['date']).strftime('%b %Y')
      consortium = report_row['consortium']

      unless @report_rows[:dates].include?(date)
        @report_rows[:dates] << date
      end

      self.class.es_cell_supply_columns.each do |column, key|
        @report_rows["#{date}-#{consortium}-#{column}-required"] = report_row[key[0]].to_i if report_row[key[0]].to_i > 0
        @report_rows["#{date}-#{consortium}-#{column}-received"] = report_row[key[1]].to_i if report_row[key[1]].to_i > 0
      end
    end

  end

  def consortia
    self.class.filter_by_centre_consortium[self.centre]
  end

  class << self

    def es_cell_supply_columns
      {
        'EUMMCR' => ['eucomm_required', 'eucomm_received'],
        'KOMP' => ['komp_required', 'komp_received'],
        'NorCOMM' => ['norcomm_required', 'norcomm_received'],
        'WTSI' => ['wtsi_required', 'wtsi_received'],
        'CMMR' => ['cmmr_required', 'cmmr_received']
      }
    end

    def columns
      {
        'Injected' => 'mi_in_progress_count',
        'Genotype confirmed' => 'genotype_confirmed_count',
        'Cre excised' => 'cre_excised_or_better_count',
        'Phenotype experiments started' => 'phenotype_experiments_started_count',
        'Phenotype data flow started' => 'phenotype_started_or_better_count',
        'Phenotype complete' => 'phenotype_complete_count'
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
      Date.parse(start_date) - 1.day
    end

    def formatted_start_date
      Date.parse(real_start_date.to_s).strftime('%b %Y')
    end

    ## Don't report incomplete month
    def end_date
      end_date = Time.now.to_date
      ## But do report it if it's the last day of the month.
      end_date = (end_date - 1.month).end_of_month unless end_date == end_date.end_of_month

      end_date.to_s(:db)
    end

    def filter_by_centre_consortium
        @filter_by_centre_consortium ||=
        {'HMGU' => ['Helmholtz GMC'],
         'ICS' => ['Phenomin', 'Helmholtz GMC'],
         'BCM' => Consortium.find_by_sql("SELECT DISTINCT consortia.* FROM mi_plans JOIN consortia ON consortia.id = mi_plans.consortium_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE centres.name = 'BCM' AND mi_plans.mutagenesis_via_crispr_cas9 = false").map{|consortium| consortium.name},
         'TCP' => Consortium.find_by_sql("SELECT DISTINCT consortia.* FROM mi_plans JOIN consortia ON consortia.id = mi_plans.consortium_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE centres.name = 'TCP' AND mi_plans.mutagenesis_via_crispr_cas9 = false").map{|consortium| consortium.name},
         'JAX' => Consortium.find_by_sql("SELECT DISTINCT consortia.* FROM mi_plans JOIN consortia ON consortia.id = mi_plans.consortium_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE centres.name = 'JAX' AND mi_plans.mutagenesis_via_crispr_cas9 = false").map{|consortium| consortium.name},
         'RIKEN BRC' => Consortium.find_by_sql("SELECT DISTINCT consortia.* FROM mi_plans JOIN consortia ON consortia.id = mi_plans.consortium_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE centres.name = 'RIKEN BRC' AND mi_plans.mutagenesis_via_crispr_cas9 = false").map{|consortium| consortium.name},
         'Harwell' => ['BaSH', 'MRC'],
         'UCD' => ['DTCC'],
         'WTSI' => ['MGP', 'BaSH'],
         'Monterotondo' => ['Monterotondo'],
         'MARC' => Consortium.find_by_sql("SELECT DISTINCT consortia.* FROM mi_plans JOIN consortia ON consortia.id = mi_plans.consortium_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE centres.name = 'MARC' AND mi_plans.mutagenesis_via_crispr_cas9 = false").map{|consortium| consortium.name}
        }
    end

    def cumulative_clones_sql(cut_off_date, centre)
      <<-EOF
        WITH
          injected_es_cells AS (
            SELECT
              targ_rep_es_cells.id AS es_cell_id,
              consortia.name AS consortium,
              count(*) AS mi_in_progress_count,
              SUM(mi_plans.number_of_es_cells_received) as es_cells_received

            FROM targ_rep_es_cells
            JOIN mi_attempts ON mi_attempts.es_cell_id = targ_rep_es_cells.id
            JOIN mi_plans ON mi_plans.id = mi_attempts.accredited_to_id AND mi_plans.mutagenesis_via_crispr_cas9 = false
            JOIN centres ON centres.id = mi_plans.production_centre_id
            JOIN consortia ON consortia.id = mi_plans.consortium_id

            JOIN mi_attempt_status_stamps as mip_stamps ON mi_attempts.id = mip_stamps.mi_attempt_id AND mip_stamps.status_id = 1 AND mip_stamps.created_at < '#{cut_off_date}'

        WHERE
        (
          #{filter_by_centre_consortium.map{|key, value| "(centres.name = '#{key}' AND consortia.name IN ('#{value.join('\', \'')}'))"}.join(' OR ')}
        )
        AND
          centres.name = '#{centre}'

            GROUP BY
              targ_rep_es_cells.id,
              consortia.name
            ORDER BY
              consortia.name ASC,
              es_cell_id ASC
        ),

        counts AS (
          SELECT
            injected_es_cells.consortium,
            SUM(CASE
              WHEN injected_es_cells.mi_in_progress_count > 0
              THEN 1
              ELSE 0
            END) as mi_in_progress_count,
            SUM(injected_es_cells.es_cells_received) as es_cells_received

          FROM injected_es_cells
          GROUP BY
            injected_es_cells.consortium
          ORDER BY injected_es_cells.consortium ASC
        )


          SELECT
            counts.consortium,
            counts.mi_in_progress_count,
            counts.es_cells_received,
            clone_goals.mip_goals AS mi_in_progress_count_goal

          FROM counts

          JOIN consortia ON consortia.name = consortium
          LEFT JOIN
          (
          SELECT
            consortium_id,
            SUM(CASE WHEN tracking_goals.goal_type = 'total_injected_clones' THEN tracking_goals.goal ELSE 0 END) AS mip_goals
          FROM tracking_goals
          JOIN centres ON centres.id = tracking_goals.production_centre_id AND centres.name = '#{centre}'
          WHERE tracking_goals.date IS NULL OR to_number(to_char(tracking_goals.date, 'YYYYMM'),'999999' ) <= (#{(cut_off_date.to_date.strftime('%Y%m'))})
                AND tracking_goals.goal_type = 'total_injected_clones' AND tracking_goals.consortium_id IS NOT NULL
          GROUP BY consortium_id

        ) AS clone_goals ON clone_goals.consortium_id = consortia.id

          ORDER BY
            consortium ASC
      EOF
    end

    def cumulative_genes_sql (cut_off_date, centre)
      <<-EOF

        WITH
           genes_with_plans AS (
                SELECT
                  genes.id AS gene_id,
                  mi_plans.id AS mi_plan_id,
                  consortia.name AS consortium_name
                FROM genes
                JOIN mi_plans ON mi_plans.gene_id = genes.id AND mi_plans.mutagenesis_via_crispr_cas9 = false
                JOIN centres ON centres.id = mi_plans.production_centre_id
                JOIN consortia ON consortia.id = mi_plans.consortium_id

                WHERE
                (
                  #{filter_by_centre_consortium.map{|key, value| "(centres.name = '#{key}' AND consortia.name IN ('#{value.join('\', \'')}'))"}.join(' OR ')}
                )
                AND centres.name = '#{centre}'

        ),

        gtc_gene_consortia AS (
          SELECT
            genes_with_plans.gene_id as gene_id,
            genes_with_plans.consortium_name as consortium_name,
            count(gtc_stamps.*) as genotype_confirmed_count
          FROM genes_with_plans
          JOIN mi_attempts ON genes_with_plans.mi_plan_id = mi_attempts.accredited_to_id and mi_attempts.status_id != 3
          LEFT JOIN mi_attempt_status_stamps as gtc_stamps ON mi_attempts.id = gtc_stamps.mi_attempt_id AND gtc_stamps.status_id = 2 AND gtc_stamps.created_at < '#{cut_off_date}'

          GROUP BY
            genes_with_plans.gene_id,
            genes_with_plans.consortium_name

          ORDER BY genes_with_plans.consortium_name ASC
        ),

        gtc_consortia AS (
          SELECT
            gtc_gene_consortia.consortium_name,
            SUM(CASE
              WHEN genotype_confirmed_count > 0
              THEN 1 ELSE 0
            END) as genotype_confirmed_count
          FROM gtc_gene_consortia
          GROUP BY
            consortium_name
          ORDER BY
            consortium_name ASC
        ),


        mouse_allele_mod_gene_consortia AS (
          SELECT
            genes_with_plans.gene_id as gene_id,
            genes_with_plans.consortium_name as consortium_name,
            count(cre_stamps.*) as cre_excised_or_better_count
          FROM genes_with_plans
          JOIN mouse_allele_mods ON genes_with_plans.mi_plan_id = mouse_allele_mods.accredited_to_id AND mouse_allele_mods.status_id != 7 --not aborted
          LEFT JOIN mouse_allele_mod_status_stamps as cre_stamps ON mouse_allele_mods.id = cre_stamps.mouse_allele_mod_id AND cre_stamps.status_id = 6 AND cre_stamps.created_at <= '#{cut_off_date}'

          GROUP BY
            genes_with_plans.gene_id,
            genes_with_plans.consortium_name

          ORDER BY genes_with_plans.consortium_name ASC
        ),

        phenotyping_production_gene_consortia AS (
          SELECT
            genes_with_plans.gene_id as gene_id,
            genes_with_plans.consortium_name as consortium_name,
            count(ps_stamps.*) as phenotype_started_or_better_count,
            count(pc_stamps.*) as phenotype_complete_count,
            SUM(CASE WHEN phenotyping_experiments_started <= '#{cut_off_date}' THEN 1 ELSE 0 END) AS phenotype_experiments_started_count
          FROM genes_with_plans
          JOIN phenotyping_productions ON genes_with_plans.mi_plan_id = phenotyping_productions.accredited_to_id AND phenotyping_productions.status_id != 5
          LEFT JOIN phenotyping_production_status_stamps as ps_stamps ON phenotyping_productions.id = ps_stamps.phenotyping_production_id AND ps_stamps.status_id = 3 AND ps_stamps.created_at <= '#{cut_off_date}'
          LEFT JOIN phenotyping_production_status_stamps as pc_stamps ON phenotyping_productions.id = pc_stamps.phenotyping_production_id AND pc_stamps.status_id = 4 AND pc_stamps.created_at <= '#{cut_off_date}'

          GROUP BY
            genes_with_plans.gene_id,
            genes_with_plans.consortium_name

          ORDER BY genes_with_plans.consortium_name ASC
        ),

        phenotype_consortia AS (
          SELECT
            mouse_allele_mod_gene_consortia.consortium_name,
            SUM(CASE
              WHEN mouse_allele_mod_gene_consortia.cre_excised_or_better_count > 0
              THEN 1 ELSE 0
            END) as cre_excised_or_better_count,
            SUM(CASE
              WHEN phenotyping_production_gene_consortia.phenotype_started_or_better_count > 0
              THEN 1 ELSE 0
            END) as phenotype_started_or_better_count,
            SUM(CASE
              WHEN phenotyping_production_gene_consortia.phenotype_complete_count > 0
              THEN 1 ELSE 0
            END) as phenotype_complete_count,
            SUM(CASE
              WHEN phenotyping_production_gene_consortia.phenotype_experiments_started_count > 0
              THEN 1 ELSE 0
            END) as phenotype_experiments_started_count
          FROM mouse_allele_mod_gene_consortia
          LEFT JOIN phenotyping_production_gene_consortia ON phenotyping_production_gene_consortia.gene_id = mouse_allele_mod_gene_consortia.gene_id AND phenotyping_production_gene_consortia.consortium_name = mouse_allele_mod_gene_consortia.consortium_name
          GROUP BY
            mouse_allele_mod_gene_consortia.consortium_name
          ORDER BY
            consortium_name ASC
        )


         SELECT
           gtc_consortia.consortium_name AS consortium,
           gtc_consortia.genotype_confirmed_count,
           phenotype_consortia.cre_excised_or_better_count,
           phenotype_consortia.phenotype_started_or_better_count,
           phenotype_consortia.phenotype_complete_count,
           phenotype_consortia.phenotype_experiments_started_count,

           gene_goals.gtc_goals as genotype_confirmed_count_goal,
           gene_goals.cre_goals as cre_excised_or_better_count_goal,
           gene_goals.phenotype_started_goals as phenotype_experiments_started_count_goal,
           gene_goals.ps_goals as phenotype_started_or_better_count_goal,
           gene_goals.pc_goals as phenotype_complete_count_goal

            FROM gtc_consortia

              LEFT JOIN phenotype_consortia ON phenotype_consortia.consortium_name = gtc_consortia.consortium_name
              JOIN consortia ON consortia.name = gtc_consortia.consortium_name

          LEFT JOIN
          (
          SELECT
            consortium_id,
            SUM(CASE WHEN tracking_goals.goal_type = 'total_glt_genes' THEN tracking_goals.goal ELSE 0 END) AS gtc_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'cre_exicised_genes' THEN tracking_goals.goal ELSE 0 END) AS cre_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'phenotype_experiment_started_genes' THEN tracking_goals.goal ELSE 0 END) AS phenotype_started_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'phenotype_started_genes' THEN tracking_goals.goal ELSE 0 END) AS ps_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'phenotype_complete_genes' THEN tracking_goals.goal ELSE 0 END) AS pc_goals
          FROM tracking_goals
          JOIN centres ON centres.id = tracking_goals.production_centre_id AND centres.name = '#{centre}'
          WHERE tracking_goals.date IS NULL OR to_number(to_char(tracking_goals.date, 'YYYYMM'),'999999' ) <= (#{(cut_off_date.to_date.strftime('%Y%m'))})
                AND tracking_goals.goal_type IN ('total_glt_genes', 'cre_exicised_genes', 'phenotype_experiment_started_genes', 'phenotype_started_genes', 'phenotype_complete_genes' )
          GROUP BY consortium_id

        ) AS gene_goals ON gene_goals.consortium_id = consortia.id

      EOF
    end

    def by_month_clones_sql(centre)
      <<-EOF
        WITH series AS (
          SELECT generate_series('#{start_date}', '#{end_date}', interval '1 month')::date as date
        ),
        clones_with_plans AS (
        SELECT
          targ_rep_es_cells.id AS es_cell_id,
          mi_plans.id AS mi_plan_id,
          consortia.name AS consortium,
          date_trunc('MONTH', mip_stamps.created_at) as mip_date
        FROM targ_rep_es_cells
        JOIN mi_attempts ON mi_attempts.es_cell_id = targ_rep_es_cells.id
        JOIN mi_plans ON mi_plans.id = mi_attempts.accredited_to_id AND mi_plans.mutagenesis_via_crispr_cas9 = false
        JOIN centres ON centres.id = mi_plans.production_centre_id
        JOIN consortia ON consortia.id = mi_plans.consortium_id

        JOIN mi_attempt_status_stamps as mip_stamps ON mi_attempts.id = mip_stamps.mi_attempt_id AND mip_stamps.status_id = 1 AND mip_stamps.created_at >= '#{start_date}'

        WHERE
        (
          #{filter_by_centre_consortium.map{|key, value| "(centres.name = '#{key}' AND consortia.name IN ('#{value.join('\', \'')}'))"}.join(' OR ')}
        )
        AND centres.name = '#{centre}'

        GROUP BY
          targ_rep_es_cells.id,
          mi_plans.id,
          consortia.name,
          mip_stamps.created_at
        ),

        counts AS (
          SELECT
            series.date,
            clones_with_plans.consortium,
            SUM(CASE
              WHEN clones_with_plans.mip_date = series.date
              THEN 1
              ELSE 0
            END) as mi_in_progress_count

          FROM clones_with_plans
          CROSS JOIN series
          GROUP BY
            series.date,
            clones_with_plans.consortium
          ORDER BY series.date ASC
        )


        SELECT
          counts.date,
          counts.consortium,
          counts.mi_in_progress_count,
          mip_goals.goal AS mi_in_progress_count_goal

        FROM counts
        JOIN consortia ON consortia.name = counts.consortium

        LEFT JOIN
          (tracking_goals AS mip_goals JOIN centres ON centres.id = mip_goals.production_centre_id AND centres.name = '#{centre}' )
        ON counts.date = mip_goals.date AND consortia.id = mip_goals.consortium_id AND mip_goals.goal_type = 'total_injected_clones'

        ORDER BY counts.date ASC, counts.consortium ASC
      EOF
    end

    def by_month_genes_sql(centre)
      <<-EOF
        WITH series AS (
          SELECT generate_series('#{start_date}', '#{end_date}', interval '1 month')::date as date
        ),
        genes_with_plans AS (
        SELECT
          genes.id AS gene_id,
          mi_plans.id AS mi_plan_id,
          consortia.name AS consortium_name
        FROM genes
        JOIN mi_plans ON mi_plans.gene_id = genes.id AND mi_plans.mutagenesis_via_crispr_cas9 = false
        JOIN centres ON centres.id = mi_plans.production_centre_id
        JOIN consortia ON consortia.id = mi_plans.consortium_id

        WHERE
        (
          #{filter_by_centre_consortium.map{|key, value| "(centres.name = '#{key}' AND consortia.name IN ('#{value.join('\', \'')}'))"}.join(' OR ')}
        )
        AND centres.name = '#{centre}'

        ),

        gtc_gene_consortia AS (
          SELECT
            genes_with_plans.gene_id as gene_id,
            genes_with_plans.consortium_name as consortium_name,
            date_trunc('MONTH', gtc_stamps.created_at) as gtc_date
          FROM genes_with_plans
          JOIN mi_attempts ON genes_with_plans.mi_plan_id = mi_attempts.accredited_to_id AND mi_attempts.status_id != 3
          LEFT JOIN mi_attempt_status_stamps as gtc_stamps ON mi_attempts.id = gtc_stamps.mi_attempt_id AND gtc_stamps.status_id = 2 AND gtc_stamps.created_at >= '#{start_date}'

          GROUP BY
            genes_with_plans.gene_id,
            genes_with_plans.consortium_name,
            gtc_date

          ORDER BY genes_with_plans.consortium_name ASC
        ),

        gtc_consortia AS (
          SELECT
            series.date,
            gtc_gene_consortia.consortium_name,
            SUM(CASE
              WHEN gtc_gene_consortia.gtc_date = series.date
              THEN 1
              ELSE 0
            END) as genotype_confirmed_count

          FROM gtc_gene_consortia
          CROSS JOIN series
          GROUP BY
            series.date,
            gtc_gene_consortia.consortium_name
          ORDER BY series.date ASC
        ),

        mouse_allele_mod_gene_consortia AS (
          SELECT
            consortium_name,
            series_date,
            SUM( CASE WHEN mam_counts.cre_count > 0 THEN 1 ELSE 0 END) AS cre_excised_or_better_count
          FROM
            (
            SELECT
              gene_id,
              consortium_name,
              mam_date AS series_date,
              SUM( CASE WHEN mams_id = 6 THEN 1 ELSE 0 END) AS cre_count
            FROM
            (
              SELECT DISTINCT
                genes_with_plans.gene_id as gene_id,
                genes_with_plans.consortium_name as consortium_name,
                mouse_allele_mod_status_stamps.status_id AS mams_id,
                date_trunc('MONTH', mouse_allele_mod_status_stamps.created_at) as mam_date
              FROM genes_with_plans
              JOIN mouse_allele_mods ON genes_with_plans.mi_plan_id = mouse_allele_mods.accredited_to_id AND mouse_allele_mods.status_id != 7 --not aborted
              JOIN mouse_allele_mod_status_stamps ON mouse_allele_mods.id = mouse_allele_mod_status_stamps.mouse_allele_mod_id AND mouse_allele_mod_status_stamps.status_id IN (6) AND mouse_allele_mod_status_stamps.created_at >= '#{start_date}'
              ORDER BY genes_with_plans.gene_id, genes_with_plans.consortium_name ASC
              ) AS mam_status_by_month
            GROUP BY gene_id, consortium_name, mam_date
            ) AS mam_counts
            GROUP BY mam_counts.consortium_name, series_date

        ),

        phenotyping_production_gene_consortia AS (
          SELECT
            consortium_name,
            series_date,
            COUNT( series_date ) AS phenotyping_experiments_count
          FROM
            (
            SELECT DISTINCT
              genes_with_plans.gene_id as gene_id,
              genes_with_plans.consortium_name as consortium_name,
              date_trunc('MONTH', phenotyping_experiments_started) as series_date
            FROM genes_with_plans
            JOIN phenotyping_productions ON genes_with_plans.mi_plan_id = phenotyping_productions.accredited_to_id AND phenotyping_productions.status_id != 5 AND phenotyping_productions.phenotyping_experiments_started >= '#{start_date}'
            ORDER BY genes_with_plans.gene_id, genes_with_plans.consortium_name ASC
            ) AS pp_counts
          GROUP BY consortium_name, series_date

        ),

        phenotyping_production_status_gene_consortia AS (
          SELECT
            pp_counts.consortium_name,
            pp_counts.series_date,
            SUM( CASE WHEN pp_counts.ps_count > 0 THEN 1 ELSE 0 END) AS phenotype_started_or_better_count,
            SUM( CASE WHEN pp_counts.pc_count > 0 THEN 1 ELSE 0 END) AS phenotype_complete_count
          FROM
            (
            SELECT
              gene_id,
              consortium_name,
              pps_date AS series_date,
              SUM( CASE WHEN pps_id = 3 THEN 1 ELSE 0 END) AS ps_count,
              SUM( CASE WHEN pps_id = 4 THEN 1 ELSE 0 END) AS pc_count
            FROM
              (
              SELECT DISTINCT
                genes_with_plans.gene_id as gene_id,
                genes_with_plans.consortium_name as consortium_name,
                phenotyping_production_status_stamps.status_id AS pps_id,
                date_trunc('MONTH', phenotyping_production_status_stamps.created_at) as pps_date
              FROM genes_with_plans
              JOIN phenotyping_productions ON genes_with_plans.mi_plan_id = phenotyping_productions.accredited_to_id AND phenotyping_productions.status_id != 5
              JOIN phenotyping_production_status_stamps ON phenotyping_production_status_stamps.phenotyping_production_id = phenotyping_productions.id AND phenotyping_production_status_stamps.created_at >= '#{start_date}' AND phenotyping_production_status_stamps.status_id IN (3,4)
              ORDER BY genes_with_plans.gene_id, genes_with_plans.consortium_name ASC
              ) AS pp_status_by_month
            GROUP BY gene_id, consortium_name, pps_date
            ) AS pp_counts
          GROUP BY pp_counts.consortium_name, pp_counts.series_date
        )


        SELECT
          gtc_consortia.date,
          gtc_consortia.consortium_name AS consortium,
          gtc_consortia.genotype_confirmed_count,
          mouse_allele_mod_gene_consortia.cre_excised_or_better_count,
          phenotyping_production_status_gene_consortia.phenotype_started_or_better_count,
          phenotyping_production_status_gene_consortia.phenotype_complete_count,
          phenotyping_production_gene_consortia.phenotyping_experiments_count AS phenotype_experiments_started_count,

          gtc_goals.goal  AS genotype_confirmed_count_goal,
          cre_goals.goal AS cre_excised_or_better_count_goal,
          phenotype_experiments_started_goals.goal  AS phenotype_experiments_started_count_goal,
          ps_goals.goal  AS phenotype_started_or_better_count_goal,
          pc_goals.goal  AS phenotype_complete_count_goal

        FROM gtc_consortia

        LEFT JOIN phenotyping_production_status_gene_consortia ON phenotyping_production_status_gene_consortia.series_date = gtc_consortia.date AND phenotyping_production_status_gene_consortia.consortium_name = gtc_consortia.consortium_name
        LEFT JOIN phenotyping_production_gene_consortia ON phenotyping_production_gene_consortia.series_date = gtc_consortia.date AND phenotyping_production_gene_consortia.consortium_name = gtc_consortia.consortium_name
        LEFT JOIN mouse_allele_mod_gene_consortia ON mouse_allele_mod_gene_consortia.series_date = gtc_consortia.date AND mouse_allele_mod_gene_consortia.consortium_name = gtc_consortia.consortium_name
        JOIN consortia ON consortia.name = gtc_consortia.consortium_name

        LEFT JOIN (tracking_goals AS gtc_goals JOIN centres AS c1 ON c1.id = gtc_goals.production_centre_id AND c1.name = '#{centre}' )
          ON gtc_consortia.date = gtc_goals.date AND consortia.id = gtc_goals.consortium_id AND gtc_goals.goal_type = 'total_glt_genes'
        LEFT JOIN (tracking_goals AS cre_goals JOIN centres AS c2 ON c2.id = cre_goals.production_centre_id AND c2.name = '#{centre}' )
          ON gtc_consortia.date = cre_goals.date AND consortia.id = cre_goals.consortium_id AND cre_goals.goal_type = 'cre_exicised_genes'
        LEFT JOIN (tracking_goals AS phenotype_experiments_started_goals  JOIN centres AS c3 ON c3.id = phenotype_experiments_started_goals.production_centre_id AND c3.name = '#{centre}' )
          ON gtc_consortia.date = phenotype_experiments_started_goals.date AND consortia.id = phenotype_experiments_started_goals.consortium_id AND phenotype_experiments_started_goals.goal_type = 'phenotype_experiment_started_genes'
        LEFT JOIN (tracking_goals AS ps_goals JOIN centres AS c4 ON c4.id = ps_goals.production_centre_id AND c4.name = '#{centre}' )
          ON gtc_consortia.date = ps_goals.date AND consortia.id = ps_goals.consortium_id AND ps_goals.goal_type = 'phenotype_started_genes'
        LEFT JOIN (tracking_goals AS pc_goals JOIN centres AS c5 ON c5.id = pc_goals.production_centre_id AND c5.name = '#{centre}' )
          ON gtc_consortia.date = pc_goals.date AND consortia.id = pc_goals.consortium_id AND pc_goals.goal_type = 'phenotype_complete_genes'

        ORDER BY gtc_consortia.date ASC, gtc_consortia.consortium_name ASC
      EOF
    end

    def cumulative_received_sql (cut_off_date, centre)
      <<-EOF
        SELECT
          consortium,
          es_cells_received,
          required_goals.eucomm_required_goals as eucomm_required,
          counts.eucomm_received  as eucomm_received,
          required_goals.komp_required_goals as komp_required,
          counts.komp_received  as komp_received,
          required_goals.norcomm_required_goals as norcomm_required,
          counts.norcomm_received  as norcomm_received,
          required_goals.wtsi_required_goals as wtsi_required,
          counts.wtsi_received as wtsi_received,
          required_goals.cmmr_required_goals as cmmr_required,
          counts.cmmr_received as cmmr_received

        FROM (
        SELECT
          consortia.name as consortium,
          consortia.id as consortium_id,
          SUM(number_of_es_cells_received) as es_cells_received,
          SUM(CASE WHEN targ_rep_centre_pipelines.name = 'EUMMCR' THEN number_of_es_cells_received ELSE 0 END) AS eucomm_received,
          SUM(CASE WHEN targ_rep_centre_pipelines.name = 'KOMP' THEN number_of_es_cells_received ELSE 0 END) AS komp_received,
          SUM(CASE WHEN targ_rep_centre_pipelines.name = 'NorCOMM2LS' THEN number_of_es_cells_received ELSE 0 END) AS norcomm_received,
          SUM(CASE WHEN targ_rep_centre_pipelines.name = 'WTSI' THEN number_of_es_cells_received ELSE 0 END) AS wtsi_received,
          SUM(CASE WHEN targ_rep_centre_pipelines.name = 'CMMR' THEN number_of_es_cells_received ELSE 0 END) AS cmmr_received

        FROM mi_plans

        JOIN centres ON centres.id = mi_plans.production_centre_id
        JOIN consortia ON consortia.id = mi_plans.consortium_id
        LEFT JOIN targ_rep_centre_pipelines ON mi_plans.es_cells_received_from_id = targ_rep_centre_pipelines.id

          WHERE
            (
              #{filter_by_centre_consortium.map{|key, value| "(centres.name = '#{key}' AND consortia.name IN ('#{value.join('\', \'')}'))"}.join(' OR ')}
            )
            AND
            centres.name = '#{centre}'

            AND mi_plans.es_cells_received_on < '#{cut_off_date}' AND mi_plans.mutagenesis_via_crispr_cas9 = false

        GROUP BY
          consortia.name,
          consortia.id
        ) AS counts

        LEFT JOIN (
          SELECT
            tracking_goals.consortium_id,
            SUM(CASE WHEN tracking_goals.goal_type = 'eucomm_required' THEN tracking_goals.goal ELSE 0 END) AS eucomm_required_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'komp_required' THEN tracking_goals.goal ELSE 0 END) AS komp_required_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'norcomm_required' THEN tracking_goals.goal ELSE 0 END) AS norcomm_required_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'wtsi_required' THEN tracking_goals.goal ELSE 0 END) AS wtsi_required_goals,
            SUM(CASE WHEN tracking_goals.goal_type = 'cmmr_required' THEN tracking_goals.goal ELSE 0 END) AS cmmr_required_goals
          FROM tracking_goals
          WHERE tracking_goals.date IS NULL OR to_number(to_char(tracking_goals.date, 'YYYYMM'),'999999' ) <= (#{(cut_off_date.to_date.strftime('%Y%m'))})
                AND tracking_goals.goal_type IN ('eucomm_required', 'komp_required', 'norcomm_required', 'wtsi_required', 'cmmr_required' )
          GROUP BY tracking_goals.consortium_id

        ) AS required_goals ON required_goals.consortium_id = counts.consortium_id

      EOF
    end

    def by_month_received_sql(centre)
      <<-EOF
        WITH series AS (
          SELECT generate_series('#{start_date}', '#{end_date}', interval '1 month')::date as date
        ),

        counts AS (
          SELECT
            series.date,
            consortia.name as consortium,
            consortia.id as consortium_id,
            SUM(CASE
              WHEN date_trunc('MONTH', es_cells_received_on) = series.date
              THEN number_of_es_cells_received ELSE 0
            END) as es_cells_received,
            SUM(CASE WHEN date_trunc('MONTH', es_cells_received_on) = series.date AND targ_rep_centre_pipelines.name = 'EUMMCR' THEN number_of_es_cells_received ELSE 0 END) AS eucomm_received,
            SUM(CASE WHEN date_trunc('MONTH', es_cells_received_on) = series.date AND targ_rep_centre_pipelines.name = 'KOMP' THEN number_of_es_cells_received ELSE 0 END) AS komp_received,
            SUM(CASE WHEN date_trunc('MONTH', es_cells_received_on) = series.date AND targ_rep_centre_pipelines.name = 'NorCOMM2LS' THEN number_of_es_cells_received ELSE 0 END) AS norcomm_received,
            SUM(CASE WHEN date_trunc('MONTH', es_cells_received_on) = series.date AND targ_rep_centre_pipelines.name = 'WTSI' THEN number_of_es_cells_received ELSE 0 END) AS wtsi_received,
            SUM(CASE WHEN date_trunc('MONTH', es_cells_received_on) = series.date AND targ_rep_centre_pipelines.name = 'CMMR' THEN number_of_es_cells_received ELSE 0 END) AS cmmr_received

          FROM mi_plans
          CROSS JOIN series
          LEFT JOIN targ_rep_centre_pipelines ON targ_rep_centre_pipelines.id = mi_plans.es_cells_received_from_id
          JOIN centres ON centres.id = mi_plans.production_centre_id
          JOIN consortia ON consortia.id = mi_plans.consortium_id

            WHERE
            (
              #{filter_by_centre_consortium.map{|key, value| "(centres.name = '#{key}' AND consortia.name IN ('#{value.join('\', \'')}'))"}.join(' OR ')}
            )
            AND centres.name = '#{centre}' AND mi_plans.mutagenesis_via_crispr_cas9 = false

          GROUP BY
            series.date,
            consortia.name,
            consortia.id
        )

        SELECT
          counts.date,
          consortium,
          es_cells_received,
          eucomm_required_goals.goal as eucomm_required,
          counts.eucomm_received as eucomm_received,
          komp_required_goals.goal as komp_required,
          counts.komp_received as komp_received,
          norcomm_required_goals.goal as norcomm_required,
          counts.norcomm_received as norcomm_received,
          wtsi_required_goals.goal as wtsi_required,
          counts.wtsi_received as wtsi_received,
          cmmr_required_goals.goal as cmmr_required,
          counts.cmmr_received as cmmr_received

        FROM counts

        LEFT JOIN (tracking_goals AS eucomm_required_goals JOIN centres AS c1 ON c1.id = eucomm_required_goals.production_centre_id AND c1.name = '#{centre}' )
          ON eucomm_required_goals.date = counts.date AND counts.consortium_id = eucomm_required_goals.consortium_id AND eucomm_required_goals.goal_type = 'eucomm_required'
        LEFT JOIN (tracking_goals AS komp_required_goals JOIN centres AS c2 ON c2.id = komp_required_goals.production_centre_id AND c2.name = '#{centre}' )
          ON komp_required_goals.date = counts.date AND counts.consortium_id = komp_required_goals.consortium_id AND komp_required_goals.goal_type = 'komp_required'
        LEFT JOIN (tracking_goals AS norcomm_required_goals JOIN centres AS c3 ON c3.id = norcomm_required_goals.production_centre_id AND c3.name = '#{centre}' )
          ON norcomm_required_goals.date = counts.date AND counts.consortium_id = norcomm_required_goals.consortium_id AND norcomm_required_goals.goal_type = 'norcomm_required'
        LEFT JOIN (tracking_goals AS wtsi_required_goals JOIN centres AS c4 ON c4.id = wtsi_required_goals.production_centre_id AND c4.name = '#{centre}' )
          ON wtsi_required_goals.date = counts.date AND counts.consortium_id = wtsi_required_goals.consortium_id AND wtsi_required_goals.goal_type = 'wtsi_required'
        LEFT JOIN (tracking_goals AS cmmr_required_goals JOIN centres AS c5 ON c5.id = cmmr_required_goals.production_centre_id AND c5.name = '#{centre}' )
          ON cmmr_required_goals.date = counts.date AND counts.consortium_id = cmmr_required_goals.consortium_id AND cmmr_required_goals.goal_type = 'cmmr_required'
      EOF
    end
  end

end