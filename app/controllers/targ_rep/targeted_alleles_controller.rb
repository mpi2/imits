class TargRep::TargetedAllelesController < TargRep::AllelesController

  ## See TargRep::AllelesController
  before_filter do
    @klass = TargRep::TargetedAllele
    @title = 'Targeted Allele'
    @allele_type = @klass.name.demodulize.underscore
    @new_path = new_targ_rep_targeted_allele_path
  end

  def targeted_allele?; true; end
end