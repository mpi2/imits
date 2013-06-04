class SlidingEfficiencyReport

  attr_accessor :mi_attempts, :total

  def initialize(consortium_name, production_centre_name)
    get_mi_attempts(consortium_name, production_centre_name)
  end

  def get_mi_attempts(consortium_name, production_centre_name)
    @mi_attempts = MiAttempt.includes(:es_cell => {:allele => :gene}, :mi_plan => [:consortium, :production_centre])
      .order('mi_attempts.mi_date ASC, mi_attempts.id ASC')
      .where(:consortia => {:name => consortium_name}, :centres => {:name => production_centre_name})
      .where('mi_date <= :date', :date => 6.months.ago)

    @total = @mi_attempts.count

    @mi_attempts.each {|mi| mi.mi_date = mi.mi_date.beginning_of_month}

    nil
  end

end