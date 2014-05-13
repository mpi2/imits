class TargRep::GeneTrapsController < TargRep::AllelesController

  before_filter do
    @klass = TargRep::GeneTrap
    @title = 'Gene Trap Allele'
    @allele_type = @klass.name.demodulize.underscore
    @new_path = new_targ_rep_gene_trap_path
  end

  def gene_trap?; true; end

end