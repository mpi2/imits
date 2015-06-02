class MiAttempts::DistributionCentresController < DistributionCentresController

  ## See "app/controllers/distribution_cenres_controller.rb" for inherited actions.

  def find_class
    @model_table_name = 'mi_attempts'
    @status_id = [2]
  end

end