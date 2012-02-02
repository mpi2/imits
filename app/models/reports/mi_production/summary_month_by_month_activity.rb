# encoding: utf-8

# TODO: use proper names in summary hashes
# TODO: add title to pages
# TODO: what about empty centres?

class Reports::MiProduction::SummaryMonthByMonthActivity
  
  CSV_BLANKS = true

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
  HEADINGS_MAP = {}
  HEADINGS.each { |name| HEADINGS_MAP[name] = name }
  HEADINGS_MAP_INVERTED = HEADINGS_MAP.invert
  HEADINGS_CLEAN = []
  HEADINGS.each { |name| HEADINGS_CLEAN.push(HEADINGS_MAP[name]) }
  
  def self.generate(params)
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }

    if params[:consortium]
      table = subsummary(params)
      return { :csv => table.to_csv, :html => table.to_html }
    end
    
    summary = get_summary(params)

    table, html_string = prettify(params, summary)

    return { :csv => table.to_csv, :html => html_string}
  end

  def self.prettify(params, summary)
    string = ''
    string += '<table>'
    string += '<tr>'

    script_name = params[:script_name]

    report_table = Table(HEADINGS_CLEAN)

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
              'es_qcs',
              'es_confirms',
              'es_fails',
              'mi',
              'gc',
              'abort',
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
              'Production Centre' => centre,
              'ES Cell QC In Progress' => make_clean.call(status_hash['es_qcs'].keys.size),
              'ES Cell QC Complete' => make_clean.call(status_hash['es_confirms'].keys.size),
              'ES Cell QC Failed' => make_clean.call(status_hash['es_fails'].keys.size),
              'Micro-injection in progress' => make_clean.call(status_hash['mi'].keys.size),
              'Genotype confirmed' => make_clean.call(status_hash['gc'].keys.size),
              'Micro-injection aborted' => make_clean.call(status_hash['abort'].keys.size)
            }

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
        
    consortium = params[:consortium]
    type = params[:type]
    priority = params[:priority]
    pcentre = params[:pcentre]
    year = params[:year]
    month = params[:month]
        
    summary = get_summary(params)
    
    table = Table(["Marker Symbol", "Year", "Month", "Consortium", "Centre"])
    
    summary[year.to_i][month.to_i][consortium][pcentre][type].keys.each do |gene|
      table << {
        "Year" => year,
        "Month"=>month,
        "Consortium"=> consortium,
        "Centre"=>pcentre,
        "Marker Symbol" => summary[year.to_i][month.to_i][consortium][pcentre][type][gene]
      }
    end
    
    return table
  end
  
  def self.get_summary(params)
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
    
    consortia = params && params[:komp2] ? ['BaSH', 'DTCC', 'JAX'] : nil
    
    MiPlan::StatusStamp.all.each do |stamp|
      
      next if consortia && stamp.created_at < Date.parse('2011-08-01')
      
      year = stamp.created_at.year
      month = stamp.created_at.month
      day = stamp.created_at.month
      consortium = stamp.mi_plan.consortium.name
      pcentre = stamp.mi_plan.production_centre && stamp.mi_plan.production_centre.name ? stamp.mi_plan.production_centre.name : ''
      next if pcentre.blank? || pcentre.to_s.length < 1
      next if consortia && ! consortia.include?(consortium)
      gene_id = stamp.mi_plan.gene_id
      status = stamp.status.name
      marker_symbol = stamp.mi_plan.gene.marker_symbol
      summary[year][month][consortium][pcentre]['all'][gene_id] = marker_symbol

      if(status == 'Assigned - ES Cell QC In Progress')
        summary[year][month][consortium][pcentre]['es_qcs'][gene_id] = marker_symbol
      end
    
      if(status == 'Assigned - ES Cell QC Complete')
        summary[year][month][consortium][pcentre]['es_qcs'][gene_id] = marker_symbol
        summary[year][month][consortium][pcentre]['es_confirms'][gene_id] = marker_symbol
      end
    
      if(status == 'Aborted - ES Cell QC Failed')
        summary[year][month][consortium][pcentre]['es_qcs'][gene_id] = marker_symbol
        summary[year][month][consortium][pcentre]['es_fails'][gene_id] = marker_symbol
      end
               
    end

    MiAttempt::StatusStamp.all.each do |stamp|

      next if consortia && stamp.created_at < Date.parse('2011-08-01')

      year = stamp.created_at.year
      month = stamp.created_at.month
      day = stamp.created_at.day
      consortium = stamp.mi_attempt.mi_plan.consortium.name
      pcentre = stamp.mi_attempt.production_centre_name
      next if pcentre.blank? || pcentre.to_s.length < 1
      next if consortia && ! consortia.include?(consortium)
      gene_id = stamp.mi_attempt.mi_plan.gene_id
      status = stamp.mi_attempt_status.description
      marker_symbol = stamp.mi_attempt.mi_plan.gene.marker_symbol
          
      if(status == 'Micro-injection in progress')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = marker_symbol
      end
    
      if(status == 'Genotype confirmed')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = marker_symbol
        summary[year][month][consortium][pcentre]['gc'][gene_id] = marker_symbol
      end
    
      if(status == 'Micro-injection aborted')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = marker_symbol
        summary[year][month][consortium][pcentre]['abort'][gene_id] = marker_symbol
      end
      
    end
    
    PhenotypeAttempt::StatusStamp.all.each do |stamp|

      next if consortia && stamp.created_at < Date.parse('2011-08-01')

      year = stamp.created_at.year
      month = stamp.created_at.month
      day = stamp.created_at.day
	  
      consortium = stamp.phenotype_attempt.mi_plan.consortium.name
      
      pcentre = stamp.phenotype_attempt.mi_plan.production_centre && stamp.phenotype_attempt.mi_plan.production_centre.name ? 
        stamp.phenotype_attempt.mi_plan.production_centre.name : ''
      
      next if pcentre.blank?
      next if consortia && ! consortia.include?(consortium)
      gene_id = stamp.phenotype_attempt.mi_plan.gene_id
      status = stamp.phenotype_attempt.status.name
      marker_symbol = stamp.phenotype_attempt.mi_plan.gene.marker_symbol

      if status == 'Phenotype Attempt Aborted'
        summary[year][month][consortium][pcentre]['Phenotype Attempt Aborted'][gene_id] = marker_symbol
      end
    
      if status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Phenotyping Complete'][gene_id] = marker_symbol
      end
    
      if status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Phenotyping Started'][gene_id] = marker_symbol
      end
    
      if status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Cre Excision Complete'][gene_id] = marker_symbol
      end
    
      if status == 'Cre Excision Started' || status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Cre Excision Started'][gene_id] = marker_symbol
      end
    
      if status == 'Rederivation Started' || status == 'Rederivation Complete' || status == 'Cre Excision Started' || status == 'Cre Excision Complete' ||
          status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Rederivation Started'][gene_id] = marker_symbol
        #TODO: check
      end
    
      if status == 'Rederivation Complete' || status == 'Cre Excision Started' || status == 'Cre Excision Complete' ||
          status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Rederivation Complete'][gene_id] = marker_symbol
        #TODO: check
      end
    
      if status == 'Phenotype Attempt Registered' || status == 'Cre Excision Started' || status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete' ||
          status == 'Rederivation Started' || status == 'Rederivation Complete' ||
          status == 'Phenotype Attempt Aborted'
        summary[year][month][consortium][pcentre]['Phenotype Attempt Registered'][gene_id] = marker_symbol
      end

    end

    return summary
  end

end
