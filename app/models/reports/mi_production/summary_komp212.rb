# encoding: utf-8
 
class Reports::MiProduction::SummaryKomp212
  
  extend Reports::MiProduction::SummariesCommon
  extend Reports::MiProduction::SummaryKomp2Common

  DEBUG = false
  ACCUMULATE = true
  CACHE_NAME = DEBUG ? 'mi_production_intermediate_test' : 'mi_production_intermediate'
  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS
  MAPPING_SUMMARIES = Reports::MiProduction::SummaryKomp2Common::MAPPING_SUMMARIES
  CONSORTIA = Reports::MiProduction::SummaryKomp2Common::CONSORTIA
  REPORT_TITLE = DEBUG ? "KOMP2 Report' - alternate (DEBUG)" : "KOMP2 Report' - alternate"
  
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

      (HEADINGS.size-1).downto(1).each do |i|
        next if IGNORE.include? HEADINGS[i]
        counts[HEADINGS[i]] ||= 0
        counts[HEADINGS[i]] += counts[HEADINGS[i+1]]
      end

      counts = ACCUMULATE ? counts : row

      pc = efficiency(request, row)
      pc2 = efficiency2(request, row)

      report_table << {
        'Consortium' => row['Consortium'],
        'Production Centre' => row['Production Centre'],
        'All' => row['All'],
        'ES QC started' => row['ES QC started'],
        'ES QC confirmed' => row['ES QC confirmed'],
        'ES QC failed' => row['ES QC failed'],
        'MI in progress' => row['MI in progress'],
        'Genotype Confirmed Mice' => row['Genotype Confirmed Mice'],
        'MI Aborted' => row['MI Aborted'],
        'Languishing' => row['Languishing'],
        'Registered for Phenotyping' => row['Registered for Phenotyping'],
        'Distinct Genotype Confirmed ES Cells' => row['Distinct Genotype Confirmed ES Cells'],
        'Distinct Old Non Genotype Confirmed ES Cells' => row['Distinct Old Non Genotype Confirmed ES Cells'],
        'Pipeline efficiency (%)' => pc,
        'Pipeline efficiency (by clone)' => pc2,
            
        'Phenotyping Started' => row['Phenotyping Started'],
        'Rederivation Started' => row['Rederivation Started'],
        'Rederivation Complete' => row['Rederivation Complete'],
        'Cre Excision Started' => row['Cre Excision Started'],
        'Cre Excision Complete' => row['Cre Excision Complete'],
        'Phenotyping Complete' => row['Phenotyping Complete'],
        'Phenotype Attempt Aborted' => row['Phenotype Attempt Aborted']
      }
        
    end

    headings_new = ['Consortium', 'Production Centre',
      'All',
      'ES QC started or better',
      'ES QC confirmed or better',
      'MI in progress or better',
      #'Chimaeras or better',
      'Genotype Confirmed Mice or better',
      'Registered for Phenotyping or better',
      'Phenotyping Started or better',
      'Rederivation Started or better',
      'Rederivation Complete or better',
      'Cre Excision Started or better',
      'Cre Excision Complete or better',
      'Phenotyping Complete',
      'ES QC failed',
      'MI Aborted',
      'Phenotype Attempt Aborted',
      #              'Pipeline efficiency (%)',
      #              'Pipeline efficiency (by clone)'
    ]
  
    report_table.rename_columns(HEADINGS, headings_new)

    return REPORT_TITLE, report_table
  end

end
