class TargRep::NhejAllelesController < TargRep::AllelesController

  respond_to :html, :xml, :json, :except => [:update, :create, :edit, :new]


  before_filter do
    @klass = TargRep::NhejAllele
    @title = 'NHEJ Allele'
    @allele_type = @klass.name.demodulize.underscore
  end

  def nhej_allele?; true; end


end