class Reports::MiProduction::Detail

  # TODO: unit-test it, share it somewhere for all reports, expand it so it
  # handles deeply nested associations
  def self.generate_report_options(report_columns)
    report_options = {
      :only => [],
      :include => {}
    }

    report_columns.each do |column_spec, column_header|
      report_options[:only] << column_spec
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
      'production_centre.name' => 'Production Centre',
      'gene.marker_symbol' => 'Gene'
    }

    report_options = generate_report_options(report_columns)
    report_options[:methods] = ['latest_status_stamps_with_dates']

    transform = proc { |record|
      status_stamps = record['latest_status_stamps_with_dates']
      status_stamps.each do |name, date|
        record["#{name} Date"] = date.to_s
      end
    }
    report_options[:transforms] = [transform]

    report = MiPlan.report_table(:all, report_options)
    report.rename_columns(report_columns)
    report.reorder(report_columns.values + [
        'Assigned Date',
        'Assigned - ES Cell QC Complete Date'
      ]
    )

    return report
  end
end
