class TargRep::GeneTrapsController < TargRep::AllelesController

  before_filter do
    @klass = TargRep::GeneTrap
    @title = 'Gene Trap Allele'
  end

  def gene_trap?; true; end

end