# encoding: utf-8

class Reports::MiProduction::SummaryMonthByMonthActivityKomp2Compressed < Reports::Base

  CUT_OFF_DATE = Date.parse('2011-06-01')

  def self.report_name; 'summary_month_by_month_activity_komp2_compressed'; end
  def self.report_title; 'KOMP2 Summary Month by Month Compressed'; end
  def self.consortia; ['BaSH', 'DTCC', 'JAX']; end
  def self.states; [['ES Cell QC In Progress','assigned_es_cell_qc_in_progress_date'],['ES Cell QC Complete', 'assigned_es_cell_qc_complete_date'], ['ES Cell QC Failed', 'updated_at'],['Micro-injection in progress', 'micro_injection_in_progress_date'],['Chimeras obtained', 'chimeras_obtained_date'],['Genotype confirmed', 'genotype_confirmed_date'],['Micro-injection aborted','micro_injection_aborted_date'],['Phenotype Attempt Registered','phenotype_attempt_registered_date'],['Rederivation Started','rederivation_started_date'],['Rederivation Complete', 'rederivation_complete_date'],['Cre Excision Started','cre_excision_started_date'],['Cre Excision Complete','cre_excision_complete_date'],['Phenotyping Started','phenotyping_started_date'],['Phenotyping Complete','phenotyping_complete_date'],['Phenotype Attempt Aborted','phenotype_attempt_aborted_date']]; end

  def initialize
    puts 'hello'
    generated = self.class.generate #:komp2 => true
#    @csv = generated[:csv]
#    @html = generated[:html]
  end

  def self.generate
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
    time = Time.now
    while time >= CUT_OFF_DATE
      year, month = convert_date(time)
      self.consortia.each do |consortium|
        self.states.each do |state|
          summary [consortium][year][month][state[0]] = 0
        end
      end
      time = time.prev_month
    end

    data = IntermediateReport.all
    data.each do |miplanrec|
      next if !self.consortia.include?(miplanrec.consortium)
      self.states.each do |state|
        date = miplanrec[state[1]]
        next if date == nil
        year, month = convert_date(date)
        consortium = miplanrec.consortium
        summary [consortium][year][month][state[0]] += 1
      end
    end
    return summary
    #html = self.convert_to_html(summary)
  end

  def self.convert_date (stamp)
    year = stamp.year
    month = stamp.month
    day = stamp.day
    [year,month,day]
  end

#  def self.convert_to_html(summary)
#    states = self.states
#    string = '<table>'
#    summary.keys & states
#    summary.each do |key, value|


#      if state.include?(key)

#      string += '<tr>'

#      string += '</tr>'
#    end
#    string += '</table>'
#  end

end
