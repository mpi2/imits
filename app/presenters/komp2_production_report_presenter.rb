class Komp2ProductionReportPresenter < BaseProductionReportPresenter

  ## See superclass for inherited methods.

  def consortium_centre_by_phenotyping_status(cre_excision_required)
    ActiveRecord::Base.connection.execute(self.class.consortium_centre_by_phenotyping_status_sql(cre_excision_required))
  end

  def generate_consortium_centre_by_phenotyping_status(cre_excision_required = true)
    hash = {}

    consortium_centre_by_phenotyping_status(cre_excision_required).each do |report_row|
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
      
      hash["#{report_row['consortium']}-#{report_row['production_centre']}-Intent to phenotype"] += report_row["count"].to_i
      
      if report_row['phenotype_attempt_status'] == 'Cre Excision Started'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Cre excision started"] += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Cre Excision Complete'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Cre excision completed"] += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Phenotyping Started'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping started"] += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Phenotyping Complete'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping completed"] += report_row["count"].to_i
      end

      if report_row['phenotype_attempt_status'] == 'Phenotype Attempt Aborted'
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-Phenotyping aborted"] += report_row["count"].to_i
      end

    end

    hash
  end

  class << self
    def available_consortia
      ['BaSH', 'DTCC', 'JAX']
    end


    def consortium_centre_by_phenotyping_status_sql(cre_excision_required = true)
      sql = <<-EOF
        SELECT
        consortium,
        production_centre,
        phenotype_attempt_status,
        COUNT(*)
        FROM intermediate_report
        JOIN phenotype_attempts ON intermediate_report.phenotype_attempt_colony_name = phenotype_attempts.colony_name AND phenotype_attempts.cre_excision_required is #{cre_excision_required}
        WHERE consortium in ('#{available_consortia.join('\', \'')}')
        GROUP BY consortium, production_centre, phenotype_attempt_status
        ORDER BY consortium, production_centre;
      EOF
    end
  end

end