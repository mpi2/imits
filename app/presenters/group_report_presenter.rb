class GroupReportPresenter 

  ##
  ##  This is the base presenter for reports grouped by sub-project, and priority.
  ##  Statuses are taken from the intermediate report, efficiencies from live data tables.
  ##  Sub-classes must define `consortium`, `intermediate_group_field`, `efficiency_group_field_and_alias`
  ##  and `efficiency_join_statement` methods. See subclasses for examples. You could create new subclasses to group
  ##  by many other fields.
  ##

  attr_accessor :report_hash

  def initialize
    @report_hash = {
      :rows => []
    }

    self.generate_status_by
    self.generate_gene_efficiency_totals
    self.generate_clone_efficiency_totals
  end

  def statuses_by
    ActiveRecord::Base.connection.execute(self.class.statuses_by_sql)
  end

  def gene_efficiency_totals
    ActiveRecord::Base.connection.execute(self.class.gene_efficiency_totals_sql)
  end

  def clone_efficiency_totals
    ActiveRecord::Base.connection.execute(self.class.clone_efficiency_totals_sql)
  end

  def generate_status_by
    statuses_by.each do |report_row|

      field = report_row[self.class.intermediate_group_field]
      total_mice = report_row['total_mice'].to_i

      unless @report_hash[:rows].include?(field)
        @report_hash[:rows] << field
      end

      self.class.columns.each do |column|
        @report_hash["#{field}-#{column}"] ||= 0
      end

      @report_hash["#{field}-All genes"] += total_mice

      mi_plan_status = report_row['mi_plan_status']

      if ['Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Aborted - ES Cell QC Failed'].include?(mi_plan_status)
        @report_hash["#{field}-ES cell QC"] += total_mice
      end

      if 'Assigned - ES Cell QC Complete' == mi_plan_status
        @report_hash["#{field}-ES QC confirmed"] += total_mice
      end

      if 'Aborted - ES Cell QC Failed' == mi_plan_status
        @report_hash["#{field}-ES QC failed"] += total_mice
      end

      mi_attempt_status = report_row['mi_attempt_status']

      if ['Micro-injection in progress', 'Micro-injection aborted', 'Chimeras obtained', 'Genotype confirmed'].include?(mi_attempt_status)
        @report_hash["#{field}-Microinjections"] += total_mice
      end

      if 'Chimeras obtained' == mi_attempt_status
        @report_hash["#{field}-Chimaeras produced"] += total_mice
      end

      if 'Genotype confirmed' == mi_attempt_status
        @report_hash["#{field}-Genotype confirmed mice"] += total_mice
      end

      if 'Micro-injection aborted' == mi_attempt_status
        @report_hash["#{field}-Microinjection aborted"] += total_mice
      end

      @report_hash["#{field}-Genotype confirmed mice 6 months"] += report_row['gtc_in_6months'].to_i
      @report_hash["#{field}-Microinjection aborted 6 months"] += report_row['abt_in_6months'].to_i
      @report_hash["#{field}-Languishing"] += report_row['languishing'].to_i

      phenotype_attempt_status = report_row['phenotype_attempt_status']

      unless phenotype_attempt_status.blank?
        @report_hash["#{field}-Registered for phenotyping"] += total_mice
      end

      if 'Cre Excision Started' == phenotype_attempt_status
        @report_hash["#{field}-Cre excision started"] += total_mice
      end

      if 'Cre Excision Complete' == phenotype_attempt_status
        @report_hash["#{field}-Cre excision completed"] += total_mice
      end

      if 'Phenotyping Started' == phenotype_attempt_status
        @report_hash["#{field}-Phenotyping started"] += total_mice
      end

      if 'Phenotyping Complete' == phenotype_attempt_status
        @report_hash["#{field}-Phenotyping completed"] += total_mice
      end

      if 'Phenotype Attempt Aborted' == phenotype_attempt_status
        @report_hash["#{field}-Phenotyping aborted"] += total_mice
      end
    end

    @report_hash
  end

  def generate_gene_efficiency_totals
    gene_efficiency_totals.each do |report_row|
      field = report_row[self.class.efficiency_group_field_and_alias[:name]]

      total  = @report_hash["#{field}-Total Pipeline Efficiency Gene Count"] = report_row['total_mice'].to_f
      subset = @report_hash["#{field}-GC Pipeline Efficiency Gene Count"]    = report_row['gtc_mice'].to_f

      percentage = if subset == 0.0 && total > 0.0
        0.0
      elsif total == 0.0 && subset > 0.0
        100.0
      else
        (subset / total) * 100.0
      end.ceil

      @report_hash["#{field}-Gene Pipeline efficiency (%)"] = percentage
    end

    @report_hash
  end

  def generate_clone_efficiency_totals
    clone_efficiency_totals.each do |report_row|
      field = report_row[self.class.efficiency_group_field_and_alias[:name]]

      total  = @report_hash["#{field}-Total Pipeline Efficiency Clone Count"] = report_row['total_mice'].to_f
      subset = @report_hash["#{field}-GC Pipeline Efficiency Clone Count"]    = report_row['gtc_mice'].to_f
    
      percentage = if subset == 0.0 && total > 0.0
        0.0
      elsif total == 0.0 && subset > 0.0
        100.0
      else
        (subset / total) * 100.0
      end.ceil

      @report_hash["#{field}-Clone Pipeline efficiency (%)"] = percentage
    end

    @report_hash
  end

  ##
  ## Class Methods
  ##

  class << self

    def consortium
      raise Tarmits::MethodNotImplemented
    end

    def intermediate_group_field
      raise Tarmits::MethodNotImplemented
    end

    def efficiency_group_field_and_alias
      raise Tarmits::MethodNotImplemented
    end

    def efficiency_join_statement
      raise Tarmits::MethodNotImplemented
    end

    def columns
      [
        'All genes',
        'ES cell QC',
        'ES QC confirmed',
        'ES QC failed',
        'Microinjections',
        'Chimaeras produced',
        'Genotype confirmed mice',
        'Microinjection aborted',
        'Gene Pipeline efficiency (%)',
        'Clone Pipeline efficiency (%)',
        'Genotype confirmed mice 6 months',
        'Microinjection aborted 6 months',
        'Languishing',
        'Registered for phenotyping',
        'Cre excision started',
        'Cre excision completed',
        'Phenotyping started',
        'Phenotyping completed',
        'Phenotyping aborted',
        'GC Pipeline Efficiency Gene Count',
        'Total Pipeline Efficiency Gene Count'
      ]
    end

    def six_months_ago
      6.months.ago.to_s(:db)
    end

    def statuses_by_sql
      sql = <<-EOF
        SELECT
        #{intermediate_group_field},
        mi_plan_status,
        mi_attempt_status,
        phenotype_attempt_status,
        count(intermediate_report.id) as total_mice,
        sum(case when gtc_stamps.created_at < '#{six_months_ago}' then 1 else 0 end) as gtc_in_6months,
        sum(case when abt_stamps.created_at < '#{six_months_ago}' then 1 else 0 end) as abt_in_6months,
        sum(case when mip_stamps.created_at < '#{six_months_ago}' then 1 else 0 end) as languishing
        FROM intermediate_report
        LEFT JOIN mi_attempts ON mi_attempts.colony_name = intermediate_report.mi_attempt_colony_name
        LEFT JOIN mi_attempt_status_stamps as gtc_stamps ON gtc_stamps.mi_attempt_id = mi_attempts.id AND gtc_stamps.status_id = 2 AND mi_attempts.status_id != 3
        LEFT JOIN mi_attempt_status_stamps as abt_stamps ON abt_stamps.mi_attempt_id = mi_attempts.id AND abt_stamps.status_id = 3 AND mi_attempts.status_id = 3
        LEFT JOIN mi_attempt_status_stamps as mip_stamps ON mip_stamps.mi_attempt_id = mi_attempts.id AND mip_stamps.status_id = 1 AND (mi_attempts.status_id = 1 OR mi_attempts.status_id = 4)
        WHERE consortium = '#{consortium}'
        GROUP BY #{intermediate_group_field}, mi_plan_status, mi_attempt_status, phenotype_attempt_status
        ORDER BY #{intermediate_group_field} ASC
      EOF
    end

    def gene_efficiency_totals_sql
      sql = <<-EOF
        SELECT
        counts.#{efficiency_group_field_and_alias[:name]},
        sum(case when counts.gtc_count > 0 then 1 else 0 end) as gtc_mice,
        sum(c) as total_mice
        FROM (
          SELECT
          genes.id as gene_id,
          #{efficiency_group_field_and_alias[:field]} as #{efficiency_group_field_and_alias[:name]},
          sum(case when mi_attempts.status_id = 2 then 1 else 0 end) as gtc_count,
          1 as c
          FROM genes
          JOIN targ_rep_alleles ON genes.id = targ_rep_alleles.gene_id
          JOIN targ_rep_es_cells ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
          JOIN mi_attempts ON targ_rep_es_cells.id = mi_attempts.es_cell_id
          JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
          #{efficiency_join_statement}
          JOIN mi_attempt_status_stamps ON mi_attempts.id = mi_attempt_status_stamps.mi_attempt_id AND mi_attempt_status_stamps.status_id = 1
          JOIN consortia ON consortia.id = mi_plans.consortium_id
          WHERE mi_attempt_status_stamps.created_at < '#{six_months_ago}'
            AND consortia.name = '#{consortium}'
          GROUP BY genes.id, #{efficiency_group_field_and_alias[:name]}
          ORDER BY #{efficiency_group_field_and_alias[:name]} ASC
        ) as counts
        GROUP BY counts.#{efficiency_group_field_and_alias[:name]}
      EOF
    end

    def clone_efficiency_totals_sql
      sql = <<-EOF
        SELECT
        counts.#{efficiency_group_field_and_alias[:name]},
        sum(case when counts.gtc_count > 0 then 1 else 0 end) as gtc_mice,
        sum(c) as total_mice
        FROM (
          SELECT
          targ_rep_es_cells.id as cell,
          #{efficiency_group_field_and_alias[:field]} as #{efficiency_group_field_and_alias[:name]},
          sum(case when mi_attempts.status_id = 2 then 1 else 0 end) as gtc_count,
          1 as c
          FROM targ_rep_es_cells
          JOIN mi_attempts ON targ_rep_es_cells.id = mi_attempts.es_cell_id
          JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
          JOIN consortia ON consortia.id = mi_plans.consortium_id
          JOIN mi_attempt_status_stamps ON mi_attempts.id = mi_attempt_status_stamps.mi_attempt_id AND mi_attempt_status_stamps.status_id = 1
          #{efficiency_join_statement}
          WHERE mi_attempt_status_stamps.created_at < '#{six_months_ago}'
            AND consortia.name = '#{consortium}'
          GROUP BY targ_rep_es_cells.id, #{efficiency_group_field_and_alias[:name]}
          ORDER BY #{efficiency_group_field_and_alias[:name]} ASC
        ) as counts
        GROUP BY counts.#{efficiency_group_field_and_alias[:name]}
      EOF
    end
  end

end