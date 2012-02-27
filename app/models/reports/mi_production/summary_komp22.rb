# encoding: utf-8

#TODO: delete *komp2_brief.*
#TODO: delete *komp212.*
#TODO: remove summary_komp2_brief metjod in controller

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
    report_title = REPORT_TITLE + " (#{month})"

    report.remove_columns('Pipeline efficiency (%)', 'Pipeline efficiency (by clone)')
    report.rename_column('All', 'All Genes')

    return report_title, request && request.format == :csv ? report.to_csv : report.to_html
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

  def self.process_row(row, key)

   # raise "correct process_row!"

    keys2 = [
      'Phenotype Attempt Aborted',
      'ES QC started',
      'ES QC confirmed',
      'ES QC failed',
      'MI in progress',
      'MI Aborted',
      'Phenotyping Started',
      'Rederivation Started',
      'Rederivation Complete',
      'Cre Excision Started',
      'Cre Excision Complete',
      'Phenotyping Complete',
      'Phenotype Attempt Aborted',
      'Genotype Confirmed Mice',
      'Registered for Phenotyping'
    ]

    return generic(row, key) if keys2.include? key

    #TODO: this isn't working

    if key == 'All'

      #TODO: fix me!

      return false if ['Assigned', 'Inspect - MI Attempt'].include? row.data['Overall Status']

      months = 1

      day = to_date(row[row.data['Overall Status'] + ' Date'])
      first_day, last_day = get_first_and_last_days_of_month(months)
      return date_between(day, first_day, last_day)
    end

    raise "process_row: invalid key detected '#{key}'"
  end

end
