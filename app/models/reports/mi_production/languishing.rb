# encoding: utf-8

class Reports::MiProduction::Languishing
  STATUSES = [
    'Assigned',
    'Assigned - ES Cell QC In Progress',
    'Assigned - ES Cell QC Complete',
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
    today = Date.today
    return ((today - date).to_i / 30)
  end

  def self.generate
    intermediate = ReportCache.find_by_name!('mi_production_intermediate').to_table

    data = {}

    STATUSES.each { |status| data[status] = DELAY_BINS_TEMPLATE.dup }

    report = Ruport::Data::Table.new(
      :column_names => [
        'Best Status For Gene',
        *DELAY_BINS_TEMPLATE.keys
      ]
    )

    intermediate.each do |record|
      overall_status = record.get('Overall Status')
      next unless STATUSES.include?(overall_status)
      overall_status_date = record.get(overall_status + ' Date')

      bin = data[overall_status]

      begin
        overall_status_date = Date.parse(overall_status_date)
      rescue => e
        raise e.class.new(e.message + ' "' + overall_status_date + '"')
      end

      case latency_in_months(overall_status_date)
      when 0         then bin['0 months'] += 1
      when 1         then bin['1 month'] += 1
      when 2         then bin['2 months'] += 1
      when 3         then bin['3 months'] += 1
      when 4, 5, 6   then bin['4-6 months'] += 1
      when 7, 8, 9   then bin['7-9 months'] += 1
      else                bin['> 9 months'] += 1
      end
    end

    data.each do |status, bin|
      report << [status, *bin.values]
    end

    return report
  end
end
