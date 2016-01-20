class PlannedMicroinjectionWtsiList     #< PlannedMicroinjectionList

  def mi_plan_summary(production_centre = 'WTSI')
    @mi_plan_summary2 = ActiveRecord::Base.connection.execute(self._mi_plan_summary(production_centre))

    @mi_plan_summary = []

    @mi_plan_summary2.each do |row|
      row['processed_status'] = ''

      array = [
        'Genotype confirmed',
        'Chimeras obtained',
        'Micro-injection in progress',
        'Micro-injection aborted'
      ]

      if row['processed_status'].to_s.empty? && ! row['mi_attempt_status'].to_s.empty?
        array.each do |status|
          if ! row['mi_attempt_status'].to_s.index(status).nil?
            row['processed_status'] = status
            break
          end
        end
      end

      if row['processed_status'].to_s.empty?

        array = [
          'Assigned - ES Cell QC In Progress',
          'Assigned - ES Cell QC Complete',
          'Aborted - ES Cell QC Failed',
          'Assigned',
          'Inspect - GLT Mouse',
          'Inspect - MI Attempt',
          'Inspect - Conflict',
          'Conflict',
          'Interest',
          'Inactive',
          'Withdrawn'
        ]

        array.each do |status|
         # puts "#### status: #{status}: #{row['mi_plan_status'].to_s.index(status).to_i}"
          if ! row['mi_plan_status'].to_s.index(status).nil?
            row['processed_status'] = status
            break
          end
        end

      if row['phenotype_attempt_status'].to_s.empty? || row['phenotype_attempt_status'].to_s =~ /Aborted/i
        row['phenotype_attempt_status'] = ''
      end

      end

      row['centre_name'] = production_centre
      row['consortium_name'] = row['consortium_name'].gsub(/\|/, '; ')

      @mi_plan_summary.push row
    end

    @mi_plan_summary
  end

  def _mi_plan_summary(production_centre = nil)

    sql = <<-EOF
    WITH plan_summary AS (#{IntermediateReportSummaryByMiPlan.es_cell_and_crsipr_sql})

    SELECT
    plan_summary.gene AS marker_symbol,
    plan_summary.mgi_accession_id AS mgi_accession_id,
    string_agg(plan_summary.consortium, '|') AS consortium_name,
    string_agg(plan_summary.production_centre, '|') AS centre_name,
    string_agg(plan_summary.plan_status, '|') AS plan_status,
    string_agg(plan_summary.mi_attempt_status, '|') AS mi_attempt_status,
    string_agg(plan_summary.mouse_allele_mod_status, '|') AS mouse_allele_mod_status,
    string_agg(plan_summary.phenotyping_status, '|') AS phenotyping_status,
    string_agg(
      CASE WHEN plan_summary.mouse_allele_mod_status IS NOT NULL AND plan_summary.mouse_allele_mod_status != 'Mouse Allele Modification Aborted'
        THEN
          plan_summary.mouse_allele_mod_status
        ELSE
          (CASE WHEN plan_summary.phenotyping_status = 'Phenotype Production Aborted' THEN 'Phenotype Attempt Aborted' ELSE plan_summary.phenotyping_status END )
      END
    , '|') AS phenotype_attempt_status
    FROM plan_summary
    where plan_summary.production_centre = '#{production_centre}'
    group by plan_summary.gene, plan_summary.mgi_accession_id
    order by plan_summary.gene
    EOF

    sql

  end
end
