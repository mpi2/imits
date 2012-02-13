# encoding: utf-8

# TODO: check CSV

class Reports::MiProduction::SummaryMonthByMonthActivity

  DEBUG = false
  RAILS_CACHE = false
  CSV_BLANKS = false
  CUT_OFF_DATE = Date.parse('2011-08-01')

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
      return { :csv => table.to_csv, :html => table.to_html, :title => title,
        :table => table # for test
      }
    end

    summary = get_summary(params)

    html_string = convert_to_html(params, summary)

    table = convert_to_csv(params, summary)

    title = params[:komp2] ? 'KOMP2 Summary Month by Month' : 'All Consortia Summary Month by Month'

    return { :csv => table.to_csv, :html => html_string, :title => title,
      :table => table # for test
    }
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
            "Marker Symbol" => status_details[:symbol],
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
          "Marker Symbol" => status_details[:symbol],
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
    return get_summary_proper(params) if params[:no_cache] || ! RAILS_CACHE
    Rails.cache.fetch('SummaryMonthByMonthActivity' + (params[:komp2] ? '-komp2' : '-impc'), :expires_in => 1.hour) do
      get_summary_proper(params)
    end
  end

  def self.get_summary_proper(params)

    summary = {}

    plan_map = Hash.new { |hash,key| raise("plan_map: No value defined for key: #{ key }") }
    MiPlan::Status.all.each { |i| plan_map[i.name.downcase.parameterize.underscore.to_sym] = i.name }

    attempt_map = Hash.new { |hash,key| raise("attempt_map: No value defined for key: #{ key }") }
    MiAttemptStatus.all.each { |i| attempt_map[i.description.downcase.parameterize.underscore.to_sym] = i.description }

    phenotype_map = Hash.new { |hash,key| raise("phenotype_map: No value defined for key: #{ key }") }
    PhenotypeAttempt::Status.all.each { |i| phenotype_map[i.name.downcase.parameterize.underscore.to_sym] = i.name }

    consortia = params && params[:komp2] ? ['BaSH', 'DTCC', 'JAX'] : nil

    MiPlan::StatusStamp.all.each do |stamp|

      next if consortia && stamp.created_at < CUT_OFF_DATE

      year = stamp.created_at.year
      month = stamp.created_at.month
      day = stamp.created_at.day
      consortium = stamp.mi_plan.consortium.name
      pcentre = stamp.mi_plan.production_centre && stamp.mi_plan.production_centre.name ? stamp.mi_plan.production_centre.name : 'UNKNOWN'
      pcentre = 'UNKNOWN' if pcentre.blank? || pcentre.to_s.length < 1
      next if pcentre == 'UNKNOWN'
      next if consortia && ! consortia.include?(consortium)
      gene_id = stamp.mi_plan.gene_id
      status = stamp.status.name
      marker_symbol = stamp.mi_plan.gene.marker_symbol

      #status_details = stamp.mi_plan.latest_relevant_status

      details_hash = { :symbol => marker_symbol, #:status => status_details[:status], :date => status_details[:date],
        :plan_id => stamp.mi_plan.id }

      summary[year] ||= {}
      summary[year][month] ||= {}
      summary[year][month][consortium] ||= {}
      summary[year][month][consortium][pcentre] ||= {}
      summary[year][month][consortium][pcentre]['ES Cell QC In Progress'] ||= {}
      summary[year][month][consortium][pcentre]['ES Cell QC Complete'] ||= {}
      summary[year][month][consortium][pcentre]['ES Cell QC Failed'] ||= {}

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

      next if consortia && stamp.created_at < CUT_OFF_DATE

      year = stamp.created_at.year
      month = stamp.created_at.month
      day = stamp.created_at.day
      consortium = stamp.mi_attempt.mi_plan.consortium.name
      pcentre = stamp.mi_attempt.production_centre_name
      pcentre = 'UNKNOWN' if pcentre.blank? || pcentre.to_s.length < 1
      next if pcentre == 'UNKNOWN'
      next if consortia && ! consortia.include?(consortium)
      gene_id = stamp.mi_attempt.mi_plan.gene_id
      status = stamp.mi_attempt_status.description
      marker_symbol = stamp.mi_attempt.mi_plan.gene.marker_symbol

    #  status_details = stamp.mi_attempt.mi_plan.latest_relevant_status

      details_hash = { :symbol => marker_symbol, #:status => status_details[:status], :date => status_details[:date],
        :plan_id => stamp.mi_attempt.mi_plan.id }

      summary[year] ||= {}
      summary[year][month] ||= {}
      summary[year][month][consortium] ||= {}
      summary[year][month][consortium][pcentre] ||= {}
      summary[year][month][consortium][pcentre]['Micro-injection in progress'] ||= {}
      summary[year][month][consortium][pcentre]['Genotype confirmed'] ||= {}
      summary[year][month][consortium][pcentre]['Micro-injection aborted'] ||= {}

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

      next if consortia && stamp.created_at < CUT_OFF_DATE

      year = stamp.created_at.year
      month = stamp.created_at.month
      day = stamp.created_at.day

      consortium = stamp.phenotype_attempt.mi_plan.consortium.name

      pcentre = stamp.phenotype_attempt.mi_plan.production_centre && stamp.phenotype_attempt.mi_plan.production_centre.name ?
        stamp.phenotype_attempt.mi_plan.production_centre.name : ''

      pcentre = 'UNKNOWN' if pcentre.blank?
      next if pcentre == 'UNKNOWN'
      next if consortia && ! consortia.include?(consortium)
      gene_id = stamp.phenotype_attempt.mi_plan.gene_id
      status = stamp.phenotype_attempt.status.name
      marker_symbol = stamp.phenotype_attempt.mi_plan.gene.marker_symbol

      #status_details = stamp.phenotype_attempt.mi_plan.latest_relevant_status

      details_hash = { :symbol => marker_symbol, #:status => status_details[:status], :date => status_details[:date],
        :plan_id => stamp.phenotype_attempt.mi_plan.id }

      summary[year] ||= {}
      summary[year][month] ||= {}
      summary[year][month][consortium] ||= {}
      summary[year][month][consortium][pcentre] ||= {}

      array = [
        'Phenotype Attempt Registered',
        'Rederivation Started',
        'Rederivation Complete',
        'Cre Excision Started',
        'Cre Excision Complete',
        'Phenotyping Started',
        'Phenotyping Complete',
        'Phenotype Attempt Aborted'
      ]

      array.each { |name| summary[year][month][consortium][pcentre][name] ||= {} }

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

    return summary
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
      string += "<td rowspan='YEAR_ROWSPAN'>#{year}</td>"
      month_hash = summary[year]
      month_hash.keys.sort.reverse!.each do |month|
        string += "<td rowspan='MONTH_ROWSPAN'>#{Date::MONTHNAMES[month]}</td>"
        cons_hash = month_hash[month]
        month_count = 0
        cons_hash.keys.each do |cons|
          centre_hash = cons_hash[cons]
          string += "<td rowspan='CONS_ROWSPAN'>#{cons}</td>"

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

          array2.each { |name| string += "<td rowspan='CONS_ROWSPAN'>#{make_link.call(name, summer[name])}</td>" }

          centre_hash.keys.each do |centre|
            next if centre.blank?

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

            string += "<td>#{centre}</td>"

            array.each { |name| string += "<td>#{make_link.call(name, status_hash)}</td>" }

            string += "</tr>\n"
            year_count += 1
            month_count += 1

          end
          string = string.gsub(/CONS_ROWSPAN/, centre_hash.keys.size.to_s)
        end
        string = string.gsub(/MONTH_ROWSPAN/, month_count.to_s)
      end
      string = string.gsub(/YEAR_ROWSPAN/, year_count.to_s)
    end
    string += '</table>'

    return string
  end

  def self.convert_to_csv(params, summary)

    array = [
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
        cons_hash.keys.each do |cons|
          centre_hash = cons_hash[cons]
          centre_hash.keys.each do |centre|
            status_hash = centre_hash[centre]

            hash = {
              'Year' => year,
              'Month' => month,
              'Consortium' => cons,
              'Production Centre' => centre
            }

            array.each do |name|
              hash[name] = status_hash[name] ? status_hash[name].keys.size : 0
            end

            report_table << hash

          end
        end
      end
    end

    return report_table
  end

  def self.convert_to_csv_new(params, summary)

    headings = [
      'Consortium',
      'Production Centre',
      'Gene',
      'Status',
      'Status Date'
    ]

    report_table = Table(headings)

    summary.keys.sort.reverse!.each do |year|
      month_hash = summary[year]
      month_hash.keys.sort.reverse!.each do |month|
        cons_hash = month_hash[month]
        cons_hash.keys.each do |cons|
          centre_hash = cons_hash[cons]
          centre_hash.keys.each do |centre|
            status_hash = centre_hash[centre]
            status_hash.keys.each do |status|
              gene_hash = status_hash[status]
              gene_hash.keys.each do |gene|

                report_table << {
                  'Consortium' => cons,
                  'Production Centre' => centre,
                  'Gene' => gene_hash[gene][:symbol],
                  'Status' => gene_hash[gene][:status],
                  'Status Date' => gene_hash[gene][:date]
                }

              end
            end
          end
        end
      end
    end

    return report_table
  end

end
