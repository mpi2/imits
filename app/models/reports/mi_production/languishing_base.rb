class Reports::MiProduction::LanguishingBase

  STATUSES = [
    'Assigned',
    'Assigned - ES Cell QC In Progress',
    'Assigned - ES Cell QC Complete',
    'Micro-injection in progress',
    'Chimeras obtained',
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

end
