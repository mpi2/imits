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
      [
        'BaSH',
        'DTCC',
        'DTCC-Legacy',
        'EUCOMM-EUMODIC',
        'EUCOMMToolsCre',
        'Helmholtz GMC',
        'JAX',
        'MARC',
        'MGP',
        'MGP Legacy',
        'MRC',
        'Monterotondo',
        'NorCOMM2',
        'Phenomin',
        'RIKEN BRC',
        'UCD-KOMP'
      ]
    end

    def columns
      {
        "Cumulative ES Starts"   => :cumulative_es_cells,
        "ES Cell QC In Progress" => :assigned_es_cell_count,
        "ES Cell QC Complete"    => :es_cell_complete_count,
        "ES Cell QC Failed"      => :es_cell_aborted_count,
        "Micro-Injection In Progress" => :mi_in_progress_count,
        "Cumulative MIs"         => :cumulative_mis,
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
        "Phenotype Attempt Aborted" => :phenotype_aborted_count
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

    def summary_by_month_sql
      sql = <<-EOF
        WITH
          series AS (
            SELECT generate_series('2011-06-01 00:00:00', '#{Time.now.to_date.to_s(:db)}', interval '1 month')::date as date
          ),
             
          counts AS (
            SELECT
              series.date as date,
              report.consortium as consortium,
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
            CROSS JOIN new_intermediate_report as report
            WHERE consortium in ('#{available_consortia.join('\', \'')}')
            GROUP BY series.date, report.consortium
            ORDER BY series.date DESC
        )

        SELECT
          date,
          consortium,
          assigned_es_cell_count,
          SUM(assigned_es_cell_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_es_cells,
          es_cell_complete_count,
          es_cell_aborted_count,
          mi_in_progress_count,
          SUM(mi_in_progress_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_mis,
          chimeras_obtained_count,
          genotype_confirmed_count,
          SUM(genotype_confirmed_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_gcs,
          mi_aborted_count,
          phenotype_registered_count,
          rederivation_started_count,
          rederivation_complete_count,
          cre_excision_started_count,
          cre_excision_complete_count,
          phenotype_started_count,
          phenotype_complete_count,
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