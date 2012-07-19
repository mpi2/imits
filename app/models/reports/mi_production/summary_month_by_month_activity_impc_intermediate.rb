# encoding: utf-8

class Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediate < Reports::Base

  def self.report_name; 'summary_month_by_month_activity_komp2_compressed'; end
  def self.report_title; 'IMPC Summary Month by Month'; end
  def self.consortia
    cons = []
    Consortium.order("name").each do |consortium|
      cons << consortium['name']
    end
    return cons
  end
  def self.states; {'ES Cell QC In Progress'=>'assigned_es_cell_qc_in_progress_date', 'ES Cell QC Complete'=> 'assigned_es_cell_qc_complete_date', 'ES Cell QC Failed'=> 'aborted_es_cell_qc_failed_date', 'Micro-injection in progress'=> 'micro_injection_in_progress_date', 'Chimeras obtained'=> 'chimeras_obtained_date', 'Genotype confirmed'=> 'genotype_confirmed_date', 'Micro-injection aborted'=>'micro_injection_aborted_date', 'Phenotype Attempt Registered'=>'phenotype_attempt_registered_date', 'Rederivation Started'=>'rederivation_started_date', 'Rederivation Complete'=> 'rederivation_complete_date', 'Cre Excision Started'=>'cre_excision_started_date', 'Cre Excision Complete'=>'cre_excision_complete_date', 'Phenotyping Started'=>'phenotyping_started_date', 'Phenotyping Complete'=>'phenotyping_complete_date', 'Phenotype Attempt Aborted'=>'phenotype_attempt_aborted_date'}; end

  def initialize
    generated = self.class.generate
    @data = self.class.format(generated)
    @csv = to_csv
  end

  def data
    return @data
  end

  def csv
    return @csv
  end

  def self.generate
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
    time = CUT_OFF_DATE
    cons = self.consortia.dup
    while time <= Time.now.to_date
      year, month = convert_date(time)
      cons.each do |consortium|
        summary [consortium]['empty']= true
        self.states.each do |state, name|
          summary [consortium]['data'][year][month][consortium][state] = 0
        end
      end
      time = time.next_month
    end
    data = IntermediateReport.all
    data.each do |miplanrec|
      next if !cons.include?(miplanrec.consortium)
      self.states.each do |state, name|
        date = miplanrec[name]
        next if date == nil or date < CUT_OFF_DATE
        year, month = convert_date(date)
        consortium = miplanrec.consortium
        summary [consortium]['data'][year][month][consortium][state] += 1
        summary [consortium]['empty'] = false
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
    goal_data = YAML.load_file('config/report_production_goals.yml')
    dataset ={}
    summary.each do |consortiumindex, condata|
      if condata['empty']
        puts consortiumindex
      end
      next if condata['empty']
      convalue = condata['data']
      dataset[consortiumindex]={}
      dataset[consortiumindex]['mi_attempt_data']=[]
      dataset[consortiumindex]['phenotype_data']=[]
      assigned_date_sum = 0
      es_starts_sum = 0
      es_complete_sum = 0
      es_failed_sum = 0
      mis_sum = 0
      genotype_confirm_sum = 0
      mi_goal = 0
      gc_goal_sum = 0
      phenotype_reg_sum = 0
      cre_excision_completed_sum = 0
      phenotype_complete_sum = 0
      state = self.states
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
            state.has_key?('Assigned Date') ? record['assigned_date'] = data['Assigned Date'] : 0
            state.has_key?('ES Cell QC In Progress') ? record['es_cell_qc_in_progress'] = data['ES Cell QC In Progress'] : 0
            state.has_key?('ES Cell QC Complete') ? record['es_cell_qc_complete'] = data['ES Cell QC Complete'] : 0
            state.has_key?('ES Cell QC Failed') ? record['es_cell_qc_failed'] = data['ES Cell QC Failed'] : 0
            state.has_key?('Micro-injection in progress') ? record['micro_injection_in_progress'] = data['Micro-injection in progress'] : 0
            state.has_key?('Chimeras obtained') ? record['chimeras_obtained'] = data['Chimeras obtained'] : 0
            state.has_key?('Genotype confirmed') ? record['genotype_confirmed'] = data['Genotype confirmed'] : 0
            state.has_key?('Micro-injection aborted') ? record['micro_injection_aborted'] = data['Micro-injection aborted'] : 0
            state.has_key?('Assigned Date') ? record['cummulative_assigned_date'] = assigned_date_sum += data['Assigned Date'] : 0
            state.has_key?('ES Cell QC In Progress') ? record['cumulative_es_starts'] = es_starts_sum += data['ES Cell QC In Progress'] : 0
            state.has_key?('ES Cell QC Complete') ? record['cumulative_es_complete'] = es_complete_sum += data['ES Cell QC Complete'] : 0
            state.has_key?('ES Cell QC Failed') ? record['cumulative_es_failed'] = es_failed_sum += data['ES Cell QC Failed'] : 0
            state.has_key?('Micro-injection in progress') ? record['cumulative_mis'] = mis_sum += data['Micro-injection in progress'] : 0
            state.has_key?('Genotype confirmed') ? record['cumulative_genotype_confirmed'] = genotype_confirm_sum += data['Genotype confirmed'] : 0
            if goal_data['summary_month_by_month'].has_key?(consortium)
              record['mi_goal'] = (goal_data['summary_month_by_month'][consortium][year].has_key?(month) ? goal_data['summary_month_by_month'][consortium][year][month]['mi_goals'] : 0)
              record['gc_goal'] = (goal_data['summary_month_by_month'][consortium][year].has_key?(month) ? goal_data['summary_month_by_month'][consortium][year][month]['gc_goals'] : 0)
            else
              record['mi_goal'] = 0
              record['gc_goal'] = 0
            end
            dataset[consortiumindex]['mi_attempt_data'] << record

            record = {}
            record['year'] = year
            record['yearspan'] = span
            record['firstrow'] = (monthcount == span  ? true : false)
            record['month'] = month
            record['consortium'] = consortium
            state.has_key?('Phenotype Attempt Registered') ? record['phenotype_attempt_registered'] = data['Phenotype Attempt Registered'] : 0
            state.has_key?('Rederivation Started') ? record['rederivation_started'] = data['Rederivation Started'] : 0
            state.has_key?('Rederivation Complete') ? record['rederivation_complete'] = data['Rederivation Complete'] : 0
            state.has_key?('Cre Excision Started') ? record['cre_excision_started'] = data['Cre Excision Started'] : 0
            state.has_key?('Cre Excision Complete') ? record['cre_excision_complete'] = data['Cre Excision Complete'] : 0
            state.has_key?('Phenotyping Started') ? record['phenotyping_started'] = data['Phenotyping Started'] : 0
            state.has_key?('Phenotyping Complete') ? record['phenotyping_complete'] = data['Phenotyping Complete'] : 0
            state.has_key?('Phenotype Attempt Aborted') ? record['phenotype_attempt_aborted'] = data['Phenotype Attempt Aborted'] : 0

            state.has_key?('Phenotype Attempt Registered') ? record['cumulative_phenotype_registered'] = phenotype_reg_sum += data['Phenotype Attempt Registered'] : 0
            state.has_key?('Cre Excision Complete') ? record['cumulative_cre_excision_complete'] = cre_excision_completed_sum += data['Cre Excision Complete'] : 0
            state.has_key?('Phenotyping Complete') ? record['cumulative_phenotyping_complete'] = phenotype_complete_sum += data['Phenotyping Complete'] : 0
            dataset[consortiumindex]['phenotype_data'] << record

          end
        end
      end
      dataset[consortiumindex]['mi_attempt_data'] = dataset[consortiumindex]['mi_attempt_data'].reverse
      dataset[consortiumindex]['phenotype_data'] = dataset[consortiumindex]['phenotype_data'].reverse
    end
  return dataset
  end

  def to_csv
    csv_headers = ['Date','Year','Month', 'Consortium', 'Cumulative ES Starts', 'ES Cell QC In Progress', 'ES Cell QC Complete', 'ES Cell QC Failed', 'Micro-Injection In Progress', 'Cumulative MIs', 'MI Goal', 'Chimeras obtained' , 'Genotype confirmed', 'Cumulative Genotype Confirmed', 'GC Goal','Micro-injection aborted', 'Phenotype Attempt Registered', 'Rederivation Started', 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete', 'Phenotyping Started', 'Phenotyping Complete', 'Phenotype Attempt Aborted']
    require 'csv'
    csv_string = csv_headers.to_csv
    @data.each do |consortium, consdata|
      (0...consdata['mi_attempt_data'].count).to_a.each do |rowno|
        data = consdata['mi_attempt_data'][rowno]
        data.update(consdata['phenotype_data'][rowno])
        rowdata = []
        rowdata << "#{Date::MONTHNAMES[data['month']]}-#{data['year']}"
        rowdata << data['year']
        rowdata << data['month']
        rowdata << data['consortium']
        rowdata << data['cumulative_es_starts']
        rowdata << data['es_cell_qc_in_progress']
        rowdata << data['es_cell_qc_complete']
        rowdata << data['es_cell_qc_failed']
        rowdata << data['micro_injection_in_progress']
        rowdata << data['cumulative_mis']
        rowdata << data['mi_goal']
        rowdata << data['chimeras_obtained']
        rowdata << data['genotype_confirmed']
        rowdata << data['cumulative_genotype_confirmed']
        rowdata << data['gc_goal']
        rowdata << data['micro_injection_aborted']
        rowdata << data['phenotype_attempt_registered']
        rowdata << data['rederivation_started']
        rowdata << data['rederivation_complete']
        rowdata << data['cre_excision_started']
        rowdata << data['cre_excision_complete']
        rowdata << data['phenotyping_started']
        rowdata << data['phenotyping_complete']
        rowdata << data['phenotype_attempt_aborted']
        csv_string += rowdata.to_csv
      end
    end
    return csv_string
  end
end
