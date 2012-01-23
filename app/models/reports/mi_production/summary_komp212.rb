# encoding: utf-8
 
class Reports::MiProduction::SummaryKomp212
  
  extend Reports::MiProduction::SummariesCommon
  extend Reports::MiProduction::SummaryKomp2Common

  DEBUG = Reports::MiProduction::SummaryKomp2Common::DEBUG
  ACCUMULATE = true
  CACHE_NAME = DEBUG ? 'mi_production_intermediate_test' : 'mi_production_intermediate'
  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS
  MAPPING_SUMMARIES = Reports::MiProduction::SummaryKomp2Common::MAPPING_SUMMARIES
  CONSORTIA = Reports::MiProduction::SummaryKomp2Common::CONSORTIA
  REPORT_TITLE = DEBUG ? "KOMP2 Report' - (DEBUG)" : "KOMP2 Report'"
  
  # if you re-order this, do same to 'headings_new' below

  HEADINGS = Reports::MiProduction::SummaryKomp2Common::HEADINGS
  IGNORE = Reports::MiProduction::SummaryKomp2Common::IGNORE

  def self.generate(request = nil, params={})
    
    if params[:consortium]
      title, report = subsummary_common(params)
      return title, report
    end

    heading = HEADINGS   
    report_table = Table(heading)

    summary1 = generate_common(request, params)

    summary1.each do |row|
        
      next if row['Production Centre'].to_s.length < 1
          
      counts = row

      if ACCUMULATE
        (HEADINGS.size-1).downto(1).each do |i|
          next if IGNORE.include? HEADINGS[i]
          puts "TRYING: '" + HEADINGS[i].to_s + "' 1: #{counts[HEADINGS[i]]}"
          puts "TRYING: '" + HEADINGS[i].to_s + "' 1: '#{counts[HEADINGS[i]]}' - 2: '#{counts[HEADINGS[i+1]]}'"
          counts[HEADINGS[i]] ||= 0
          counts[HEADINGS[i+1]] ||= 0
#          counts[HEADINGS[i]] += counts[HEADINGS[i+1]].to_i
          counts[HEADINGS[i]] = counts[HEADINGS[i]].to_i + counts[HEADINGS[i+1]].to_i
        end
      end

      row = ACCUMULATE ? counts : row

      pc = efficiency(request, row)
      pc2 = efficiency2(request, row)

        clean_value = lambda {|value|
          return value if request && request.format == :csv
          return '' if ! value || value.to_s == "0"
          return value
        }

      report_table << {
        'Consortium' => row['Consortium'],
        'Production Centre' => row['Production Centre'],
        'All' => clean_value.call(row['All']),
        'ES QC started' => clean_value.call(row['ES QC started']),
        'ES QC confirmed' => clean_value.call(row['ES QC confirmed']),
        'ES QC failed' => clean_value.call(row['ES QC failed']),
        'MI in progress' => clean_value.call(row['MI in progress']),
        'Genotype Confirmed Mice' => clean_value.call(row['Genotype Confirmed Mice']),
        'MI Aborted' => clean_value.call(row['MI Aborted']),
        'Languishing' => clean_value.call(row['Languishing']),
        'Registered for Phenotyping' => clean_value.call(row['Registered for Phenotyping']),
        'Distinct Genotype Confirmed ES Cells' => clean_value.call(row['Distinct Genotype Confirmed ES Cells']),
        'Distinct Old Non Genotype Confirmed ES Cells' => clean_value.call(row['Distinct Old Non Genotype Confirmed ES Cells']),
        'Pipeline efficiency (%)' => clean_value.call(pc),
        'Pipeline efficiency (by clone)' => clean_value.call(pc2),
            
        'Phenotyping Started' => clean_value.call(row['Phenotyping Started']),
        'Rederivation Started' => clean_value.call(row['Rederivation Started']),
        'Rederivation Complete' => clean_value.call(row['Rederivation Complete']),
        'Cre Excision Started' => clean_value.call(row['Cre Excision Started']),
        'Cre Excision Complete' => clean_value.call(row['Cre Excision Complete']),
        'Phenotyping Complete' => clean_value.call(row['Phenotyping Complete']),
        'Phenotype Attempt Aborted' => clean_value.call(row['Phenotype Attempt Aborted'])
      }
        
    end

    #headings_new = ['Consortium', 'Production Centre',
    #  'All',
    #  'ES QC started or better',
    #  'ES QC confirmed or better',
    #  'MI in progress or better',
    #  #'Chimaeras or better',
    #  'Genotype Confirmed Mice or better',
    #  'Registered for Phenotyping or better',
    #  'Phenotyping Started or better',
    #  'Rederivation Started or better',
    #  'Rederivation Complete or better',
    #  'Cre Excision Started or better',
    #  'Cre Excision Complete or better',
    #  'Phenotyping Complete',
    #  'ES QC failed',
    #  'MI Aborted',
    #  'Phenotype Attempt Aborted',
    #  #              'Pipeline efficiency (%)',
    #  #              'Pipeline efficiency (by clone)'
    #]
    #
    #report_table.rename_columns(HEADINGS, headings_new)

    report_table.remove_columns('Pipeline efficiency (%)', 'Pipeline efficiency (by clone)')
    
    report_table.column_names.each do |name|
      next if ['Consortium','Production Centre','All'].include? name
      next if /failed|Aborted/.match(name)
      report_table.rename_column(name, name + ' or better')
    end

    return REPORT_TITLE, report_table
  end

end
