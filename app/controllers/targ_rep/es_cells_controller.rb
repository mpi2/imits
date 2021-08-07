class TargRep::EsCellsController < TargRep::BaseController

  respond_to :xml, :json

  before_filter :authorize_admin_user!, :only => :destroy

  def index
    find_escells
    @es_cells = @search

    respond_to do |format|
      format.xml {respond_with @es_cells}
      format.json {respond_with @es_cells.to_json(TargRep::EsCell::JSON_OPTIONS)}
    end
  end

  def show
    find_escell

    respond_with @es_cell
  end

  def mart_search
    if ! params[:es_cell_name].blank?
      respond_with TargRep::EsCell.search(:name_cont => params[:es_cell_name]).result.limit(100),
        :methods => ['marker_symbol', 'pipeline_name']

    elsif ! params[:marker_symbol].blank?
      respond_with TargRep::EsCell.search(:allele_gene_marker_symbol_cont =>  params[:marker_symbol]).result.limit(100),
        :methods => ['marker_symbol', 'pipeline_name']

    else
      respond_with []
    end
  end

  def attributes
    render :json => create_attribute_documentation_for(TargRep::EsCell)
  end

  private
    def find_escell
      @es_cell = TargRep::EsCell.find params[:id]
    end

    def find_escells
      escell_params = params.dup

      # Just keep TargetingVector params.
      escell_params.delete "controller"
      escell_params.delete "action"
      escell_params.delete "format"
      escell_params.delete "page"
      escell_params.delete "per_page"
      escell_params.delete "utf8"

      params[:page] ||= 1
      params[:per_page] ||= 100

      @search = TargRep::EsCell.search(escell_params).result.paginate(:page => params[:page], :per_page => params[:per_page])
    end

end
