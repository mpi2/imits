class Reports::MiProduction::Detail
  def self.generate
    report = MiPlan.report_table(:all,
      :only => ['consortium.name'],
      :include => {
        :consortium => {:only => [:name]},
      }
    )

    report = MiPlan.report_table

    return report
  end
end
