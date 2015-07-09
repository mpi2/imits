class PhenotypeAttempts::DistributionCentresController < DistributionCentresController

  ## See "app/controllers/distribution_cenres_controller.rb" for inherited actions.

  def find_class
    @model_table_name = 'mouse_allele_mods'
    @status_id = [6, 7, 8]
  end

end