# encoding: utf-8

class Reports::MiProduction::SummaryMonthByMonthActivity

  DEBUG = false
  RAILS_CACHE = true
  CSV_BLANKS = false
  CUT_OFF_DATE = Date.parse('2011-08-01')
  NEW_CODE = true

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

    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }

    plan_map = Hash.new { |hash,key| raise("plan_map: No value defined for key: #{ key }") }
    MiPlan::Status.all.each { |i| plan_map[i.name.downcase.parameterize.underscore.to_sym] = i.name }

    attempt_map = Hash.new { |hash,key| raise("attempt_map: No value defined for key: #{ key }") }
    MiAttemptStatus.all.each { |i| attempt_map[i.description.downcase.parameterize.underscore.to_sym] = i.description }

    phenotype_map = Hash.new { |hash,key| raise("phenotype_map: No value defined for key: #{ key }") }
    PhenotypeAttempt::Status.all.each { |i| phenotype_map[i.name.downcase.parameterize.underscore.to_sym] = i.name }

    consortia = params && params[:komp2] ? ['BaSH', 'DTCC', 'JAX'] : nil

    consortia_list = consortia ? consortia : Consortium.all.map(&:name)

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

      details_hash = { :symbol => marker_symbol, :plan_id => stamp.mi_plan.id, :original_status => status, :original_date => stamp.created_at }

      #summary[year][month][consortium]['DUMMY']['ES Cell QC In Progress'] ||= {}
      #summary[year][month][consortium]['DUMMY']['ES Cell QC Complete'] ||= {}
      #summary[year][month][consortium]['DUMMY']['ES Cell QC Failed'] ||= {}

      if NEW_CODE
        consortia_list.each do |name|
          summary[year][month][name]['DUMMY']['ES Cell QC In Progress'] ||= {}
          summary[year][month][name]['DUMMY']['ES Cell QC Complete'] ||= {}
          summary[year][month][name]['DUMMY']['ES Cell QC Failed'] ||= {}
        end
      end

      # if NEW_CODE
      #   Consortium.all.each { |c| summary[year][month][c.name]['DUMMY']['ES Cell QC In Progress'] ||= {} } if ! consortia
      # end

      # wibble = nil

      if status == plan_map[:assigned_es_cell_qc_in_progress]
        summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
        #  wibble = 'ES Cell QC In Progress'
      end

      if status == plan_map[:assigned_es_cell_qc_complete]
        summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
        summary[year][month][consortium][pcentre]['ES Cell QC Complete'][gene_id] = details_hash
        #   wibble = 'ES Cell QC Complete'
      end

      if status == plan_map[:aborted_es_cell_qc_failed]
        summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
        summary[year][month][consortium][pcentre]['ES Cell QC Failed'][gene_id] = details_hash
        #  wibble = 'ES Cell QC Failed'
      end

      #consortia.each { |name| summary[year][month][name]['DUMMY'][wibble] ||= {} } if consortia && wibble
      #Consortium.all.each { |c| summary[year][month][c.name]['DUMMY'][wibble] ||= {} } if ! consortia && wibble
      #consortia_list.each { |c| summary[year][month][c]['DUMMY'][wibble] ||= {} }

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

      details_hash = { :symbol => marker_symbol, :plan_id => stamp.mi_attempt.mi_plan.id, :original_status => status, :original_date => stamp.created_at }

      #summary[year][month][consortium]['DUMMY']['Micro-injection in progress'] ||= {}
      #summary[year][month][consortium]['DUMMY']['Genotype confirmed'] ||= {}
      #summary[year][month][consortium]['DUMMY']['Micro-injection aborted'] ||= {}

      #consortia.each { |name| summary[year][month][name]['DUMMY']['ES Cell QC In Progress'] ||= {} } if consortia
      #Consortium.all.each { |c| summary[year][month][c.name]['DUMMY']['ES Cell QC In Progress'] ||= {} } if ! consortia

      if NEW_CODE
        consortia_list.each do |name|
          summary[year][month][name]['DUMMY']['Micro-injection in progress'] ||= {}
          summary[year][month][name]['DUMMY']['Genotype confirmed'] ||= {}
          summary[year][month][name]['DUMMY']['Micro-injection aborted'] ||= {}
        end
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

      details_hash = { :symbol => marker_symbol, :plan_id => stamp.phenotype_attempt.mi_plan.id, :original_status => status, :original_date => stamp.created_at }

      #summary[year][month][consortium]['DUMMY']['Phenotype Attempt Aborted'] ||= {}

      # consortia.each { |name| summary[year][month][name]['DUMMY']['ES Cell QC In Progress'] ||= {} } if consortia
      # Consortium.all.each { |c| summary[year][month][c.name]['DUMMY']['ES Cell QC In Progress'] ||= {} } if ! consortia

      if NEW_CODE
        consortia_list.each do |name|
          summary[year][month][name]['DUMMY']['Phenotype Attempt Aborted'] ||= {}
        end
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

    #puts summary.inspect

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

            #string += "</tr>\n" if NEW_CODE && centre == 'DUMMY'
            next if NEW_CODE && centre == 'DUMMY' && centre_hash.keys.size > 1

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

            c = NEW_CODE && centre == 'DUMMY' ? '' : centre

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

            #next if centre == 'DUMMY'
            #            next if centre == 'DUMMY' && ! cons_hash.fetch(cons) || cons_hash[cons]
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

  def self.convert_to_csv_full(params, summary)

    headings = [
      'Consortium',
      'Production Centre',
      'Gene',
      'Original Status',
      'Original Status Date',
      'Current Status',
      'Current Status Date'
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

                plan_id = gene_hash[gene][:plan_id]
                plan = MiPlan.find(plan_id)
                status_details = plan.latest_relevant_status

                report_table << {
                  'Consortium' => cons,
                  'Production Centre' => centre,
                  'Gene' => gene_hash[gene][:symbol],
                  'Original Status' => gene_hash[gene][:original_status],
                  'Original Status Date' => gene_hash[gene][:original_date],
                  'Current Status' => status_details[:status],
                  'Current Status Date' => status_details[:date].to_date
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
