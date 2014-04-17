class PlannedMicroinjectionWtsiList     #< PlannedMicroinjectionList

  def mi_plan_summary(production_centre = 'WTSI')
    @mi_plan_summary2 = ActiveRecord::Base.connection.execute(self._mi_plan_summary(production_centre))

    @mi_plan_summary = []

    @mi_plan_summary2.each do |row|
      row['processed_status'] = ''

      #if ! row['phenotype_attempt_status'].to_s.empty?
      #  row['processed_status'] = row['phenotype_attempt_status']
      #elsif ! row['mi_attempt_status'].to_s.empty?
      #  row['processed_status'] = row['mi_attempt_status']
      #else
      #  if row['mi_plan_status'].to_s !~ /Inactive/
      #    row['processed_status'] = row['mi_plan_status']
      #  end
      #end

      #if ! row['phenotype_attempt_status'].to_s.empty? && row['phenotype_attempt_status'].to_s !~ /Aborted/i
      #  row['processed_status'] = row['phenotype_attempt_status']
      #end

      #array = ['Genotype confirmed', 'Micro-injection in progress', 'Micro-injection aborted']
      #
      #if ! row['processed_status'].to_s.empty?
      #  array.each do |regex|
      #    if row['mi_attempt_status'].to_s.index(regex).to_i > -1
      #      row['processed_status'] = regex.to_s
      #      break
      #    end
      #  end
      #end

      #if row['processed_status'].to_s.empty? && ! row['mi_attempt_status'].to_s.empty?
      #  if row['mi_attempt_status'].to_s =~ /Genotype confirmed/
      #    row['processed_status'] = 'Genotype confirmed'
      #  elsif row['mi_attempt_status'].to_s =~ /Chimeras obtained/
      #    row['processed_status'] = 'Chimeras obtained'
      #  elsif row['mi_attempt_status'].to_s =~ /Micro.injection in progress/
      #    row['processed_status'] = 'Micro-injection in progress'
      #  elsif row['mi_attempt_status'].to_s =~ /Micro.injection aborted/
      #    row['processed_status'] = 'Micro-injection aborted'
      #    #else
      #    #row['processed_status'] = 'other mi'
      #  end
      #end

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
        #  row['processed_status'] = row['mi_plan_status']
        #row['processed_status'] = 'default'

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

      @mi_plan_summary.push row
    end

    @mi_plan_summary
  end

  #Aborted - ES Cell QC Failed
  #Conflict
  #Assigned
  #Cre Excision Started
  #Inspect - MI Attempt
  #Micro-injection aborted
  #Inspect - GLT Mouse
  #Inactive
  #Micro-injection in progress
  #Assigned - ES Cell QC In Progress
  #Phenotype Attempt Aborted
  #Chimeras obtained
  #Assigned - ES Cell QC Complete
  #Phenotype Attempt Registered
  #Genotype confirmed
  #Inspect - Conflict
  #Rederivation Complete
  #Cre Excision Complete
  #Phenotyping Started
  #Withdrawn
  #Rederivation Started

  #b) If there's a plan (which is not inactive) => 'planned' (don't use the status here).
  #     If there's any production activity => MI in progress, If there's a GC mouse => GC mouse.
  #c) If there's any PA => report status of PA.

  def _mi_plan_summary(production_centre = nil)

    #sql = <<-EOF
    #SELECT
    #  new_intermediate_report.mi_plan_id AS mi_plan_id,
    #  new_intermediate_report.gene AS marker_symbol,
    #  new_intermediate_report.mgi_accession_id AS mgi_accession_id,
    #  new_intermediate_report.consortium AS consortium_name,
    #  new_intermediate_report.production_centre AS centre_name,
    #  new_intermediate_report.mi_plan_status AS mi_plan_status,
    #  new_intermediate_report.overall_status AS overall_status,
    #  new_intermediate_report.mi_attempt_status AS mi_attempt_status,
    #  new_intermediate_report.phenotype_attempt_status AS phenotype_attempt_status
    #FROM new_intermediate_report
    #where new_intermediate_report.production_centre = '#{production_centre}'
    #order by new_intermediate_report.gene
    #EOF

    sql = <<-EOF
    SELECT
    new_intermediate_report.gene AS marker_symbol,
    new_intermediate_report.mgi_accession_id AS mgi_accession_id,
    string_agg(new_intermediate_report.consortium, '|') AS consortium_name,
    string_agg(new_intermediate_report.production_centre, '|') AS centre_name,
    string_agg(new_intermediate_report.mi_plan_status, '|') AS mi_plan_status,
    string_agg(new_intermediate_report.overall_status, '|') AS overall_status,
    string_agg(new_intermediate_report.mi_attempt_status, '|') AS mi_attempt_status,
    string_agg(new_intermediate_report.phenotype_attempt_status, '|') AS phenotype_attempt_status
    FROM new_intermediate_report
    where new_intermediate_report.production_centre = '#{production_centre}'
    group by new_intermediate_report.gene, new_intermediate_report.mgi_accession_id
    order by new_intermediate_report.gene
    EOF

    sql

  end
end
