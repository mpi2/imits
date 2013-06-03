class SlidingEfficiencyReport

  attr_accessor :mi_attempts, :total

  def initialize(consortium_name, production_centre_name)
    get_mi_attempts(consortium_name, production_centre_name)
  end

  def get_mi_attempts(consortium_name, production_centre_name)
    @mi_attempts = MiAttempt.joins('JOIN mi_plans ON mi_attempts.mi_plan_id = mi_plans.id', 'JOIN consortia ON mi_plans.consortium_id = consortia.id', 'JOIN centres ON mi_plans.production_centre_id = centres.id')
      .order('mi_attempts.mi_date ASC, mi_attempts.id ASC')
      .where(:consortia => {:name => consortium_name}, :centres => {:name => production_centre_name})
      .where('mi_date <= :date', :date => 6.months.ago)

    @total = @mi_attempts.count

    @mi_attempts.each {|mi| mi.mi_date = mi.mi_date.beginning_of_month}

    nil
  end

  def dates
    (mi_attempts.keys.first...mi_attempts.keys.last).to_a
  end

end