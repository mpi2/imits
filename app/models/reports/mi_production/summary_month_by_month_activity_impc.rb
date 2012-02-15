# encoding: utf-8

class Reports::MiProduction::SummaryMonthByMonthActivityImpc < Reports::Base

  DEBUG = false
  CSV_BLANKS = false
  CUT_OFF_DATE = Date.parse('2011-08-01')
  RAILS_CACHE = true

  HEADINGS = [
    'Year',
    'Month',
    'Consortium',

    'ES Cell QC In Progress',
    'ES Cell QC Complete',
    'ES Cell QC Failed',

    'Production Centre',

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
  ]

  def self.generate(params = {})

    if params[:consortium]
      title, table = subsummary(params)
      return { :csv => table.to_csv, :html => table.to_html, :title => title, :table => table }
    end

    summary = get_summary(params)

    html_string = convert_to_html(params, summary)

    table = convert_to_csv(params, summary)

    return { :csv => table.to_csv, :html => html_string, :table => table }
  end

  def self.subsummary(params)

    year = params[:year]
    month = params[:month]
    consortium = params[:consortium]
    type = params[:type]
    pcentre = params[:pcentre]

    summary = get_summary(params)

    table = Table(["Date", "Marker Symbol", "Consortium", "Centre", "Status"])

    if ! pcentre
      summary[year.to_i][month.to_i][consortium].keys.each do |centre|
        types = summary[year.to_i][month.to_i][consortium][centre]
        types[type].keys.each do |gene|
          plan_id = types[type][gene][:plan_id]
          plan = MiPlan.find(plan_id)
          status_details = plan.latest_relevant_status
          table << {
            "Date" => status_details[:date].to_date,
            "Consortium" => consortium,
            "Centre" => centre,
            "Marker Symbol" => types[type][gene][:symbol],
            "Status" => status_details[:status]
          }
        end
      end
    else
      summary[year.to_i][month.to_i][consortium][pcentre][type].keys.each do |gene|
        plan_id = summary[year.to_i][month.to_i][consortium][pcentre][type][gene][:plan_id]
        plan = MiPlan.find(plan_id)
        status_details = plan.latest_relevant_status
        table << {
          "Date" => status_details[:date].to_date,
          "Consortium" => consortium,
          "Centre" => pcentre,
          "Marker Symbol" => summary[year.to_i][month.to_i][consortium][pcentre][type][gene][:symbol],
          "Status" => status_details[:status]
        }
      end
    end

    table.sort_rows_by!("Date", :order => :descending)

    title = 'Details'
    size = table && table.data && table.data.size ? table.data.size : 0
    title += " - YEAR: #{year} - MONTH: #{month} - CONSORTIUM: #{consortium} - CENTRE: #{pcentre} - TYPE: #{type} (#{size})" if DEBUG

    return title, table
  end

  def self.get_summary(params)
    return get_summary_proper(params) if ! RAILS_CACHE
    Rails.cache.fetch(self.report_name, :expires_in => 1.hour) do
      get_summary_proper(params)
    end
  end

  # we need this (or something better) because we can't dump Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
  # when using the rails cache
  # see http://stackoverflow.com/questions/3818623/marshal-ruby-hash-with-default-proc-remove-the-default-proc
  # for example

  def self.prepare_summary(summary)
    s = {}
    summary.keys.each do |year|
      s[year] ||= {}
      month_hash = summary[year]
      month_hash.keys.each do |month|
        s[year][month] ||= {}
        cons_hash = month_hash[month]
        cons_hash.keys.each do |cons|
          s[year][month][cons] ||= {}
          centre_hash = cons_hash[cons]
          centre_hash.keys.each do |centre|
            s[year][month][cons][centre] ||= {}
            status_hash = centre_hash[centre]
            status_hash.keys.each do |status|
              s[year][month][cons][centre][status] ||= {}
              genes_hash = status_hash[status]
              genes_hash.keys.each do |gene|
                s[year][month][cons][centre][status][gene] ||= genes_hash[gene]
              end
            end

          end
        end
      end
    end
    return s
   end

  def self.get_summary_proper(params)

    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }

    plan_map = Hash.new { |hash,key| raise("plan_map: No value defined for key: #{ key }") }
    MiPlan::Status.all.each { |i| plan_map[i.name.downcase.parameterize.underscore.to_sym] = i.name }

    attempt_map = Hash.new { |hash,key| raise("attempt_map: No value defined for key: #{ key }") }
    MiAttemptStatus.all.each { |i| attempt_map[i.description.downcase.parameterize.underscore.to_sym] = i.description }

    phenotype_map = Hash.new { |hash,key| raise("phenotype_map: No value defined for key: #{ key }") }
    PhenotypeAttempt::Status.all.each { |i| phenotype_map[i.name.downcase.parameterize.underscore.to_sym] = i.name }

    MiPlan::StatusStamp.all.each do |stamp|

      next if stamp.created_at < CUT_OFF_DATE

      year = stamp.created_at.year
      month = stamp.created_at.month
      day = stamp.created_at.day
      consortium = stamp.mi_plan.consortium.name
      pcentre = stamp.mi_plan.production_centre && stamp.mi_plan.production_centre.name ? stamp.mi_plan.production_centre.name : 'UNKNOWN'
      pcentre = 'UNKNOWN' if pcentre.blank? || pcentre.to_s.length < 1
      next if pcentre == 'UNKNOWN'
      next if self.consortia && ! self.consortia.include?(consortium)
      gene_id = stamp.mi_plan.gene_id
      status = stamp.status.name
      marker_symbol = stamp.mi_plan.gene.marker_symbol

      details_hash = { :symbol => marker_symbol, :plan_id => stamp.mi_plan.id, :original_status => status, :original_date => stamp.created_at }

      self.consortia.each do |name|
        summary[year][month][name]['DUMMY']['ES Cell QC In Progress'] ||= {}
        summary[year][month][name]['DUMMY']['ES Cell QC Complete'] ||= {}
        summary[year][month][name]['DUMMY']['ES Cell QC Failed'] ||= {}
      end

      if status == plan_map[:assigned_es_cell_qc_in_progress]
        summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
      end

      if status == plan_map[:assigned_es_cell_qc_complete]
        summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
        summary[year][month][consortium][pcentre]['ES Cell QC Complete'][gene_id] = details_hash
      end

      if status == plan_map[:aborted_es_cell_qc_failed]
        summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
        summary[year][month][consortium][pcentre]['ES Cell QC Failed'][gene_id] = details_hash
      end

    end

    MiAttempt::StatusStamp.all.each do |stamp|

      next if stamp.created_at < CUT_OFF_DATE

      year = stamp.created_at.year
      month = stamp.created_at.month
      day = stamp.created_at.day
      consortium = stamp.mi_attempt.mi_plan.consortium.name
      pcentre = stamp.mi_attempt.production_centre_name
      pcentre = 'UNKNOWN' if pcentre.blank? || pcentre.to_s.length < 1
      next if pcentre == 'UNKNOWN'
      next if self.consortia && ! self.consortia.include?(consortium)
      gene_id = stamp.mi_attempt.mi_plan.gene_id
      status = stamp.mi_attempt_status.description
      marker_symbol = stamp.mi_attempt.mi_plan.gene.marker_symbol

      details_hash = { :symbol => marker_symbol, :plan_id => stamp.mi_attempt.mi_plan.id, :original_status => status, :original_date => stamp.created_at }

      self.consortia.each do |name|
        summary[year][month][name]['DUMMY']['Micro-injection in progress'] ||= {}
        summary[year][month][name]['DUMMY']['Genotype confirmed'] ||= {}
        summary[year][month][name]['DUMMY']['Micro-injection aborted'] ||= {}
      end

      if(status == attempt_map[:micro_injection_in_progress])
        summary[year][month][consortium][pcentre]['Micro-injection in progress'][gene_id] = details_hash
      end

      if(status == attempt_map[:genotype_confirmed])
        summary[year][month][consortium][pcentre]['Micro-injection in progress'][gene_id] = details_hash
        summary[year][month][consortium][pcentre]['Genotype confirmed'][gene_id] = details_hash
      end

      if(status == attempt_map[:micro_injection_aborted])
        summary[year][month][consortium][pcentre]['Micro-injection in progress'][gene_id] = details_hash
        summary[year][month][consortium][pcentre]['Micro-injection aborted'][gene_id] = details_hash
      end

    end

    PhenotypeAttempt::StatusStamp.all.each do |stamp|

      next if stamp.created_at < CUT_OFF_DATE

      year = stamp.created_at.year
      month = stamp.created_at.month
      day = stamp.created_at.day

      consortium = stamp.phenotype_attempt.mi_plan.consortium.name

      pcentre = stamp.phenotype_attempt.mi_plan.production_centre && stamp.phenotype_attempt.mi_plan.production_centre.name ?
        stamp.phenotype_attempt.mi_plan.production_centre.name : ''

      pcentre = 'UNKNOWN' if pcentre.blank?
      next if pcentre == 'UNKNOWN'
      next if self.consortia && ! self.consortia.include?(consortium)
      gene_id = stamp.phenotype_attempt.mi_plan.gene_id
      status = stamp.phenotype_attempt.status.name
      marker_symbol = stamp.phenotype_attempt.mi_plan.gene.marker_symbol

      details_hash = { :symbol => marker_symbol, :plan_id => stamp.phenotype_attempt.mi_plan.id, :original_status => status, :original_date => stamp.created_at }

      self.consortia.each do |name|
        summary[year][month][name]['DUMMY']['Phenotype Attempt Aborted'] ||= {}
      end

      if status == phenotype_map[:phenotype_attempt_aborted]
        summary[year][month][consortium][pcentre]['Phenotype Attempt Aborted'][gene_id] = details_hash
      end

      if status == phenotype_map[:phenotyping_complete]
        summary[year][month][consortium][pcentre]['Phenotyping Complete'][gene_id] = details_hash
      end

      phenotyping_started = [ phenotype_map[:phenotyping_started], phenotype_map[:phenotyping_complete] ]

      if phenotyping_started.include?(status)
        summary[year][month][consortium][pcentre]['Phenotyping Started'][gene_id] = details_hash
      end

      cre_excision_complete = phenotyping_started + [ phenotype_map[:cre_excision_complete] ]

      if cre_excision_complete.include?(status)
        summary[year][month][consortium][pcentre]['Cre Excision Complete'][gene_id] = details_hash
      end

      cre_excision_started = cre_excision_complete + [ phenotype_map[:cre_excision_started] ]

      if cre_excision_started.include?(status)
        summary[year][month][consortium][pcentre]['Cre Excision Started'][gene_id] = details_hash
      end

      rederivation_started = cre_excision_started + [ phenotype_map[:rederivation_started] ]

      if rederivation_started.include?(status)
        summary[year][month][consortium][pcentre]['Rederivation Started'][gene_id] = details_hash
        #TODO: check
      end

      rederivation_complete = rederivation_started + [ phenotype_map[:rederivation_complete] ]

      if rederivation_complete.include?(status)
        summary[year][month][consortium][pcentre]['Rederivation Complete'][gene_id] = details_hash
        #TODO: check
      end

      phenotype_attempt_registered = rederivation_complete + [ phenotype_map[:phenotype_attempt_registered] ]

      if phenotype_attempt_registered.include?(status)
        summary[year][month][consortium][pcentre]['Phenotype Attempt Registered'][gene_id] = details_hash
      end

    end

    return RAILS_CACHE ? prepare_summary(summary) : summary
  end

  def self.convert_to_html(params, summary)
    string = '<table>'
    string += '<tr>'

    script_name = params[:script_name]

    make_clean = lambda do |value|
      return value if params[:format] == :csv && ! CSV_BLANKS
      return '' if value.to_s.length < 1
      return '' if value.to_i == 0
      return value
    end

    HEADINGS.each { |name| string += "<th>#{name}</th>" }

    summary.keys.sort.reverse!.each do |year|

      string += '</tr>'
      year_count = 0
      string += '<tr>'
      string += "<td class='report-cell-integer' rowspan='YEAR_ROWSPAN'>#{year}</td>"
      month_hash = summary[year]
      month_hash.keys.sort.reverse!.each do |month|
        string += "<td class='report-cell-text' rowspan='MONTH_ROWSPAN'>#{Date::MONTHNAMES[month]}</td>"

        month_count = 0
        cons_hash = month_hash[month]

        cons_hash.keys.sort.each do |cons|
          centre_hash = cons_hash[cons]
          string += "<td class='report-cell-text' rowspan='CONS_ROWSPAN'>#{cons}</td>"

          make_link = lambda do |key, value|
            return value if params[:format] == :csv
            return '' if value.to_s.length < 1
            return '' if value.to_i == 0
            consort = CGI.escape cons
            type = CGI.escape key.to_s
            separator = /\?/.match(script_name) ? '&' : '?'
            return "<a href='#{script_name}#{separator}year=#{year}&month=#{month}&consortium=#{consort}&type=#{type}'>#{value}</a>"
          end

          summer = {'ES Cell QC In Progress'=> 0, 'ES Cell QC Complete' => 0, 'ES Cell QC Failed' => 0}
          array2 = [ 'ES Cell QC In Progress', 'ES Cell QC Complete', 'ES Cell QC Failed' ]
          centre_hash.keys.each do |centre|
            status_hash = centre_hash[centre]
            array2.each do |name|
              next if ! status_hash[name]
              status_hash[name].each do |gene|
                summer[name] += 1
              end
            end
          end

          array2.each { |name| string += "<td class='report-cell-integer' rowspan='CONS_ROWSPAN'>#{make_link.call(name, summer[name])}</td>" }

          centre_count = 0

          centre_hash.keys.each do |centre|

            next if centre == 'DUMMY' && centre_hash.keys.size > 1

            centre_count += 1

            make_link = lambda do |key, frame|
              return 0 if ! frame[key] && params[:format] == :csv
              return frame[key].keys.size if params[:format] == :csv
              return '' if ! frame[key]
              return '' if frame[key].keys.size.to_s.length < 1
              return '' if frame[key].keys.size.to_i == 0

              consort = CGI.escape cons
              pcentre = CGI.escape centre
              type = CGI.escape key.to_s
              separator = /\?/.match(script_name) ? '&' : '?'
              return "<a href='#{script_name}#{separator}year=#{year}&month=#{month}&consortium=#{consort}&pcentre=#{pcentre}&type=#{type}'>#{frame[key].keys.size}</a>"
            end

            status_hash = centre_hash[centre]

            array = [
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
            ]

            c = centre == 'DUMMY' ? '' : centre

            string += "<td class='report-cell-text'>#{c}</td>"

            array.each { |name| string += "<td class='report-cell-integer'>#{make_link.call(name, status_hash)}</td>" }

            string += '</tr>' # this sometimes inserts empty rows
            string += '<tr>'

            year_count += 1
            month_count += 1

          end
          string = string.gsub(/CONS_ROWSPAN/, centre_count.to_s)
        end
        string = string.gsub(/MONTH_ROWSPAN/, month_count.to_s)
      end
      string = string.gsub(/YEAR_ROWSPAN/, year_count.to_s)
    end
    string += '</table>'

    string = string.gsub(/\<tr\>\<\/tr\>/, '')

    return string
  end

  def self.convert_to_csv(params, summary)

    column_names = [
      'ES Cell QC In Progress',
      'ES Cell QC Complete',
      'ES Cell QC Failed',
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
    ]

    report_table = Table(HEADINGS)

    summary.keys.sort.reverse!.each do |year|
      month_hash = summary[year]
      month_hash.keys.sort.reverse!.each do |month|
        cons_hash = month_hash[month]
        cons_hash.keys.sort.each do |cons|
          centre_hash = cons_hash[cons]
          centre_hash.keys.each do |centre|
            status_hash = centre_hash[centre]

            next if centre == 'DUMMY' && centre_hash.keys.size > 1

            c = centre == 'DUMMY' ? '' : centre

            hash = {
              'Year' => year,
              'Month' => month,
              'Consortium' => cons,
              'Production Centre' => c
            }

            column_names.each do |name|
              hash[name] = status_hash[name] ? status_hash[name].keys.size : 0
            end

            report_table << hash

          end
        end
      end
    end

    return report_table
  end

  def self.report_name; 'summary_month_by_month_activity_impc'; end

  def initialize
    generated = self.class.generate
    @csv = generated[:csv]
    @html = generated[:html]
  end

  def to(format)
    if format == 'html'
      return @html
    elsif format == 'csv'
      return @csv
    end
  end

  def self.report_title; 'IMPC Summary Month by Month'; end
  def self.consortia; Consortium.all.map(&:name); end

end
