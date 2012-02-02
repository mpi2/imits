# encoding: utf-8

# TODO: use proper names in summary hashes
# TODO: add cell links
# TODO: drop test routines *_new
# TODO: add title to pages


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
    #consortia = ['BaSH', 'DTCC', 'JAX']
    #return generate_new(params)
    return generate_original(params)
  end
  
  def self.generate_new(params)
    
#    raise "generate_new - params: " + params.inspect

    
    if params[:consortium]
      #raise "generate_new - params"
      table = subsummary_original(params)
      return { :csv => table.to_csv, :html => table.to_html}
    end

    consortia = params[:komp2] ? ['BaSH', 'DTCC', 'JAX'] : nil

    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
    
    plans_table = get_plans
    
    puts plans_table.inspect

    for i in (0..plans_table.column('Year').size-1)

      year = plans_table.column('Year')[i].to_i
      month = plans_table.column('Month')[i].to_i
      day = plans_table.column('Day')[i].to_i
      
      m = "%02i" % month
      d = "%02i" % day
      
      puts "PLANS DATE: #{year}-#{m}-#{d}"

      next if consortia && Date.parse("#{year}-#{month}-#{day}") < Date.parse('2011-08-01')

      consortium = plans_table.column('Consortium')[i]
      pcentre = plans_table.column('Centre')[i]
      next if pcentre.blank? || pcentre.to_s.length < 1
      next if consortia && ! consortia.include?(consortium)
      gene_id = plans_table.column('Gene Id')[i]
      status = plans_table.column('Status')[i]
      marker_symbol = plans_table.column('Marker Symbol')[i]
      summary[year][month][consortium][pcentre]['all'][gene_id] = 1

      if(status == 'Assigned - ES Cell QC In Progress')
        summary[year][month][consortium][pcentre]['es_qcs'][gene_id] = 1
      end
    
      if(status == 'Assigned - ES Cell QC Complete')
        summary[year][month][consortium][pcentre]['es_qcs'][gene_id] = 1
        summary[year][month][consortium][pcentre]['es_confirms'][gene_id] = 1
      end
    
      if(status == 'Aborted - ES Cell QC Failed')
        summary[year][month][consortium][pcentre]['es_qcs'][gene_id] = 1
        summary[year][month][consortium][pcentre]['es_fails'][gene_id] = 1
      end

    end

    attempts_table = get_attempts

    puts attempts_table.inspect

    for i in (0..attempts_table.column('Year').size-1)

      year = attempts_table.column('Year')[i].to_i
      month = attempts_table.column('Month')[i].to_i
      day = attempts_table.column('Day')[i].to_i

      m = "%02i" % month
      d = "%02i" % day

      next if consortia && Date.parse("#{year}-#{m}-#{d}") < Date.parse('2011-08-01')

      consortium = attempts_table.column('Consortium')[i]
      pcentre = attempts_table.column('Centre')[i]
      next if pcentre.blank? || pcentre.to_s.length < 1
      next if consortia && ! consortia.include?(consortium)
      gene_id = attempts_table.column('Gene Id')[i]
      status = attempts_table.column('Status')[i]
      marker_symbol = attempts_table.column('Marker Symbol')[i]
          
      if(status == 'Micro-injection in progress')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = 1
      end
    
      if(status == 'Genotype confirmed')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = 1
        summary[year][month][consortium][pcentre]['gc'][gene_id] = 1
      end
    
      if(status == 'Micro-injection aborted')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = 1
        summary[year][month][consortium][pcentre]['abort'][gene_id] = 1
      end
    
    end

    phenotypes_table = get_phenotypes

    puts phenotypes_table.inspect
    
    for i in (0..phenotypes_table.column('Year').size-1)

      year = phenotypes_table.column('Year')[i].to_i
      month = phenotypes_table.column('Month')[i].to_i
      day = phenotypes_table.column('Day')[i].to_i

      m = "%02i" % month
      d = "%02i" % day

      puts "PHENO DATE: #{year}-#{m}-#{d}"

      next if consortia && Date.parse("#{year}-#{month}-#{day}") < Date.parse('2011-08-01')

      consortium = phenotypes_table.column('Consortium')[i]
      pcentre = phenotypes_table.column('Centre')[i]
      
      next if pcentre.blank?
      next if consortia && ! consortia.include?(consortium)
      gene_id = phenotypes_table.column('Gene Id')[i]
      status = phenotypes_table.column('Status')[i]
      marker_symbol = phenotypes_table.column('Marker Symbol')[i]

      if status == 'Phenotype Attempt Aborted'
        summary[year][month][consortium][pcentre]['Phenotype Attempt Aborted'][gene_id] = 1
      end
      
      if status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Phenotyping Complete'][gene_id] = 1
        ok = true
      end
      
      if status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Phenotyping Started'][gene_id] = 1
      end
      
      if status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Cre Excision Complete'][gene_id] = 1
      end
      
      if status == 'Cre Excision Started' || status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Cre Excision Started'][gene_id] = 1
        ok = true
      end
      
      if status == 'Rederivation Started' || status == 'Rederivation Complete' || status == 'Cre Excision Started' || status == 'Cre Excision Complete' ||
          status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Rederivation Started'][gene_id] = 1
        #TODO: check
      end
      
      if status == 'Rederivation Complete' || status == 'Cre Excision Started' || status == 'Cre Excision Complete' ||
          status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Rederivation Complete'][gene_id] = 1
        #TODO: check
      end
      
      if status == 'Phenotype Attempt Registered' ||
          status == 'Cre Excision Started' ||
          status == 'Cre Excision Complete' ||
          status == 'Phenotyping Started' ||
          status == 'Phenotyping Complete' ||
          status == 'Rederivation Started' ||
          status == 'Rederivation Complete' ||
          status == 'Phenotype Attempt Aborted'
        summary[year][month][consortium][pcentre]['Phenotype Attempt Registered'][gene_id] = 1
      end
        
    end
  
    table, html_string = prettify(params, summary)

    return { :csv => table.to_csv, :html => html_string}
  end

  def self.generate_original(params)
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }

    if params[:consortium]
      #raise "generate_new - params"
      table = subsummary_new(params)
      return { :csv => table.to_csv, :html => table.to_html}
    end
    
    table1 = Table(['Year', 'Month', 'Day', 'Consortium', 'Centre', 'Gene Id', 'Marker', 'Status', 'Date Valid', 'Included', 'Count'])
    table2 = Table(['Year', 'Month', 'Day', 'Consortium', 'Centre', 'Gene Id', 'Marker', 'Status', 'Date Valid', 'Included'])
    table3 = Table(['Year', 'Month', 'Day', 'Consortium', 'Centre', 'Gene Id', 'Marker', 'Status', 'Date Valid', 'Included'])

    counter = {}
    consortia = params[:komp2] ? ['BaSH', 'DTCC', 'JAX'] : nil
    
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
      summary[year][month][consortium][pcentre]['all'][gene_id] = 1
      
      counter[gene_id] ||= 0
      counter[gene_id] += 1
      
      ok = false
    
      if(status == 'Assigned - ES Cell QC In Progress')
        summary[year][month][consortium][pcentre]['es_qcs'][gene_id] = 1
        #puts "PLANS 1: #{year} - #{month} - #{consortium} - #{pcentre} - #{marker_symbol}"
        ok = true
      end
    
      if(status == 'Assigned - ES Cell QC Complete')
        summary[year][month][consortium][pcentre]['es_qcs'][gene_id] = 1
        summary[year][month][consortium][pcentre]['es_confirms'][gene_id] = 1
        #puts "PLANS 2: #{year} - #{month} - #{consortium} - #{pcentre} - #{marker_symbol}"
        ok = true
      end
    
      if(status == 'Aborted - ES Cell QC Failed')
        summary[year][month][consortium][pcentre]['es_qcs'][gene_id] = 1
        summary[year][month][consortium][pcentre]['es_fails'][gene_id] = 1
        puts "PLANS 3: #{year} - #{month} - #{consortium} - #{pcentre} - #{marker_symbol} = #{status}"
        puts stamp.inspect
        ok = true
      end
      
      date_early = stamp.created_at < Date.parse('2011-08-01')
      
      table1 << {
        'Year' => year,
        'Month' => month,
        'Consortium' => consortium,
        'Centre' => pcentre,
        'Gene Id' => gene_id,
        'Marker' => marker_symbol,
        'Status' => status,
        'Date Valid' => (date_early ? 'No':'Yes'),
        'Included' => (ok ? 'Yes':'No'),
        'Count' => counter[gene_id].to_i,
        'Day' => day
      }
      
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
      
      ok = false
    
      if(status == 'Micro-injection in progress')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = 1
        ok = true
      end
    
      if(status == 'Genotype confirmed')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = 1
        summary[year][month][consortium][pcentre]['gc'][gene_id] = 1
        ok = true
      end
    
      if(status == 'Micro-injection aborted')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = 1
        summary[year][month][consortium][pcentre]['abort'][gene_id] = 1
        ok = true
      end

      date_early = stamp.created_at < Date.parse('2011-08-01')
      
      table2 << {
        'Year' => year,
        'Month' => month,
        'Consortium' => consortium,
        'Centre' => pcentre,
        'Gene Id' => gene_id,
        'Marker' => marker_symbol,
        'Status' => status,
        'Date Valid' => (date_early ? 'No':'Yes'),
        'Included' => (ok ? 'Yes':'No'),
        'Day' => day
      }
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

      ok = false

      if status == 'Phenotype Attempt Aborted'
        summary[year][month][consortium][pcentre]['Phenotype Attempt Aborted'][gene_id] = 1
        ok = true
      end
    
      if status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Phenotyping Complete'][gene_id] = 1
        ok = true
      end
    
      if status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Phenotyping Started'][gene_id] = 1
        ok = true
      end
    
      if status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Cre Excision Complete'][gene_id] = 1
        ok = true
      end
    
      if status == 'Cre Excision Started' || status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Cre Excision Started'][gene_id] = 1
        ok = true
      end
    
      if status == 'Rederivation Started' || status == 'Rederivation Complete' || status == 'Cre Excision Started' || status == 'Cre Excision Complete' ||
          status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Rederivation Started'][gene_id] = 1
        ok = true
        #TODO: check
      end
    
      if status == 'Rederivation Complete' || status == 'Cre Excision Started' || status == 'Cre Excision Complete' ||
          status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Rederivation Complete'][gene_id] = 1
        ok = true
        #TODO: check
      end
    
      if status == 'Phenotype Attempt Registered' || status == 'Cre Excision Started' || status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete' ||
          status == 'Rederivation Started' || status == 'Rederivation Complete' ||
          status == 'Phenotype Attempt Aborted'
        summary[year][month][consortium][pcentre]['Phenotype Attempt Registered'][gene_id] = 1
        ok = true
      end

      date_early = stamp.created_at < Date.parse('2011-08-01')
      
      table3 << {
        'Year' => year,
        'Month' => month,
        'Consortium' => consortium,
        'Centre' => pcentre,
        'Gene Id' => gene_id,
        'Marker' => marker_symbol,
        'Status' => status,
        'Date Valid' => (date_early ? 'No':'Yes'),
        'Included' => (ok ? 'Yes':'No'),
        'Day' => day
      }

    end

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
              #pcentre = pcentre ? "&pcentre=#{pcentre}" : ''
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
            
            #            array.each { |name| string += "<td>#{make_clean.call status_hash[name].keys.size}</td>" }
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
  
  def self.get_plans
    
    csv_data = <<-"CSV"
"Year","Month","Day","Consortium","Centre","Gene Id","Marker Symbol","Status","Notes"
2012,1,1,"BaSH","BCM",2576,"Foxr2","Assigned - ES Cell QC In Progress",
2012,1,1,"BaSH","BCM",6815,"Rundc3a","Assigned - ES Cell QC Complete",
2012,1,1,"BaSH","BCM",11797,"Ascc2","Aborted - ES Cell QC Failed","Dummy!"
2010,1,1,"BaSH","BCM",11790,"1700006E09Rik","Assigned - ES Cell QC In Progress","Too old"
2011,11,11,"NorCOMM2","TCP",16170,"Clvs2","Aborted - ES Cell QC Failed","Wrong Consortium"
2010,3,3,"DTCC","UCD",2145,"Med28","Assigned","Not a status we care about"
    CSV

    parsed_data = CSV.parse(csv_data)
    
    return Ruport::Data::Table.new(
      :column_names => parsed_data[0],
      :data => parsed_data[1..-1]
    )
    
  end
    
  def self.get_attempts
    
    csv_data = <<-"CSV"
"Year","Month","Day","Consortium","Centre","Gene Id","Marker Symbol","Status","Notes"
2012,1,3,"BaSH","MRC - Harwell",2559,"Itga2","Genotype confirmed",
2012,1,17,"BaSH","MRC - Harwell",14712,"Boc","Micro-injection in progress",
2012,1,5,"BaSH","MRC - Harwell",1101,"Tex22","Micro-injection aborted","Dummy!"
2008,1,26,"BaSH","WTSI",14142,"Zfp282","Micro-injection in progress","Too old"
2012,1,3,"EUCOMM-EUMODIC","MRC - Harwell",2563,"Frs2","Genotype confirmed","Wrong Consortium"
    CSV

    parsed_data = CSV.parse(csv_data)
    
    return Ruport::Data::Table.new(
      :column_names => parsed_data[0],
      :data => parsed_data[1..-1]
    )
    
  end
    
  def self.get_phenotypes
    
    csv_data = <<-"CSV"
"Year","Month","Day","Consortium","Centre","Gene Id","Marker Symbol","Status","Notes"
2012,1,1,"DTCC","UCD",2489,"Nmur1","Phenotype Attempt Registered",
2012,1,1,"DTCC","UCD",2304,"Podxl2","Rederivation Started",
2012,1,1,"DTCC","UCD",2487,"1700003F12Rik","Rederivation Complete",
2012,1,1,"DTCC","UCD",2054,"Apof","Cre Excision Started",
2012,1,1,"DTCC","UCD",2499,"Rilp","Cre Excision Complete",
2012,1,1,"DTCC","UCD",2553,"Abo","Phenotyping Started",
2012,1,1,"DTCC","UCD",2095,"Svs2","Phenotyping Complete",
2012,1,1,"DTCC","UCD",2167,"P2ry13","Phenotype Attempt Aborted",
2010,1,31,"DTCC","UCD",14840,"Caskin2","Phenotype Attempt Registered","Too old"
2012,1,31,"NorCOMM2","TCP",14216,"Exoc8","Phenotype Attempt Registered","Wrong Consortium"
    CSV

    parsed_data = CSV.parse(csv_data)
    
    return Ruport::Data::Table.new(
      :column_names => parsed_data[0],
      :data => parsed_data[1..-1]
    )
    
  end
  
  def self.get_summary_new(consortia = nil)
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
    
    plans_table = get_plans
    
    puts plans_table.inspect

    for i in (0..plans_table.column('Year').size-1)

      year = plans_table.column('Year')[i].to_i
      month = plans_table.column('Month')[i].to_i
      day = plans_table.column('Day')[i].to_i
      
      m = "%02i" % month
      d = "%02i" % day
      
      puts "PLANS DATE: #{year}-#{m}-#{d}"

      next if consortia && Date.parse("#{year}-#{month}-#{day}") < Date.parse('2011-08-01')

      consortium = plans_table.column('Consortium')[i]
      pcentre = plans_table.column('Centre')[i]
      next if pcentre.blank? || pcentre.to_s.length < 1
      next if consortia && ! consortia.include?(consortium)
      gene_id = plans_table.column('Gene Id')[i]
      status = plans_table.column('Status')[i]
      marker_symbol = plans_table.column('Marker Symbol')[i]
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

    attempts_table = get_attempts

    puts attempts_table.inspect

    for i in (0..attempts_table.column('Year').size-1)

      year = attempts_table.column('Year')[i].to_i
      month = attempts_table.column('Month')[i].to_i
      day = attempts_table.column('Day')[i].to_i

      m = "%02i" % month
      d = "%02i" % day

      next if consortia && Date.parse("#{year}-#{m}-#{d}") < Date.parse('2011-08-01')

      consortium = attempts_table.column('Consortium')[i]
      pcentre = attempts_table.column('Centre')[i]
      next if pcentre.blank? || pcentre.to_s.length < 1
      next if consortia && ! consortia.include?(consortium)
      gene_id = attempts_table.column('Gene Id')[i]
      status = attempts_table.column('Status')[i]
      marker_symbol = attempts_table.column('Marker Symbol')[i]
          
      if(status == 'Micro-injection in progress')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = marker_symbol
      end
    
      if(status == 'Genotype confirmed')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = 
          summary[year][month][consortium][pcentre]['gc'][gene_id] = marker_symbol
      end
    
      if(status == 'Micro-injection aborted')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = marker_symbol
        summary[year][month][consortium][pcentre]['abort'][gene_id] = marker_symbol
      end
    
    end

    phenotypes_table = get_phenotypes

    puts phenotypes_table.inspect
    
    for i in (0..phenotypes_table.column('Year').size-1)

      year = phenotypes_table.column('Year')[i].to_i
      month = phenotypes_table.column('Month')[i].to_i
      day = phenotypes_table.column('Day')[i].to_i

      m = "%02i" % month
      d = "%02i" % day

      next if consortia && Date.parse("#{year}-#{month}-#{day}") < Date.parse('2011-08-01')

      puts "ADD PHENO DATE: #{year}-#{m}-#{d}"

      consortium = phenotypes_table.column('Consortium')[i]
      pcentre = phenotypes_table.column('Centre')[i]
      
      next if pcentre.blank?
      next if consortia && ! consortia.include?(consortium)
      gene_id = phenotypes_table.column('Gene Id')[i]
      status = phenotypes_table.column('Status')[i]
      marker_symbol = phenotypes_table.column('Marker Symbol')[i]

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
      
      if status == 'Phenotype Attempt Registered' ||
          status == 'Cre Excision Started' ||
          status == 'Cre Excision Complete' ||
          status == 'Phenotyping Started' ||
          status == 'Phenotyping Complete' ||
          status == 'Rederivation Started' ||
          status == 'Rederivation Complete' ||
          status == 'Phenotype Attempt Aborted'
        summary[year][month][consortium][pcentre]['Phenotype Attempt Registered'][gene_id] = marker_symbol
      end
              
    end

    return summary

  end

  def self.subsummary_new(params)
    
    #raise "subsummary_new: " + params.inspect
    
    consortium = params[:consortium]
    type = params[:type]
    #    type = type ? type.gsub(/^\#\s+/, "") : nil
    priority = params[:priority]
    pcentre = params[:pcentre]
    year = params[:year]
    month = params[:month]
    
    #    type = type
    
    summary = get_summary_new(params)
    
#    table = Table(["Year","Month","Consortium","Centre","Gene Id","Marker Symbol"]) #,"Status"])
    table = Table(["Year","Month","Consortium","Centre","Gene Id","Marker Symbol"]) #,"Status"])
    
    #        summary[year][month][consortium][pcentre]['Phenotype Attempt Registered'][gene_id] = 1
    
    #raise summary.inspect
    
    puts "subsummary_new: #{year} - #{month} - #{consortium} - #{pcentre} - #{type}"    

    summary[year.to_i][month.to_i][consortium][pcentre][type].keys.each do |key|
      table << {
        "Year" => year,"Month"=>month,"Consortium"=> consortium,"Centre"=>pcentre,"Gene Id"=>key,
        "Marker Symbol" => summary[year.to_i][month.to_i][consortium][pcentre][type][key]
        #,"Status"
      }
    end

    #raise params.inspect
    #raise summary.inspect
    #raise summary[year.to_i][month.to_i][consortium][pcentre].inspect
    
    return table
  end
  
  def self.get_summary_new(params)

    consortium = params[:consortium]
    type = params[:type]
    priority = params[:priority]
    pcentre = params[:pcentre]
    year = params[:year]
    month = params[:month]

    summary = get_summary_original(params)

    table = Table(["Year","Month","Consortium","Centre","Gene Id","Marker Symbol"]) #,"Status"])

    summary[year.to_i][month.to_i][consortium][pcentre][type].keys.each do |key|
      table << {
        "Year" => year,"Month"=>month,"Consortium"=> consortium,"Centre"=>pcentre,"Gene Id"=>key,
        "Marker Symbol" => summary[year.to_i][month.to_i][consortium][pcentre][type][key]
      }
    end

    return table
  end

  def self.get_summary_original(params)
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
    
    counter = {}
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
      
      counter[gene_id] ||= 0
      counter[gene_id] += 1
      
      ok = false
    
      if(status == 'Assigned - ES Cell QC In Progress')
        summary[year][month][consortium][pcentre]['es_qcs'][gene_id] = marker_symbol
        #puts "PLANS 1: #{year} - #{month} - #{consortium} - #{pcentre} - #{marker_symbol}"
        ok = true
      end
    
      if(status == 'Assigned - ES Cell QC Complete')
        summary[year][month][consortium][pcentre]['es_qcs'][gene_id] = marker_symbol
        summary[year][month][consortium][pcentre]['es_confirms'][gene_id] = marker_symbol
        #puts "PLANS 2: #{year} - #{month} - #{consortium} - #{pcentre} - #{marker_symbol}"
        ok = true
      end
    
      if(status == 'Aborted - ES Cell QC Failed')
        summary[year][month][consortium][pcentre]['es_qcs'][gene_id] = marker_symbol
        summary[year][month][consortium][pcentre]['es_fails'][gene_id] = marker_symbol
        puts "PLANS 3: #{year} - #{month} - #{consortium} - #{pcentre} - #{marker_symbol} = #{status}"
        puts stamp.inspect
        ok = true
      end
      
      date_early = stamp.created_at < Date.parse('2011-08-01')
         
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
      
      ok = false
    
      if(status == 'Micro-injection in progress')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = marker_symbol
        ok = true
      end
    
      if(status == 'Genotype confirmed')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = marker_symbol
        summary[year][month][consortium][pcentre]['gc'][gene_id] = marker_symbol
        ok = true
      end
    
      if(status == 'Micro-injection aborted')
        summary[year][month][consortium][pcentre]['mi'][gene_id] = marker_symbol
        summary[year][month][consortium][pcentre]['abort'][gene_id] = marker_symbol
        ok = true
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

      ok = false

      if status == 'Phenotype Attempt Aborted'
        summary[year][month][consortium][pcentre]['Phenotype Attempt Aborted'][gene_id] = marker_symbol
        ok = true
      end
    
      if status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Phenotyping Complete'][gene_id] = marker_symbol
        ok = true
      end
    
      if status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Phenotyping Started'][gene_id] = marker_symbol
        ok = true
      end
    
      if status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Cre Excision Complete'][gene_id] = marker_symbol
        ok = true
      end
    
      if status == 'Cre Excision Started' || status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Cre Excision Started'][gene_id] = marker_symbol
        ok = true
      end
    
      if status == 'Rederivation Started' || status == 'Rederivation Complete' || status == 'Cre Excision Started' || status == 'Cre Excision Complete' ||
          status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Rederivation Started'][gene_id] = marker_symbol
        ok = true
        #TODO: check
      end
    
      if status == 'Rederivation Complete' || status == 'Cre Excision Started' || status == 'Cre Excision Complete' ||
          status == 'Phenotyping Started' || status == 'Phenotyping Complete'
        summary[year][month][consortium][pcentre]['Rederivation Complete'][gene_id] = marker_symbol
        ok = true
        #TODO: check
      end
    
      if status == 'Phenotype Attempt Registered' || status == 'Cre Excision Started' || status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete' ||
          status == 'Rederivation Started' || status == 'Rederivation Complete' ||
          status == 'Phenotype Attempt Aborted'
        summary[year][month][consortium][pcentre]['Phenotype Attempt Registered'][gene_id] = marker_symbol
        ok = true
      end

    end

    return summary
  end

end
