class PhenotypeAttempts::DistributionCentresController < DistributionCentresController

  ## See "app/controllers/distribution_cenres_controller.rb" for inherited actions.

  def find_class
    @klass = PhenotypeAttempt::DistributionCentre
    @table_name = 'phenotype_attempt_distribution_centres'
  end

end