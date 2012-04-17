# encoding: utf-8

class Reports::MiProduction::Languishing < Reports::MiProduction::LanguishingBase

  def self.generate_detail(options = {})
    consortium, status, delay_bin = options.values_at(:consortium, :status, :delay_bin)

    intermediate = ReportCache.find_by_name_and_format!('mi_production_intermediate', 'csv').to_table

    report = Ruport::Data::Table.new(
      :column_names => intermediate.column_names,
      :data => intermediate.data,
      :filters => lambda { |intermediate_record|
        return false unless intermediate_record['Consortium'] == consortium &&
                intermediate_record['Overall Status'] == status
        overall_status_date = intermediate_record.get(intermediate_record['Overall Status'] + ' Date')

        return(delay_bin == get_delay_bin_for(overall_status_date))
      }
    )

    [
      "MiPlan Status",
      "MiAttempt Status",
      "PhenotypeAttempt Status"
    ].each do |name|
      report.remove_column name
    end

    report.rename_column 'Overall Status', 'Status'
    report.rename_column 'Mutation Sub-Type', 'Mutation Type'

    return report
  end

  def self.generate(options = {})
    intermediate = ReportCache.find_by_name_and_format!('mi_production_intermediate', 'csv').to_table

    if options[:consortia].blank?
      consortia = Consortium.all.map(&:name)
    else
      consortia = options[:consortia].split(',')
    end

    report = Ruport::Data::Grouping.new

    consortia.each do |consortium_name|
      group = Ruport::Data::Group.new(
        :name => consortium_name,
        :column_names => ['Best Status For Gene'] + DELAY_BINS
      )

      STATUSES.each do |status_name|
        group << [status_name] + Array.new(DELAY_BINS.size, 0)
      end

      report.append group
    end

    intermediate.each do |intermediate_record|
      next unless consortia.include?(intermediate_record['Consortium'])
      overall_status = intermediate_record['Overall Status']
      next unless STATUSES.include?(overall_status)
      overall_status_date = intermediate_record.get(overall_status + ' Date')

      consortium_group = report[intermediate_record['Consortium']]
      record = consortium_group.find {|i| i[0] == overall_status }

      record[get_delay_bin_for(overall_status_date)] += 1
    end

    return report
  end

end
