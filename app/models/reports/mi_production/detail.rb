# encoding: utf-8

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
      'priority.name' => 'Priority',
      'production_centre.name' => 'Production Centre',
      'gene.marker_symbol' => 'Gene'
    }

    report_options = generate_report_options(report_columns)
    report_options[:methods] = [
      'reportable_statuses_with_latest_dates',
      'latest_relevant_mi_attempt',
      'status_name'
    ]

    transform = proc { |record|
      mi_attempt = record['latest_relevant_mi_attempt']

      plan_status_dates = record['reportable_statuses_with_latest_dates']
      plan_status_dates.each do |name, date|
        record["#{name} Date"] = date.to_s
      end

      if mi_attempt
        record['status_name'] = mi_attempt.status

        mi_status_dates = mi_attempt.reportable_statuses_with_latest_dates
        mi_status_dates.each do |description, date|
          record["#{description} Date"] = date.to_s
        end

        phenotype_attempt = mi_attempt.latest_relevant_phenotype_attempt
        if phenotype_attempt
          record['status_name'] = phenotype_attempt.status.name

          pt_status_names = phenotype_attempt.reportable_statuses_with_latest_dates
          pt_status_names.each do |name, date|
            record["#{name} Date"] = date.to_s
          end
        end
      end
    }
    report_options[:transforms] = [transform]

    report = MiPlan.report_table(:all, report_options)
    report.rename_columns(report_columns.merge('status_name' => 'Status'))
    column_names = report_columns.values + [
      'Status',
      'Assigned Date',
      'Assigned - ES Cell QC In Progress Date',
      'Assigned - ES Cell QC Complete Date',
      'Micro-injection in progress Date',
      'Genotype confirmed Date',
      'Micro-injection aborted Date',
      'Phenotype Attempt Registered Date',
      'Rederivation Started Date',
      'Rederivation Complete Date',
      'Cre Excision Started Date',
      'Cre Excision Complete Date',
      'Phenotyping Started Date',
      'Phenotyping Complete Date',
      'Phenotype Attempt Aborted Date'
    ]
    report.reorder(column_names)

    report.data.each do |record|
      record.attributes.each do |attr|
        if record[attr] == nil
          record[attr] = ''
        end
      end
    end

    report = report.sort_rows_by(column_names)
    return report
  end

  def self.generate_and_cache
    cache = ReportCache.find_by_name('mi_production_detail')
    if cache
      cache.csv_data = self.generate.to_csv
      cache.save!
    else
      ReportCache.create!(
        :name => 'mi_production_detail',
        :csv_data => self.generate.to_csv
      )
    end
  end
end
