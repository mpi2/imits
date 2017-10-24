class BaseSummaryByMonthReport
  attr_accessor :available_consortia
  ##
  ##  This is the base presenter for reporting on counts of statuses for particular months,
  ##  this report uses the intermediate report table.
  ##

  attr_accessor :report_hash, :category, :approach, :allele_type

  def initialize(consortia_list=nil, category = 'es cell', approach = 'all', allele_type = 'all')
    @category = category || 'es cell'
    @approach = approach || 'all'
    @allele_type = allele_type || 'all'

    self.available_consortia = consortia_list
    @report_hash = {
      :dates => {}
    }

    self.generate_summary_by_month
  end

  def summary_by_month
    ActiveRecord::Base.connection.execute(summary_by_month_sql)
  end

  def generate_summary_by_month

    @back_fill_goals = {}
    summary_by_month.each do |report_row|

      consortium = report_row['consortium']
      @back_fill_goals[consortium] = {'mi_goal' => {'last_goal' => 0 , 'next_goal' => 0 , 'year_of_next_goal' => 2016, 'month_of_next_goal' => 07, 'final_goal' => 0 , 'year_of_final_goal' => 2016, 'month_of_final_goal' => 07},
                                      'gc_goal' => {'last_goal' => 0 , 'next_goal' => 0 , 'year_of_next_goal' => 2016, 'month_of_next_goal' => 07, 'final_goal' => 0 , 'year_of_final_goal' => 2016, 'month_of_final_goal' => 07}} unless @back_fill_goals.has_key?(consortium)
      date = Date.parse(report_row['date'])

      if @report_hash[:dates].include?(date.year)
        @report_hash[:dates][date.year] << date
      else
        @report_hash[:dates][date.year] = [date]
      end

      columns.to_a.each do |heading, key|
        if ["mi_goal", "gc_goal"].include?(key.to_s)
          value = fill_in_goals(key.to_s, report_row)
        else
          value = report_row[key.to_s]
        end

        @report_hash["#{consortium}-#{date}-#{heading}"] = value
      end
    end
  end

  def select_goal(goal_type)
     goals = {'es cell' => {:mi_goal => 'mi_goal' ,      :gc_goal => 'gc_goal'},
             'crispr'  => {:mi_goal => 'crispr_mi_goal', :gc_goal => 'crispr_gc_goal'},
             'all'     => {:mi_goal => 'total_mi_goal',  :gc_goal => 'total_gc_goal'}}

     return goals[category][goal_type]
  end

  def fill_in_goals(goal_type, row)
    if row[goal_type].nil?
      last_goal = @back_fill_goals[row['consortium']][goal_type]['last_goal'].to_i
      this_goal_month = row['date'].to_date.month
      this_goal_year = row['date'].to_date.year

      if last_goal == 0 || @back_fill_goals[row['consortium']][goal_type]['next_goal'].to_i != 0
        next_goal = @back_fill_goals[row['consortium']][goal_type]['next_goal'].to_i
        next_goal_year = @back_fill_goals[row['consortium']][goal_type]['year_of_next_goal'].to_i
        next_goal_month = @back_fill_goals[row['consortium']][goal_type]['month_of_next_goal'].to_i
      else
        next_goal = @back_fill_goals[row['consortium']][goal_type]['final_goal'].to_i
        @back_fill_goals[row['consortium']][goal_type]['year_of_final_goal'].to_i
        next_goal_month = @back_fill_goals[row['consortium']][goal_type]['month_of_final_goal'].to_i

      end

      month_difference = (next_goal_year.to_i - this_goal_year.to_i) * 12 + (next_goal_month.to_i - this_goal_month.to_i)
      goal = month_difference == 0 ? 0 : last_goal + ( (next_goal - last_goal) / (month_difference))
      @back_fill_goals[row['consortium']][goal_type]['last_goal'] = goal

    else
      goal = row[goal_type]
      @back_fill_goals[row['consortium']][goal_type]['last_goal'] = goal
      @back_fill_goals[row['consortium']][goal_type]['next_goal'] = row["next_#{goal_type}"]
      @back_fill_goals[row['consortium']][goal_type]['month_of_next_goal'] = row["month_of_next_goal"]
      @back_fill_goals[row['consortium']][goal_type]['year_of_next_goal'] = row["year_of_next_goal"]

      @back_fill_goals[row['consortium']][goal_type]['final_goal'] = row["final_#{goal_type}"]
      @back_fill_goals[row['consortium']][goal_type]['month_of_final_goal'] = row["final_goal_month"]
      @back_fill_goals[row['consortium']][goal_type]['year_of_final_goal'] = row["final_goal_year"]
    end

    return goal
  end


  def columns

    return { "Gene Interest" => :commenece_count,
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
      "GC Goal"            => :gc_goal,
      "Micro-injection aborted"      => :mi_aborted_count,
      "Phenotype Attempt Registered" => :phenotype_registered_count,
      "Rederivation Started"  => :rederivation_started_count,
      "Rederivation Complete" => :rederivation_complete_count,
      "Cre Excision Started"  => :cre_excision_started_count,
      "Cre Excision Complete" => :cre_excision_complete_count,
      "Phenotyping Started"   => :phenotype_started_count,
      "Phenotyping Experiments Started" => :phenotyping_experiments_started_count,
      "Phenotyping Complete"  => :phenotype_complete_count,
      "Phenotype Attempt Aborted" => :phenotype_aborted_count,

      "Cumulative Phenotype Registered" => :cumulative_phenotype_registered,
      "Cumulative Cre Excision Complete" => :cumulative_cre_excision_complete,
      "Cumulative Phenotyping Experiments Started" => :cumulative_phenotyping_experiments_started,
      "Cumulative Phenotype Started" => :cumulative_phenotype_started,
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
    (Time.now - 1.month).to_date.to_s(:db)
  end

  def summary_by_month_sql(previous_month = false)
    puts "CATEGORIES FDS #{@category}, #{@approach}, #{@allele_type}"
    from_date = '2011-06-01'.to_datetime
    from_date_minus_a_month = from_date - 1.month

    from_date = from_date.to_s(:db)
    from_date_minus_a_month = from_date_minus_a_month.to_s(:db)
    if previous_month
      up_to_date = date_previous_month
    else
      up_to_date = Time.now.to_date.to_s(:db)
    end


    sql = <<-EOF
      WITH
        goals AS (
          SELECT  row_number() OVER (PARTITION BY ordered_goals.consortium_id) AS rank,
                  ordered_goals.consortium_id, ordered_goals.year, ordered_goals.month, ordered_goals.mi_goal, ordered_goals.gc_goal,
                  last_value(ordered_goals.year) OVER (PARTITION BY ordered_goals.consortium_id) AS final_goal_year,
                  last_value(ordered_goals.month) OVER (PARTITION BY ordered_goals.consortium_id) AS final_goal_month,
                  last_value(ordered_goals.mi_goal) OVER (PARTITION BY ordered_goals.consortium_id) AS final_mi_goal,
                  last_value(ordered_goals.gc_goal) OVER (PARTITION BY ordered_goals.consortium_id) AS final_gc_goal
            FROM (
              SELECT consortium_id, year, month, #{select_goal(:mi_goal)} AS mi_goal, #{select_goal(:gc_goal)} AS gc_goal
                FROM production_goals
               WHERE #{select_goal(:mi_goal)} IS NOT NULL AND #{select_goal(:gc_goal)} IS NOT NULL
               ORDER BY consortium_id, year, month
              ) AS ordered_goals
        ),

        goals_with_next_goal AS (
          SELECT goals.*,
                 goals_plus_one.year AS year_of_next_goal,
                 goals_plus_one.month AS month_of_next_goal,
                 goals_plus_one.mi_goal AS next_mi_goal,
                 goals_plus_one.gc_goal AS next_gc_goal
          FROM goals
          LEFT JOIN goals goals_plus_one ON (goals_plus_one.rank - 1) = goals.rank AND goals_plus_one.consortium_id = goals.consortium_id
        ),

        -- create a series of dates for each month from the 2011-06-01 (from_date) to now. NOTE 2011-05-01 (from_date_minus_a_month) will store all production prior to 2011-06-01 (Easiest bodge).
        consortium_summary AS ( #{IntermediateReportSummaryByConsortia.select_sql(@category, @approach, @allele_type)}
        ),
        series AS (
          SELECT generate_series('#{from_date_minus_a_month}', '#{up_to_date}', interval '1 month')::date as date
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
              WHEN report.phenotyping_registered_date >= series.date
                AND report.phenotyping_registered_date < date(series.date + interval '1 month')
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
                WHEN report.phenotyping_experiments_started_date >= series.date
                AND report.phenotyping_experiments_started_date < date(series.date + interval '1 month')
              THEN 1 ELSE 0
            END) as phenotyping_experiments_started_count,
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
              consortium_summary.consortium,
              CASE WHEN consortium_summary.gene_interest_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE consortium_summary.gene_interest_date END AS commenece_date,
              CASE WHEN assigned_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE assigned_date END AS assigned_date,
              CASE WHEN assigned_es_cell_qc_in_progress_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE assigned_es_cell_qc_in_progress_date END AS assigned_es_cell_qc_in_progress_date,
              CASE WHEN assigned_es_cell_qc_complete_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE assigned_es_cell_qc_complete_date END AS assigned_es_cell_qc_complete_date,
              CASE WHEN aborted_es_cell_qc_failed_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE aborted_es_cell_qc_failed_date END AS aborted_es_cell_qc_failed_date,
              CASE WHEN micro_injection_in_progress_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE micro_injection_in_progress_date END AS micro_injection_in_progress_date,
              CASE WHEN chimeras_obtained_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE chimeras_obtained_date END AS chimeras_obtained_date,
              CASE WHEN genotype_confirmed_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE genotype_confirmed_date END AS genotype_confirmed_date,
              CASE WHEN micro_injection_aborted_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE micro_injection_aborted_date END AS micro_injection_aborted_date,
              CASE WHEN phenotyping_registered_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE phenotyping_registered_date END AS phenotyping_registered_date,
              CASE WHEN rederivation_started_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE rederivation_started_date END AS rederivation_started_date,
              CASE WHEN rederivation_complete_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE rederivation_complete_date END AS rederivation_complete_date,
              CASE WHEN cre_excision_started_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE cre_excision_started_date END AS cre_excision_started_date,
              CASE WHEN cre_excision_complete_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE cre_excision_complete_date END AS cre_excision_complete_date,
              CASE WHEN phenotyping_started_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE phenotyping_started_date END AS phenotyping_started_date,
              CASE WHEN phenotyping_experiments_started_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE phenotyping_experiments_started_date END AS phenotyping_experiments_started_date,
              CASE WHEN phenotyping_complete_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE phenotyping_complete_date END AS phenotyping_complete_date,
              CASE WHEN phenotype_attempt_aborted_date < '#{from_date}' THEN '#{from_date_minus_a_month}' ELSE phenotype_attempt_aborted_date END AS phenotype_attempt_aborted_date
            FROM consortium_summary
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
        SUM(phenotype_started_count) OVER (PARTITION BY consortium ORDER BY date) AS cumulative_phenotype_started,
        phenotyping_experiments_started_count,
        SUM(phenotyping_experiments_started_count) OVER (PARTITION BY consortium ORDER BY date) AS cumulative_phenotyping_experiments_started,
        phenotype_complete_count,
        SUM(phenotype_complete_count) OVER (PARTITION BY consortium ORDER BY date) as cumulative_phenotype_complete,
        phenotype_aborted_count,
        goals_with_next_goal.gc_goal AS gc_goal,
        goals_with_next_goal.mi_goal AS mi_goal,
        goals_with_next_goal.next_mi_goal AS next_mi_goal,
        goals_with_next_goal.next_gc_goal AS next_gc_goal,
        goals_with_next_goal.month_of_next_goal AS month_of_next_goal,
        goals_with_next_goal.year_of_next_goal AS year_of_next_goal,
        goals_with_next_goal.final_goal_year AS final_goal_year,
        goals_with_next_goal.final_goal_month AS final_goal_month,
        goals_with_next_goal.final_mi_goal AS final_mi_goal,
        goals_with_next_goal.final_gc_goal AS final_gc_goal

      FROM counts
      LEFT JOIN consortia ON consortia.name = consortium
      LEFT JOIN goals_with_next_goal ON date_part('year', date) = goals_with_next_goal.year AND date_part('month', date) = goals_with_next_goal.month AND consortia.id = goals_with_next_goal.consortium_id
      ORDER BY date_part('year', date), date_part('month', date) DESC;
    EOF
  end

end
