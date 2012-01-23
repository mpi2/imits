# encoding: utf-8

class Reports::MiProduction::Languishing
  STATUSES = [
    'Assigned',
    'Assigned - ES Cell QC In Progress',
    'Assigned - ES Cell QC Complete',
    'Micro-injection in progress',
    'Genotype confirmed',
    'Micro-injection aborted',
    'Phenotype Attempt Registered',
    'Rederivation Started',
    'Rederivation Complete',
    'Cre Excision Started',
    'Cre Excision Complete',
    'Phenotyping Started',
    'Phenotyping Complete',
    'Phenotype Attempt Aborted'
  ].freeze

  DELAY_BINS = [
    '0 months',
    '1 month',
    '2 months',
    '3 months',
    '4-6 months',
    '7-9 months',
    '> 9 months'
  ].freeze

  def self.latency_in_months(date)
    date = Date.parse(date) unless date.kind_of?(Date)
    today = Date.today
    return ((today - date).to_i / 30)
  end

  def self.get_delay_bin_for(date)
    case latency_in_months(date)
    when 0         then return '0 months'
    when 1         then return '1 month'
    when 2         then return '2 months'
    when 3         then return '3 months'
    when 4, 5, 6   then return '4-6 months'
    when 7, 8, 9   then return '7-9 months'
    else                return '> 9 months'
    end
  end

  def self.generate_detail(options = {})
    consortium, status, delay_bin = options.values_at(:consortium, :status, :delay_bin)

    intermediate = ReportCache.find_by_name!('mi_production_intermediate').to_table

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
    intermediate = ReportCache.find_by_name!('mi_production_intermediate').to_table

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
