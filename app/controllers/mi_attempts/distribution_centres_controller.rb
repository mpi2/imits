class MiAttempts::DistributionCentresController < DistributionCentresController

  ## See "app/controllers/distribution_cenres_controller.rb" for inherited actions.

  def find_class
    @klass = MiAttempt::DistributionCentre
    @table_name = 'mi_attempt_distribution_centres'
    @parent_table_name = 'mi_attempts'
  end

end