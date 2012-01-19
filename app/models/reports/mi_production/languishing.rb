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

  DELAY_BINS_TEMPLATE = {
    '0 months' => 0,
    '1 month' => 0,
    '2 months' => 0,
    '3 months' => 0,
    '4-6 months' => 0,
    '7-9 months' => 0,
    '> 9 months' => 0
  }.freeze

  def self.latency_in_months(date)
    date = Date.parse(date) unless date.kind_of?(Date)
    today = Date.today
    return ((today - date).to_i / 30)
  end

  def self.generate(params = {})
    intermediate = ReportCache.find_by_name!('mi_production_intermediate').to_table

    if params[:consortia].blank?
      consortia = Consortium.all.map(&:name)
    else
      consortia = params[:consortia].split(',')
    end

    report = Ruport::Data::Grouping.new

    consortia.each do |consortium_name|
      group = Ruport::Data::Group.new(
        :name => consortium_name,
        :column_names => ['Best Status For Gene'] + DELAY_BINS_TEMPLATE.keys
      )

      STATUSES.each do |status_name|
        group << [status_name] + Array.new(DELAY_BINS_TEMPLATE.keys.size, 0)
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

      case latency_in_months(overall_status_date)
      when 0         then record['0 months']   += 1
      when 1         then record['1 month']    += 1
      when 2         then record['2 months']   += 1
      when 3         then record['3 months']   += 1
      when 4, 5, 6   then record['4-6 months'] += 1
      when 7, 8, 9   then record['7-9 months'] += 1
      else                record['> 9 months'] += 1
      end
    end

    return report
  end

end
