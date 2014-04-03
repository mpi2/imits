class TargRep::CrisprTargetedAllelesController < TargRep::AllelesController

  respond_to :html, :xml, :json, :except => [:update, :create, :edit, :new]


  before_filter do
    @klass = TargRep::CrisprTargetedAllele
    @title = 'Crispr Targeted Allele'
    @allele_type = @klass.name.demodulize.underscore
    @new_path = new_targ_rep_crispr_targeted_allele_path
  end

  def nhej_allele?; true; end


end