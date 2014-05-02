class TargRep::HdrAllelesController < TargRep::AllelesController

  before_filter do
    @klass = TargRep::HdrAllele
    @title = 'HDR Allele'
    @allele_type = @klass.name.demodulize.underscore
    @new_path = new_targ_rep_hdr_allele_path
  end

  def hdr_allele?; true; end


end