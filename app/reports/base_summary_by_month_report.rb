class BaseSummaryByMonthReport

  ##
  ##  This is the base presenter for reporting on counts of statuses for particular months,
  ##  this report uses the intermediate report table.
  ##

  attr_accessor :report_hash

  def initialize
    @report_hash = {
      :dates => {}
    }

    self.generate_summary_by_month
  end

  def summary_by_month
    ActiveRecord::Base.connection.execute(self.class.summary_by_month_sql)
  end

  def generate_summary_by_month

    summary_by_month.each do |report_row|

      consortium = report_row['consortium']
      date = Date.parse(report_row['date'])

      if @report_hash[:dates].include?(date.year)
        @report_hash[:dates][date.year] << date
      else
        @report_hash[:dates][date.year] = [date]
      end

      self.class.columns.to_a.each do |heading, key|
        value = report_row[key.to_s]

        @report_hash["#{consortium}-#{date}-#{heading}"] = value
      end
    end
  end

  class << self

    def available_consortia
      []
    end

    def columns
      { "Gene Interest" => :commenece_count,
        "Cumulative Gene Interest" => :cumulative_commenece,
        "Assigned" => :assigned_count,
        "Cumulative Assigned" => :cumulative_assigned,
        "Cumulative ES Starts"   => :cumulative_es_cells,
        "ES Cell QC In Progress" => :assigned_es_cell_count,
        "ES Cell QC Complete"    => :es_cell_complete_count,
        "ES Cell QC Failed"      => :es_cell_aborted_count,
        "Micro-Injection In Progress" => :mi_in_progress_count,
        "Cumulative MIs"         => :cumulative_mis,

        "Cumulative ES Cell QC Complete" => :cumulative_es_cell_complete,
        "Cumulative ES Cell QC Failed" => :cumulative_es_cells_aborted,

        "MI Goal"            => :mi_goal,
        "Chimeras obtained"  => :chimeras_obtained_count,
        "Genotype confirmed" => :genotype_confirmed_count,
        "Cumulative genotype confirmed" => :cumulative_gcs,
        "GC Goal"            => :genotype_confirmed_goals,
        "Micro-injection aborted"      => :mi_aborted_count,
        "Phenotype Attempt Registered" => :phenotype_registered_count,
        "Rederivation Started"  => :rederivation_started_count,
        "Rederivation Complete" => :rederivation_complete_count,
        "Cre Excision Started"  => :cre_excision_started_count,
        "Cre Excision Complete" => :cre_excision_complete_count,
        "Phenotyping Started"   => :phenotype_started_count,
        "Phenotyping Complete"  => :phenotype_complete_count,
        "Phenotype Attempt Aborted" => :phenotype_aborted_count,

        "Cumulative Phenotype Registered" => :cumulative_phenotype_registered,
        "Cumulative Cre Excision Complete" => :cumulative_cre_excision_complete,
        "Cumulative Phenotype Complete" => :cumulative_phenotype_complete
      }
    end

    def clone_columns
      [
        "Cumulative ES Starts",
        "ES Cell QC In Progress",
        "ES Cell QC Complete",
        "ES Cell QC Failed",
        "Micro-Injection In Progress",
        "Cumulative MIs",
        "MI Goal",
        "Chimeras obtained",
        "Genotype confirmed",
        "Cumulative genotype confirmed",
        "GC Goal",
        "Micro-injection aborted"
      ]
    end

    def phenotype_columns
      [
        "Phenotype Attempt Registered",
        "Rederivation Started",
        "Rederivation Complete",
        "Cre Excision Started",
        "Cre Excision Complete",
        "Phenotyping Started",
        "Phenotyping Complete",
        "Phenotype Attempt Aborted"
      ]
    end

    def date_previous_month
      if (Time.now.month - 1) ==0
        year = Time.now.year - 1
        month = 12
      else
        year = Time.now.year
        month = Time.now.month - 1
      end
      Date.civil( year,  month, -1).to_s(:db)
    end

    def summary_by_month_sql(previous_month = false)

      if previous_month
        up_to_date = date_previous_month
      else
        up_to_date = Time.now.to_date.to_s(:db)
      end
      sql = <<-EOF
        WITH
          -- create a series of dates for each month from the 2011-06-01 to now. NOTE 2011-05-01 will store all production prior to 2011-06-01 (Easiest bodge).
          series AS (
            SELECT generate_series('2011-05-01 00:00:00', '#{up_to_date}', interval '1 month')::date as date
          ),
          counts AS (
            SELECT
              series.date as date,
              report.consortium as consortium,
              SUM(CASE
                WHEN report.commenece_date >= series.date
                  AND report.commenece_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as commenece_count,
              SUM(CASE
                WHEN report.assigned_date >= series.date
                  AND report.assigned_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as assigned_count,
              SUM(CASE
                WHEN report.assigned_es_cell_qc_in_progress_date >= series.date
                  AND report.assigned_es_cell_qc_in_progress_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as assigned_es_cell_count,
              SUM(CASE
                WHEN report.assigned_es_cell_qc_complete_date >= series.date
                  AND report.assigned_es_cell_qc_complete_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as es_cell_complete_count,
              SUM(CASE
                WHEN report.aborted_es_cell_qc_failed_date >= series.date
                  AND report.aborted_es_cell_qc_failed_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as es_cell_aborted_count,
              SUM(CASE
                WHEN report.micro_injection_in_progress_date >= series.date
                  AND report.micro_injection_in_progress_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as mi_in_progress_count,
              SUM(CASE
                WHEN report.chimeras_obtained_date >= series.date
                  AND report.chimeras_obtained_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as chimeras_obtained_count,
              SUM(CASE
                WHEN report.genotype_confirmed_date >= series.date
                  AND report.genotype_confirmed_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as genotype_confirmed_count,
              SUM(CASE
                WHEN report.micro_injection_aborted_date >= series.date
                  AND report.micro_injection_aborted_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as mi_aborted_count,
              SUM(CASE
                WHEN report.phenotype_attempt_registered_date >= series.date
                  AND report.phenotype_attempt_registered_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as phenotype_registered_count,
              SUM(CASE
                WHEN report.rederivation_started_date >= series.date
                  AND report.rederivation_started_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as rederivation_started_count,
              SUM(CASE
                WHEN report.rederivation_complete_date >= series.date
                  AND report.rederivation_complete_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as rederivation_complete_count,
              SUM(CASE
                WHEN report.cre_excision_started_date >= series.date
                  AND report.cre_excision_started_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as cre_excision_started_count,
              SUM(CASE
                WHEN report.cre_excision_complete_date >= series.date
                  AND report.cre_excision_complete_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as cre_excision_complete_count,
              SUM(CASE
                WHEN report.phenotyping_started_date >= series.date
                  AND report.phenotyping_started_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as phenotype_started_count,
              SUM(CASE
                WHEN report.phenotyping_complete_date >= series.date
                  AND report.phenotyping_complete_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as phenotype_complete_count,
              SUM(CASE
                WHEN report.phenotype_attempt_aborted_date >= series.date
                  AND report.phenotype_attempt_aborted_date < date(series.date + interval '1 month')
                THEN 1 ELSE 0
              END) as phenotype_aborted_count
            FROM series
            CROSS JOIN (
              SELECT
                new_consortia_intermediate_report.consortium,
                CASE WHEN gene_consortium_commence_date.commenece_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE gene_consortium_commence_date.commenece_date END AS commenece_date,
                CASE WHEN assigned_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE assigned_date END AS assigned_date,
                CASE WHEN assigned_es_cell_qc_in_progress_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE assigned_es_cell_qc_in_progress_date END AS assigned_es_cell_qc_in_progress_date,
                CASE WHEN assigned_es_cell_qc_complete_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE assigned_es_cell_qc_complete_date END AS assigned_es_cell_qc_complete_date,
                CASE WHEN aborted_es_cell_qc_failed_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE aborted_es_cell_qc_failed_date END AS aborted_es_cell_qc_failed_date,
                CASE WHEN micro_injection_in_progress_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE micro_injection_in_progress_date END AS micro_injection_in_progress_date,
                CASE WHEN chimeras_obtained_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE chimeras_obtained_date END AS chimeras_obtained_date,
                CASE WHEN genotype_confirmed_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE genotype_confirmed_date END AS genotype_confirmed_date,
                CASE WHEN micro_injection_aborted_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE micro_injection_aborted_date END AS micro_injection_aborted_date,
                CASE WHEN phenotype_attempt_registered_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE phenotype_attempt_registered_date END AS phenotype_attempt_registered_date,
                CASE WHEN rederivation_started_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE rederivation_started_date END AS rederivation_started_date,
                CASE WHEN rederivation_complete_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE rederivation_complete_date END AS rederivation_complete_date,
                CASE WHEN cre_excision_started_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE cre_excision_started_date END AS cre_excision_started_date,
                CASE WHEN cre_excision_complete_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE cre_excision_complete_date END AS cre_excision_complete_date,
                CASE WHEN phenotyping_started_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE phenotyping_started_date END AS phenotyping_started_date,
                CASE WHEN phenotyping_complete_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE phenotyping_complete_date END AS phenotyping_complete_date,
                CASE WHEN phenotype_attempt_aborted_date < '2011-06-01 00:00:00' THEN '2011-05-01 00:00:00' ELSE phenotype_attempt_aborted_date END AS phenotype_attempt_aborted_date
              FROM new_consortia_intermediate_report
              JOIN
                (SELECT genes.marker_symbol AS gene, consortia.name AS consortium, min(mi_plan_commence_date.mi_plan_date) AS commenece_date
                   FROM mi_plans
                   JOIN (SELECT mi_plan_id as mi_plan_id, min(created_at) as mi_plan_date FROM mi_plan_status_stamps GROUP BY mi_plan_id) AS mi_plan_commence_date ON mi_plan_commence_date.mi_plan_id = mi_plans.id
                   JOIN genes ON genes.id = mi_plans.gene_id
                   JOIN consortia ON consortia.id = mi_plans.consortium_id
                 GROUP BY gene, consortium
                 ) AS gene_consortium_commence_date
                 ON gene_consortium_commence_date.gene = new_consortia_intermediate_report.gene AND gene_consortium_commence_date.consortium = new_consortia_intermediate_report.consortium
            ) as report
            WHERE report.consortium in ('#{available_consortia.join('\', \'')}')
            GROUP BY series.date, report.consortium
            ORDER BY series.date DESC
        )

        SELECT
          date,
          consortium,
          commenece_count,
          SUM(commenece_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_commenece,
          assigned_count,
          SUM(assigned_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_assigned,
          assigned_es_cell_count,
          SUM(assigned_es_cell_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_es_cells,
          es_cell_complete_count,
          SUM(es_cell_complete_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_es_cell_complete,
          es_cell_aborted_count,
          SUM(es_cell_aborted_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_es_cells_aborted,
          mi_in_progress_count,
          SUM(mi_in_progress_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_mis,
          chimeras_obtained_count,
          genotype_confirmed_count,
          SUM(genotype_confirmed_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_gcs,
          mi_aborted_count,
          phenotype_registered_count,
          SUM(phenotype_registered_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_phenotype_registered,
          rederivation_started_count,
          rederivation_complete_count,
          cre_excision_started_count,
          cre_excision_complete_count,
          SUM(cre_excision_complete_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_cre_excision_complete,
          phenotype_started_count,
          phenotype_complete_count,
          SUM(phenotype_complete_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_phenotype_complete,
          phenotype_aborted_count,
          production_goals.gc_goal as genotype_confirmed_goals,
          production_goals.mi_goal as mi_goal

        FROM counts
        LEFT JOIN consortia ON consortia.name = consortium
        LEFT JOIN production_goals ON date_part('year', date) = production_goals.year AND date_part('month', date) = production_goals.month AND consortia.id = production_goals.consortium_id
        ORDER BY date DESC;
      EOF
    end
  end

end