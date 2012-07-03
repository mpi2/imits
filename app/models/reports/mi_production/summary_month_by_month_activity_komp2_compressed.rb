# encoding: utf-8

class Reports::MiProduction::SummaryMonthByMonthActivityKomp2Compressed < Reports::Base

  CUT_OFF_DATE = Date.parse('2011-06-01')

  def self.report_name; 'summary_month_by_month_activity_komp2_compressed'; end
  def self.report_title; 'KOMP2 Summary Month by Month Compressed'; end
  def self.consortia; ['BaSH', 'DTCC', 'JAX']; end
  def self.states; [['ES Cell QC In Progress','assigned_es_cell_qc_in_progress_date'],['ES Cell QC Complete', 'assigned_es_cell_qc_complete_date'], ['ES Cell QC Failed', 'aborted_es_cell_qc_failed_date'],['Micro-injection in progress', 'micro_injection_in_progress_date'],['Chimeras obtained', 'chimeras_obtained_date'],['Genotype confirmed', 'genotype_confirmed_date'],['Micro-injection aborted','micro_injection_aborted_date'],['Phenotype Attempt Registered','phenotype_attempt_registered_date'],['Rederivation Started','rederivation_started_date'],['Rederivation Complete', 'rederivation_complete_date'],['Cre Excision Started','cre_excision_started_date'],['Cre Excision Complete','cre_excision_complete_date'],['Phenotyping Started','phenotyping_started_date'],['Phenotyping Complete','phenotyping_complete_date'],['Phenotype Attempt Aborted','phenotype_attempt_aborted_date']]; end

  def initialize
    generated = self.class.generate
    @data = self.class.format(generated)
   # @csv = self.to_csv(@data)
  end

  def data
    return @data
  end

  def self.generate
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
    time = CUT_OFF_DATE
    while time <= Time.now.to_date
      year, month = convert_date(time)
      self.consortia.each do |consortium|
        self.states.each do |state|
          summary [consortium][year][month][consortium][state[0]] = 0
        end
      end
      time = time.next_month
    end

    data = IntermediateReport.all
    data.each do |miplanrec|
      next if !self.consortia.include?(miplanrec.consortium)
      self.states.each do |state|
        date = miplanrec[state[1]]
        next if date == nil
        year, month = convert_date(date)
        consortium = miplanrec.consortium
        summary [consortium][year][month][consortium][state[0]] += 1
      end
    end
    return summary
  end

  def self.convert_date (stamp)
    year = stamp.year
    month = stamp.month
    day = stamp.day
    [year,month,day]
  end

  def self.format(summary)
    require 'yaml'
    goal_data = YAML.load_file('config/report_production_goals.yml')
    print goal_data
    dataset ={}
    summary.each do |consortiumindex, convalue|
      dataset[consortiumindex]={}
      dataset[consortiumindex]['mi_attempt_data']=[]
      dataset[consortiumindex]['phenotype_data']=[]
      es_starts_sum = 0
      mis_sum = 0
      mi_goal = 0
      genotype_confirm_sum = 0
      gc_goal_sum = 0
      convalue.each do |yearindex, yearvalue|
        span = yearvalue.count
        year = yearindex
        monthcount = 0
        yearvalue.each do |monthindex, monthvalue|
          month = monthindex
          monthvalue.each do |consortium2index, data|
            monthcount += 1

            consortium = consortium2index
            record = {}
            record['year'] = year
            record['yearspan'] = span
            record['firstrow'] = (monthcount == span  ? true : false)
            record['month'] = month
            record['consortium'] = consortium
            record['cumulative_es_starts'] = es_starts_sum += data['ES Cell QC In Progress']
            record['es_cell_qc_in_progress'] = data['ES Cell QC In Progress']
            record['es_cell_qc_complete'] = data['ES Cell QC Complete']
            record['es_cell_qc_failed'] = data['ES Cell QC Failed']
            record['micro_injection_in_progress'] = data['Micro-injection in progress']
            record['cumulative_mis'] = mis_sum += data['Micro-injection in progress']
            record['mi_goal'] = (goal_data['summary_month_by_month'][consortium][year].has_key?(month) ? goal_data['summary_month_by_month'][consortium][year][month]['mi_goals'] : 0)
            record['chimeras_obtained'] = data['Chimeras obtained']
            record['genotype_confirmed'] = data['Genotype confirmed']
            record['cumulative_genotype_confirmed'] = genotype_confirm_sum += data['Genotype confirmed']
            record['gc_goal'] = (goal_data['summary_month_by_month'][consortium][year].has_key?(month) ? goal_data['summary_month_by_month'][consortium][year][month]['gc_goals'] : 0)
            record['micro_injection_aborted'] = data['Micro-injection aborted']
            dataset[consortiumindex]['mi_attempt_data'] << record
            record = {}
            record['year'] = year
            record['yearspan'] = span
            record['firstrow'] = (monthcount == span  ? true : false)
            record['month'] = month
            record['consortium'] = consortium
            record['phenotype_attempt_registered'] = data['Phenotype Attempt Registered']
            record['rederivation_started'] = data['Rederivation Started']
            record['rederivation_complete'] = data['Rederivation Complete']
            record['cre_excision_started'] = data['Cre Excision Started']
            record['cre_excision_complete'] = data['Cre Excision Complete']
            record['phenotyping_started'] = data['Phenotyping Started']
            record['phenotyping_complete'] = data['Phenotyping Complete']
            record['phenotype_attempt_aborted'] = data['Phenotype Attempt Aborted']
            dataset[consortiumindex]['phenotype_data'] << record

          end
        end
      end
      dataset[consortiumindex]['mi_attempt_data'] = dataset[consortiumindex]['mi_attempt_data'].reverse
      dataset[consortiumindex]['phenotype_data'] = dataset[consortiumindex]['phenotype_data'].reverse
    end
  return dataset
  end
end
