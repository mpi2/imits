# encoding: utf-8

class Reports::MiProduction::LanguishingMgp < Reports::MiProduction::LanguishingBase

  def self.generate_detail(options = {})
    sub_project, status, delay_bin, priority = options.values_at(:sub_project, :status, :delay_bin, :priority)

    intermediate = ReportCache.find_by_name_and_format!('mi_production_intermediate', 'csv').to_table

    report = Ruport::Data::Table.new(
      :column_names => intermediate.column_names,
      :data => intermediate.data,
      :filters => lambda {
        |intermediate_record|
        if(sub_project)
          return false unless intermediate_record['Sub-Project'] == sub_project
        elsif(priority)
          return false unless intermediate_record['Priority'] == priority
        else
          raise "Must specify one of sub_project or priority as a parameter to this detail method"
        end
        return false unless intermediate_record['Overall Status'] == status
        status_name = intermediate_record['Overall Status'] + ' Date'
        status_date = intermediate_record.get(status_name)
        return delay_bin == get_delay_bin_for(intermediate_record.get(intermediate_record['Overall Status'] + ' Date'))
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

  def self.make_empty_report_grouping(grouping_field)

    report = Ruport::Data::Grouping.new

    if(grouping_field == 'Sub-Project')
      group_objects = MiPlan::SubProject.all
    elsif(grouping_field == 'Priority')
      group_objects = MiPlan::Priority.all
    else
      raise "have to specify a grouping field of Sub-Project or Priority"
    end

    names_to_exclude = {
      "" => 1,
      "WTSI_Blood_A" => 1,
      "Legacy EUCOMM" => 1,
      "Legacy KOMP" => 1,
      "Legacy with new Interest" => 1,
    }

    group_objects.each do |object|
      group_name = object.name
      next unless (names_to_exclude[group_name].nil?)
      group = Ruport::Data::Group.new(
        :name => group_name,
        :column_names => ['Best Status For Gene'] + DELAY_BINS
      )

      STATUSES.each do |status_name|
        group << [status_name] + Array.new(DELAY_BINS.size, 0)
      end

      report.append group
    end

    #some MGP plans have no subproject - add a 'None' group for these
    #if(grouping_field == 'Sub-Project')
    #  group = Ruport::Data::Group.new(
    #    :name => 'None',
    #    :column_names => ['Best Status For Gene'] + DELAY_BINS
    #  )
    #  STATUSES.each do |status_name|
    #    group << [status_name] + Array.new(DELAY_BINS.size, 0)
    #  end
    #  report.append group
    #end

    return report
  end

  def self.fill_in_report_with_intermediate_record_data(grouping_field, summary_report, intermediate)
    names_to_exclude = {
      "" => 1,
      "WTSI_Blood_A" => 1,
      "Legacy EUCOMM" => 1,
      "Legacy KOMP" => 1,
      "Legacy with new Interest" => 1,
    }

    intermediate.each do |intermediate_record|
      next unless intermediate_record['Consortium'] == 'MGP'
      grouping_value = intermediate_record[grouping_field]
      next unless names_to_exclude[grouping_value].nil?
      #sub_project_name = intermediate_record['Sub-Project']
      #sometimes the Sub-Project can be empty - replace with 'None'
      if((grouping_value.eql?nil) || (grouping_value.length == 0))
        grouping_value = 'None'
      end
      overall_status = intermediate_record['Overall Status']
      next unless STATUSES.include?(overall_status)
      overall_status_date = intermediate_record.get(overall_status + ' Date')

      group_for_row_in_report = summary_report[grouping_value]
      record = group_for_row_in_report.find {|i| i[0] == overall_status }

      record[get_delay_bin_for(overall_status_date)] += 1
    end
  end

  def self.generate(grouping_field)

    intermediate = ReportCache.find_by_name_and_format!('mi_production_intermediate', 'csv').to_table

    report = make_empty_report_grouping(grouping_field)

    fill_in_report_with_intermediate_record_data(grouping_field, report, intermediate)

    #report.each do |name, group|
    #  {
    #    'Micro-injection in progress' => 'Mouse production attempt',
    #    'Phenotype Attempt Registered' => 'Intent to phenotype'
    #  }.each do |from, to|
    #    row = group.find {|r| r[0] == from}
    #    row[0] = to
    #  end
    #end

    return report
  end

end
