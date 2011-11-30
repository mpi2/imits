class Reports::MiProduction::Detail

  # TODO: unit-test it, share it somewhere for all reports, expand it so it
  # handles deeply nested associations
  def self.generate_report_options(report_columns)
    report_options = {
      :only => [],
      :include => {}
    }

    report_columns.each do |column_spec, column_header|
      report_options[:only].push column_spec
      if(column_spec.include? '.')
        association, attribute = column_spec.split('.').map(&:to_sym)
        report_options[:include][association] ||= {:only => []}
        report_options[:include][association][:only].push attribute
      end
    end

    return report_options
  end

  def self.generate
    report_columns = {
      'consortium.name' => 'Consortium',
      'sub_project.name' => 'Sub-Project',
      'production_centre.name' => 'Production Centre',
      'gene.marker_symbol' => 'Gene'
    }

    report_options = generate_report_options(report_columns)
    report_options[:methods] = ['status_stamps_with_latest_dates']
    report_options[:include][:latest_relevant_mi_attempt] = {
      :methods => [:status_stamps_with_latest_dates],
      :only => []
    }

    transform = proc { |record|
      plan_status_stamps = record['status_stamps_with_latest_dates']
      plan_status_stamps.each do |name, date|
        record["#{name} Date"] = date.to_s
      end

      mi_status_stamps = record['latest_relevant_mi_attempt.status_stamps_with_latest_dates'] || []
      mi_status_stamps.each do |description, date|
        record["#{description} Date"] = date.to_s
      end
    }
    report_options[:transforms] = [transform]

    report = MiPlan.report_table(:all, report_options)
    report.rename_columns(report_columns)
    report.reorder(report_columns.values + [
        'Assigned Date',
        'Assigned - ES Cell QC Complete Date',
        'Micro-injection in progress Date',
        'Genotype confirmed Date',
        'Micro-injection aborted Date'
      ]
    )

    return report
  end
end
