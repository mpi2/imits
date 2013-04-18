class BaseProductionReportPresenter < BaseReportPresenter

  attr_accessor :consortium_by_status
  attr_accessor :consortium_centre_by_status
  attr_accessor :consortium_by_distinct_gene
  attr_accessor :gene_efficiency_totals
  attr_accessor :clone_efficiency_totals
  attr_accessor :available_consortia

  def available_consortia
    @available_consortia if @available_consortia && !@available_consortia.empty?
    self.class.available_consortia
  end

  def available_consortia=(array)
    @available_consortia = array
  end

  def consortium_by_status
    @consortium_by_status ||= ActiveRecord::Base.connection.execute(self.class.consortium_by_status_sql)
  end

  def consortium_centre_by_status
    @consortium_centre_by_status ||= ActiveRecord::Base.connection.execute(self.class.consortium_centre_by_status_sql)
  end

  def consortium_centre_by_phenotyping_status
    ActiveRecord::Base.connection.execute(self.class.consortium_centre_by_phenotyping_status_sql)
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

      non_cumulative_status = report_row['mi_attempt_status']

      if ['Micro-injection in progress', 'Micro-injection aborted', 'Chimeras obtained', 'Genotype confirmed'].include?(non_cumulative_status)
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Microinjections"] += report_row['count'].to_i
      end

      if 'Chimeras obtained' == non_cumulative_status
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Chimeras"] += report_row['count'].to_i
      end

      if 'Genotype confirmed' == non_cumulative_status
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Genotype Confirmed Mice"] += report_row['count'].to_i
      end

      if 'Micro-injection aborted' == non_cumulative_status
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Microinjection aborted"] += report_row['count'].to_i
      end
    
    end

    hash
  end

  def generate_consortium_centre_by_phenotyping_status
    hash = {}

    consortium_centre_by_phenotyping_status.each do |report_row|
      next if report_row['production_centre'].blank?

      hash["#{report_row['consortium']}"] = hash["#{report_row['consortium']}"] || []
      if !hash["#{report_row['consortium']}"].include?(report_row['production_centre'])
        hash["#{report_row['consortium']}"] << report_row['production_centre']
      end

      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Intent to phenotype"]    ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Cre excision started"]   ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Cre excision completed"] ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping started"]    ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping completed"]  ||= 0
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping aborted"]    ||= 0

      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Intent to phenotype"]    += report_row["count"].to_i

      if report_row['phenotype_attempt_status'] == 'Cre Excision Started'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Cre excision started"]   += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Cre Excision Complete'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Cre excision completed"] += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Phenotyping Started'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping started"]   += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Phenotyping Complete'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping completed"] += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Phenotype Attempt Aborted'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping aborted"]   += report_row["count"].to_i
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

  class << self

    def mi_plan_statuses
      ['ES Cell QC', 'ES QC Confirmed', 'ES QC Failed']
    end

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

    def consortium_by_distinct_gene_sql
      sql = <<-EOF
        SELECT
        consortium,
        COUNT(distinct(gene))
        FROM intermediate_report
        WHERE consortium in ('#{available_consortia.join('\', \'')}')
        GROUP BY consortium;
      EOF
    end

    def consortium_by_status_sql
      sql = <<-EOF
        SELECT 
        consortium,
        mi_plan_status,
        COUNT(*)
        FROM intermediate_report
        WHERE consortium in ('#{available_consortia.join('\', \'')}')
        GROUP BY consortium, mi_plan_status
        ORDER BY consortium;
      EOF
    end

    def consortium_centre_by_status_sql
      sql = <<-EOF
        SELECT
        consortium,
        production_centre,
        mi_attempt_status,
        COUNT(*)
        FROM intermediate_report
        WHERE consortium in ('#{available_consortia.join('\', \'')}')
        GROUP BY consortium, production_centre, mi_attempt_status
        ORDER BY consortium, production_centre;
      EOF
    end

    def consortium_centre_by_phenotyping_status_sql
      sql = <<-EOF
        SELECT
        consortium,
        production_centre,
        phenotype_attempt_status,
        COUNT(*)
        FROM intermediate_report
        JOIN phenotype_attempts ON intermediate_report.phenotype_attempt_colony_name = phenotype_attempts.colony_name
        WHERE consortium in ('#{available_consortia.join('\', \'')}')
        GROUP BY consortium, production_centre, phenotype_attempt_status
        ORDER BY consortium, production_centre;
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
          WHERE mi_attempt_status_stamps.created_at > '#{report_cut_off_date}'
                  AND mi_attempt_status_stamps.created_at < '#{6.months.ago.to_s(:db)}'
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
          WHERE mi_attempt_status_stamps.created_at > '#{report_cut_off_date}'
                  AND mi_attempt_status_stamps.created_at < '#{6.months.ago.to_s(:db)}'
            AND consortia.name in ('#{available_consortia.join('\', \'')}')
          GROUP BY targ_rep_es_cells.id, consortium_name, production_centre_name
        ) as counts
        GROUP BY counts.consortium_name, counts.production_centre_name
      EOF
    end
  end

end