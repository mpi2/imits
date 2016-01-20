class SlidingEfficiencyReport

  attr_accessor :mi_attempts, :total

  def initialize(category, consortium_name, production_centre_name)
    if category == 'crisprs'
      get_crispr_mi_attempts(consortium_name, production_centre_name)
    else
      get_mi_attempts(consortium_name, production_centre_name)
    end
  end

  def get_mi_attempts(consortium_name, production_centre_name)
    @mi_attempts = MiAttempt.includes(:es_cell => {:allele => :gene}, :plan => [:consortium, :production_centre])
      .order('mi_attempts.mi_date ASC, mi_attempts.id ASC')
      .where(:consortia => {:name => consortium_name}, :centres => {:name => production_centre_name})
      .where('mi_date <= :date', :date => 6.months.ago)

    @total = @mi_attempts.count

    @mi_attempts.each {|mi| mi.mi_date = mi.mi_date.beginning_of_month}

    nil
  end

  def get_crispr_mi_attempts(consortium_name, production_centre_name)
    @mi_attempts = MiAttempt.includes(:plan => [:consortium, :production_centre, :gene, :plan_intentions])
      .where("mi_attempts.status_id = 2 AND plan_intentions.intention_id = 4 AND consortia.name = '#{consortium_name}' AND centres.name = '#{production_centre_name}'")
      .order('mi_attempts.mi_date ASC, mi_attempts.id ASC')

    @total = @mi_attempts.count

    @mi_attempts.each {|mi| mi.mi_date = mi.mi_date.beginning_of_month}

    nil
  end

end