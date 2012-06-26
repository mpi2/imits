# encoding: utf-8

class Reports::MiProduction::SummaryMonthByMonthActivityKomp2Compressed < Reports::MiProduction::SummaryMonthByMonthActivityImpc

  CUT_OFF_DATE = Date.parse('2011-06-01')

  def self.report_name; 'summary_month_by_month_activity_komp2'; end
  def self.report_title; 'KOMP2 Summary Month by Month'; end
  def self.consortia; ['BaSH', 'DTCC', 'JAX']; end
  def self.states; [['ES Cell QC In Progress','assigned_es_cell_qc_in_progress_date'],['ES Cell QC Complete', 'assigned_es_cell_qc_complete_date'], ['ES Cell QC Failed'],['Micro-injection in progress'],['Chimeras obtained'],['Genotype confirmed'],['Micro-injection aborted'],['Phenotype Attempt Registered'],['Rederivation Started'],['Rederivation Complete'],['Cre Excision Started'],['Cre Excision Complete'],['Phenotyping Started'],['Phenotyping Complete'],['Phenotype Attempt Aborted']]; end

  def initialize
    generated = self.class.generate :komp2 => true
    @csv = generated[:csv]
    @html = generated[:html]
  end

  def generate
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
    time = Time.now
    while time >= CUT_OFF_DATE
      year, month = convert_date(time)
      self.consortium.each do |consortium|
        self.states.each do |state|
          summary [year][month][consortium][state[0]]
        end
      end
      time = time.new(year,month -1, 1)
    end

    summary = IntermediateReport.all
    summary.each do |miplanrec|
      self.states.each do |state|
        if miplanrec in self.consortia
          if
          miplanrec.mi_plan_status == 'Aborted' and ()
          miplanrec.mi_attempt_status == 'Aborted' and ()
          miplanrec.phenotype_attempt_status == 'Aborted' and ()


            date = miplanrec[state[1]]
            if date != nil
              year, month = convert_date(date)
              consortium = miplanrec.consortium
              if summary [year][month][consortium].haskey?(state[0])
                summary [year][month][consortium][state[0]] += 1
              else
              summary [year][month][consortium][state[0]] = 0
              end
            end
          end
        end
      end
  end

  def convert_date (stamp)
    year = stamp.created_at.year
    month = stamp.created_at.month
    day = stamp.created_at.day
    [year,month,day]
  end

end
