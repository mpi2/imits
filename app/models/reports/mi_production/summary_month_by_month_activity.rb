# encoding: utf-8

# TODO: what about empty centres?
# TODO: better rowspanning

class Reports::MiProduction::SummaryMonthByMonthActivity

  DEBUG = true
  CSV_BLANKS = false
  CUT_OFF_DATE = Date.parse('2011-08-01')

  #plan_thing = {
  #  :inspect_glt_mouse=>"Inspect - GLT Mouse",
  #  :inspect_mi_attempt=>"Inspect - MI Attempt",
  #  :inspect_conflict=>"Inspect - Conflict",
  #  :interest=>"Interest",
  #  :assigned_es_cell_qc_in_progress=>"Assigned - ES Cell QC In Progress",
  #  :assigned_es_cell_qc_complete=>"Assigned - ES Cell QC Complete",
  #  :inactive=>"Inactive",
  #  :aborted_es_cell_qc_failed=>"Aborted - ES Cell QC Failed",
  #  :withdrawn=>"Withdrawn",
  #  :conflict=>"Conflict",
  #  :assigned=>"Assigned"
  #}

  PLAN_MAP = Hash.new { |hash,key| "PLAN_MAP: No value defined for key: #{ key }" }
  MiPlan::Status.all.each { |i| PLAN_MAP[i.name.downcase.parameterize.underscore.to_sym] = i.name }

  ATTEMPT_MAP = Hash.new { |hash,key| "ATTEMPT_MAP: No value defined for key: #{ key }" }
  MiAttempt::Status.all.each { |i| ATTEMPT_MAP[i.name.downcase.parameterize.underscore.to_sym] = i.name }

  PHENOTYPE_MAP = Hash.new { |hash,key| "PHENOTYPE_MAP: No value defined for key: #{ key }" }
  PhenotypeAttempt::Status.all.each { |i| PHENOTYPE_MAP[i.name.downcase.parameterize.underscore.to_sym] = i.name }

  PLAN_STATUSES = [PLAN_MAP[:assigned_es_cell_qc_in_progress], PLAN_MAP[:assigned_es_cell_qc_complete], PLAN_MAP[:aborted_es_cell_qc_failed]]
  ATTEMPT_STATUSES = [ATTEMPT_MAP[:micro_injection_in_progress], ATTEMPT_MAP[:genotype_confirmed],
    ATTEMPT_MAP[:micro_injection_aborted]]
  #PHENOTYPE_STATUSES = [
  #  PHENOTYPE_MAP[:phenotype_attempt_aborted],
  #  PHENOTYPE_MAP[:phenotyping_complete],
  #  PHENOTYPE_MAP[:phenotyping_started],
  #  PHENOTYPE_MAP[:cre_excision_complete],
  #  PHENOTYPE_MAP[:cre_excision_started],
  #  PHENOTYPE_MAP[:rederivation_started],
  #  PHENOTYPE_MAP[:rederivation_complete],
  #  PHENOTYPE_MAP[:phenotype_attempt_registered]
  #]
  PHENOTYPE_STATUSES = []
  PHENOTYPE_MAP.keys.each { |name| PHENOTYPE_STATUSES.push([name]) }

  HEADINGS = [
    'Year',
    'Month',
    'Consortium',
    'Production Centre',

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

  def self.generate(params = {})

    #puts PLAN_MAP[:hello]
    #raise PLAN_MAP.inspect

    if params[:consortium]
      title, table = subsummary(params)
      return { :csv => table.to_csv, :html => table.to_html, :title => title,
        :table => table # for test
      }
    end

    summary = get_summary(params)

    table, html_string = prettify(params, summary)

    title = params[:komp2] ? 'KOMP2 Summary Month by Month' : 'All Consortia Summary Month by Month'

    return { :csv => table.to_csv, :html => html_string, :title => title,
      :table => table # for test
    }
  end

  def self.prettify(params, summary)
    string = '<table>'
    string += '<tr>'

    script_name = params[:script_name]

    report_table = Table(HEADINGS)

    make_clean = lambda do |value|
      return value if params[:format] == :csv && ! CSV_BLANKS
      return '' if value.to_s.length < 1
      return '' if value.to_i == 0
      return value
    end

    report_table.column_names.each { |name| string += "<th>#{name}</th>" }

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
          centre_hash.keys.each do |centre|
            next if centre.blank?

            make_link = lambda do |key, frame|
              return frame[key].keys.size if params[:format] == :csv
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

            string += "<td>#{centre}</td>"

            array.each { |name| string += "<td>#{make_link.call(name, status_hash)}</td>" }

            string += "</tr>\n"
            year_count += 1
            month_count += 1

            hash = {
              'Year' => year,
              'Month' => month,
              'Consortium' => cons,
              'Production Centre' => centre
            }

            array.each { |name| hash[name] = make_clean.call(status_hash[name].keys.size) }

            report_table << hash

          end
          string = string.gsub(/CONS_ROWSPAN/, centre_hash.keys.size.to_s)
        end
        string = string.gsub(/MONTH_ROWSPAN/, month_count.to_s)
      end
      string = string.gsub(/YEAR_ROWSPAN/, year_count.to_s)
    end
    string += '</table>'
    return report_table, string
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
      summary[year.to_i][month.to_i][consortium].each do |centre|
        summary[year.to_i][month.to_i][consortium][centre][type].keys.each do |gene|
          table << {
            "Date" => summary[year.to_i][month.to_i][consortium][pcentre][type][gene][:date].strftime("%Y-%m-%d"),
            "Consortium" => consortium,
            "Centre" => pcentre,
            "Marker Symbol" => summary[year.to_i][month.to_i][consortium][pcentre][type][gene][:symbol],
            "Status" => summary[year.to_i][month.to_i][consortium][pcentre][type][gene][:status]
          }
        end
      end
    end

    if pcentre
      summary[year.to_i][month.to_i][consortium][pcentre][type].keys.each do |gene|
        table << {
          "Date" => summary[year.to_i][month.to_i][consortium][pcentre][type][gene][:date].strftime("%Y-%m-%d"),
          "Consortium" => consortium,
          "Centre" => pcentre,
          "Marker Symbol" => summary[year.to_i][month.to_i][consortium][pcentre][type][gene][:symbol],
          "Status" => summary[year.to_i][month.to_i][consortium][pcentre][type][gene][:status]
        }
      end
    end

    table.sort_rows_by!("Date", :order => :descending)

    title = ''
    title = "Plan Details" if PLAN_STATUSES.include? type
    title = "Attempt Details" if ATTEMPT_STATUSES.include? type
    title = "Phenotype Details" if PHENOTYPE_STATUSES.include? type
    size = table && table.data && table.data.size ? table.data.size : 0
    title += " - YEAR: #{year} - MONTH: #{month} - CONSORTIUM: #{consortium} - CENTRE: #{pcentre} - TYPE: #{type} (#{size})" if DEBUG

    return title, table
  end

  def self.get_summary(params)
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }

    consortia = params && params[:komp2] ? ['BaSH', 'DTCC', 'JAX'] : nil

    type = params[:type]

    if ! type || PLAN_STATUSES.include?(type)

      MiPlan::StatusStamp.all.each do |stamp|

        next if consortia && stamp.created_at < CUT_OFF_DATE

        year = stamp.created_at.year
        month = stamp.created_at.month
        day = stamp.created_at.day
        consortium = stamp.mi_plan.consortium.name
        pcentre = stamp.mi_plan.production_centre && stamp.mi_plan.production_centre.name ? stamp.mi_plan.production_centre.name : 'UNKNOWN'
        pcentre = 'UNKNOWN' if pcentre.blank? || pcentre.to_s.length < 1
        next if consortia && ! consortia.include?(consortium)
        gene_id = stamp.mi_plan.gene_id
        status = stamp.status.name
        marker_symbol = stamp.mi_plan.gene.marker_symbol

        details_hash = { :symbol => marker_symbol, :status => status, :date => stamp.created_at }

        if status == PLAN_MAP[:assigned_es_cell_qc_in_progress]
          summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
        end

        if status == PLAN_MAP[:assigned_es_cell_qc_complete]
          summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
          summary[year][month][consortium][pcentre]['ES Cell QC Complete'][gene_id] = details_hash
        end

        if status == PLAN_MAP[:aborted_es_cell_qc_failed]
          summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
          summary[year][month][consortium][pcentre]['ES Cell QC Failed'][gene_id] = details_hash
        end

      end

      return summary if PLAN_STATUSES.include? type

    end

    if ! type || ATTEMPT_STATUSES.include?(type)

      MiAttempt::StatusStamp.all.each do |stamp|

        next if consortia && stamp.created_at < CUT_OFF_DATE

        year = stamp.created_at.year
        month = stamp.created_at.month
        day = stamp.created_at.day
        consortium = stamp.mi_attempt.mi_plan.consortium.name
        pcentre = stamp.mi_attempt.production_centre_name
        pcentre = 'UNKNOWN' if pcentre.blank? || pcentre.to_s.length < 1
        next if consortia && ! consortia.include?(consortium)
        gene_id = stamp.mi_attempt.mi_plan.gene_id
        status = stamp.mi_attempt_status.description
        marker_symbol = stamp.mi_attempt.mi_plan.gene.marker_symbol

        details_hash = {
          :symbol => marker_symbol,
          :status => stamp.mi_attempt.mi_plan.latest_relevant_mi_attempt.mi_attempt_status.description,
          :date => stamp.mi_attempt.mi_plan.latest_relevant_mi_attempt.mi_attempt_status.created_at
        }

        if(status == ATTEMPT_MAP[:micro_injection_in_progress])
          summary[year][month][consortium][pcentre]['Micro-injection in progress'][gene_id] = details_hash
        end

        if(status == ATTEMPT_MAP[:genotype_confirmed])
          summary[year][month][consortium][pcentre]['Micro-injection in progress'][gene_id] = details_hash
          summary[year][month][consortium][pcentre]['Genotype confirmed'][gene_id] = details_hash
        end

        if(status == ATTEMPT_MAP[:micro_injection_aborted])
          summary[year][month][consortium][pcentre]['Micro-injection in progress'][gene_id] = details_hash
          summary[year][month][consortium][pcentre]['Micro-injection aborted'][gene_id] = details_hash
        end

      end

      return summary if ATTEMPT_STATUSES.include? type

    end

    if ! type || PHENOTYPE_STATUSES.include?(type)

      PhenotypeAttempt::StatusStamp.all.each do |stamp|

        next if consortia && stamp.created_at < CUT_OFF_DATE

        year = stamp.created_at.year
        month = stamp.created_at.month
        day = stamp.created_at.day

        consortium = stamp.phenotype_attempt.mi_plan.consortium.name

        pcentre = stamp.phenotype_attempt.mi_plan.production_centre && stamp.phenotype_attempt.mi_plan.production_centre.name ?
          stamp.phenotype_attempt.mi_plan.production_centre.name : ''

        pcentre = 'UNKNOWN' if pcentre.blank?
        next if consortia && ! consortia.include?(consortium)
        gene_id = stamp.phenotype_attempt.mi_plan.gene_id
        status = stamp.phenotype_attempt.status.name
        marker_symbol = stamp.phenotype_attempt.mi_plan.gene.marker_symbol

        details_hash = {
          :symbol => marker_symbol,
          :status => stamp.phenotype_attempt.mi_plan.latest_relevant_phenotype_attempt.status.name,
          :date => stamp.phenotype_attempt.mi_plan.latest_relevant_phenotype_attempt.status.created_at
        }

        if status == PHENOTYPE_MAP[:phenotype_attempt_aborted]
          summary[year][month][consortium][pcentre]['Phenotype Attempt Aborted'][gene_id] = details_hash
        end

        if status == PHENOTYPE_MAP[:phenotyping_complete]
          summary[year][month][consortium][pcentre]['Phenotyping Complete'][gene_id] = details_hash
        end

        phenotyping_started = [ PHENOTYPE_MAP[:phenotyping_started], PHENOTYPE_MAP[:phenotyping_complete] ]

        if phenotyping_started.include?(status)
          summary[year][month][consortium][pcentre]['Phenotyping Started'][gene_id] = details_hash
        end

        cre_excision_complete = phenotyping_started + [ PHENOTYPE_MAP[:cre_excision_complete] ]

        if cre_excision_complete.include?(status)
          summary[year][month][consortium][pcentre]['Cre Excision Complete'][gene_id] = details_hash
        end

        cre_excision_started = cre_excision_complete + [ PHENOTYPE_MAP[:cre_excision_started] ]

        if cre_excision_started.include?(status)
          summary[year][month][consortium][pcentre]['Cre Excision Started'][gene_id] = details_hash
        end

        rederivation_started = cre_excision_started + [ PHENOTYPE_MAP[:rederivation_started] ]

        if rederivation_started.include?(status)
          summary[year][month][consortium][pcentre]['Rederivation Started'][gene_id] = details_hash
          #TODO: check
        end

        rederivation_complete = rederivation_started + [ PHENOTYPE_MAP[:rederivation_complete] ]

        if rederivation_complete.include?(status)
          summary[year][month][consortium][pcentre]['Rederivation Complete'][gene_id] = details_hash
          #TODO: check
        end

        phenotype_attempt_registered = rederivation_complete + [ PHENOTYPE_MAP[:phenotype_attempt_registered] ]

        if phenotype_attempt_registered.include?(status)
          summary[year][month][consortium][pcentre]['Phenotype Attempt Registered'][gene_id] = details_hash
        end

      end

      return summary if PHENOTYPE_STATUSES.include? type

    end

    return summary
  end

  def self.prettify2(params, summary)
    string = '<table>'
    string += '<tr>'

    script_name = params[:script_name]

    report_table = Table(HEADINGS)

    make_clean = lambda do |value|
      return value if params[:format] == :csv && ! CSV_BLANKS
      return '' if value.to_s.length < 1
      return '' if value.to_i == 0
      return value
    end

    report_table.column_names.each { |name| string += "<th>#{name}</th>" }

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
          
 
 
          # new bit to re-jig plan stuff
          
          make_link = lambda do |key, value|
            return value if params[:format] == :csv
            return '' if value.to_s.length < 1
            consort = CGI.escape cons
            type = CGI.escape key.to_s
            separator = /\?/.match(script_name) ? '&' : '?'
            return "<a href='#{script_name}#{separator}year=#{year}&month=#{month}&consortium=#{consort}&type=#{type}'>#{value}</a>"
          end
          
          centre_hash.keys.each do |centre|
            array2 = [ 'ES Cell QC In Progress', 'ES Cell QC Complete', 'ES Cell QC Failed' ]
            summer = {'ES Cell QC In Progress'=> 0, 'ES Cell QC Complete' => 0, 'ES Cell QC Failed' => 0}
            status_hash = centre_hash[centre]
            array2.each { |name| summer[name] += status_hash[name] }
          end          
    
          array2.each { |name| string += "<td rowspan='#{centre_hash.keys.size.to_s}'>#{make_link.call(name, status_hash[name])}</td>" }
 
 
          
          
          centre_hash.keys.each do |centre|
            next if centre.blank?

            make_link = lambda do |key, frame|
              return frame[key].keys.size if params[:format] == :csv
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
              #'ES Cell QC In Progress',
              #'ES Cell QC Complete',
              #'ES Cell QC Failed',
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

            hash = {
              'Year' => year,
              'Month' => month,
              'Consortium' => cons,
              'Production Centre' => centre
            }

            array.each { |name| hash[name] = make_clean.call(status_hash[name].keys.size) }

            report_table << hash

          end
          string = string.gsub(/CONS_ROWSPAN/, centre_hash.keys.size.to_s)
        end
        string = string.gsub(/MONTH_ROWSPAN/, month_count.to_s)
      end
      string = string.gsub(/YEAR_ROWSPAN/, year_count.to_s)
    end
    string += '</table>'
    return report_table, string
  end
  
end
