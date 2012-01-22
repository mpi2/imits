# encoding: utf-8

class Reports::MiProduction::SummaryKomp22

  extend Reports::MiProduction::SummariesCommon
  extend Reports::MiProduction::SummaryKomp2Common

  CSV_LINKS = Reports::MiProduction::SummaryKomp2Common::CSV_LINKS
  MAPPING_SUMMARIES = Reports::MiProduction::SummaryKomp2Common::MAPPING_SUMMARIES
  CONSORTIA = Reports::MiProduction::SummaryKomp2Common::CONSORTIA
  HEADINGS = Reports::MiProduction::SummaryKomp2Common::HEADINGS
  REPORT_TITLE = "KOMP2 Report''"

  def self.generate(request = nil, params={})

    if params[:consortium]
      title, report = subsummary_common(params)
      rv = request && request.format == :csv ? report.to_csv : report.to_html
      return title, rv
    end

    report = generate_common(request, params)
    
    months = 1
    month = get_month(months)
    report_title = REPORT_TITLE + " (#{month})"   # + " (#{months})"

    return report_title, report.to_html
  end

  def self.all(row)
#    raise "correct all"
    months = 1
    day = to_date(row.data['Overall Status'] + ' Date')
    first_day, last_day = get_first_and_last_days_of_month(months)
    return date_between(day, first_day, last_day)
  end

  def self.generic(row, key)
    return false if !MAPPING_SUMMARIES[key].include? row.data['Overall Status']
    return check_date(row, key)
  end
  
  def self.check_date(row, key)
    months = 1
    first_day, last_day = get_first_and_last_days_of_month(months)

    array = MAPPING_SUMMARIES[key]
    array.each do |item|
      day = to_date(row[item + ' Date'])
      return true if date_between(day, first_day, last_day)
    end

    return false
  end

  def self.get_first_and_last_days_of_month(month)
    first_day = Date.today << month
    first_day = Time.new(first_day.year,first_day.month,1).to_date
    last_day = (Date.today << month).end_of_month
    return first_day, last_day
  end
  
  def self.get_month(month)
    return "Unknown" if ! month || month < 0
    day = Date.today << month
    return Date::MONTHNAMES[day.month] 
  end

  def self.to_date(string)
    return nil if ! string || string.to_s.length < 1 || ! /-/.match(string)
    splits = string.to_s.split(/\-/)
    return nil if ! splits || splits.size < 3
    day = Time.new(splits[0],splits[1],splits[2])
    day = day ? day.to_date : nil
    return day
  end
  
  def self.date_between(target_date, start_date, end_date)
    return false if !target_date || !start_date || !end_date
    return target_date >= start_date && target_date <= end_date
  end

  def self.es_qc_started(row)
    return generic(row, 'ES QC started')
    #    return MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status']
  end
  
  def self.es_qc_confirmed(row)
    return generic(row, 'ES QC confirmed')
    #    return MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status']
  end
  
  def self.es_qc_failed(row)
    return generic(row, 'ES QC failed')
    #    return MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status']
  end

  def self.mi_in_progress(row)
    return generic(row, 'MI in progress')
    #    return MAPPING_SUMMARIES['MI in progress'].include? row.data['Overall Status']
  end

  def self.genotype_confirmed_mice(row)
    return generic(row, 'Genotype Confirmed Mice')
    #(MAPPING_SUMMARIES['Genotype Confirmed Mice'].include?(row.data['Overall Status'])) ||
    #  ((MAPPING_SUMMARIES['Registered for Phenotyping'].include? row.data['Overall Status']) &&
    #  (row.data['Genotype confirmed Date'] && row.data['Genotype confirmed Date'].to_s.length > 0))
  end
  
  def self.mi_aborted(row)
    return generic(row, 'MI Aborted')
    #    return MAPPING_SUMMARIES['MI Aborted'].include? row.data['Overall Status']
  end

  def self.registered_for_phenotyping(row)
    return generic(row, 'Registered for Phenotyping')
    #    row && row['PhenotypeAttempt Status'] && row['PhenotypeAttempt Status'].to_s.length > 1 || MAPPING_SUMMARIES['Registered for Phenotyping'].include?(row.data['Overall Status'])
  end
  
  def self.phenotyping_started(row)
    return generic(row, 'Phenotyping Started')
    #    return MAPPING_SUMMARIES['Phenotyping Started'].include? row.data['Overall Status']
  end
  
  def self.rederivation_started(row)
    return generic(row, 'Rederivation Started')
    #    return MAPPING_SUMMARIES['Rederivation Started'].include? row.data['Overall Status']
  end
  
  def self.rederivation_complete(row)
    return generic(row, 'Rederivation Complete')
    #    return MAPPING_SUMMARIES['Rederivation Complete'].include? row.data['Overall Status']
  end
  
  def self.cre_excision_started(row)
    return generic(row, 'Cre Excision Started')
    #    return MAPPING_SUMMARIES['Cre Excision Started'].include? row.data['Overall Status']
  end
  
  def self.cre_excision_complete(row)
    return generic(row, 'Cre Excision Complete')
    #    return MAPPING_SUMMARIES['Cre Excision Complete'].include? row.data['Overall Status']
  end

  def self.phenotyping_complete(row)
    return generic(row, 'Phenotyping Complete')
    #    return MAPPING_SUMMARIES['Phenotyping Complete'].include? row.data['Overall Status']
  end
  
  def self.phenotype_attempt_aborted(row)
    return generic(row, 'Phenotype Attempt Aborted')
    #    return MAPPING_SUMMARIES['Phenotype Attempt Aborted'].include? row.data['Overall Status']
  end
  
end
