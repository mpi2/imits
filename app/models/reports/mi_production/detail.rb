class Reports::MiProduction::Detail

  # TODO: unit-test it, share it somewhere for all reports, expand it so it
  # handles deeply nested associations
  def self.generate_report_options(report_columns)
    report_options = {
      :only => [],
      :include => {}
    }

    report_columns.each do |column_spec, column_header|
      if(column_spec.include? '.')
        association, attribute = column_spec.split('.').map(&:to_sym)
        report_options[:include][association] ||= {:only => []}
        report_options[:include][association][:only].push attribute
      else
        report_options[:only] << column_spec
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

    report = MiPlan.report_table(:all, report_options)
    report.rename_columns(report_columns)

    return report
  end
end
