class TargRep::EsCellsController < TargRep::BaseController

  respond_to :xml, :json

  before_filter :authorize_admin_user!, :only => :destroy

  def index
    find_escells
    @es_cells = @search

    respond_with @es_cells
  end

  def show
    find_escell

    respond_with @es_cell
  end

  # POST /es_cells.xml
  # POST /es_cells.json
  def create
    @es_cell = TargRep::EsCell.new params[:es_cell]

    respond_to do |format|
      if @es_cell.save
        format.xml  { render :xml  => @es_cell, :status => :created, :location => @es_cell }
        format.json { render :json => @es_cell, :status => :created, :location => @es_cell }
      else
        format.xml  { render :xml  => @es_cell.errors, :status => 400 }
        format.json { render :json => @es_cell.errors, :status => 400 }
      end
    end
  end

  # PUT /es_cells/1.xml
  # PUT /es_cells/1.json
  def update
    find_escell

    respond_to do |format|
      if @es_cell.update_attributes params[:es_cell]
        format.xml  { render :xml  => @es_cell, :location => @es_cell }
        format.json { render :json => @es_cell, :location => @es_cell }
      else
        format.xml  { render :xml  => @es_cell.errors, :status => 400 }
        format.json { render :json => @es_cell.errors, :status => 400 }
      end
    end
  end

  # DELETE /es_cells/1.xml
  # DELETE /es_cells/1.json
  def destroy
    find_escell

    @es_cell.destroy

    respond_to do |format|
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

  # GET /es_cells/bulk_edit
  # POST /es_cells/bulk_edit
  def bulk_edit

    @bulk_edit = true

    unless params[:es_cell_names].blank?
      es_cell_names = params[:es_cell_names].split("\n").map{ |elm| elm.chomp.strip }.compact
      @es_cells = TargRep::EsCell.search(:name_in => es_cell_names).result
      @es_cells.sort!{ |a,b| es_cell_names.index(a.name) <=> es_cell_names.index(b.name) }

      @es_cells.each do |es_cell|
        es_cell.build_distribution_qc(current_user.es_cell_distribution_centre)
      end
    end

  end

  def update_multiple

    TargRep::EsCell.transaction do
      @distribution_qcs = TargRep::DistributionQc.update(params[:distribution_qcs].keys, params[:distribution_qcs].values).reject { |p| p.errors.empty? }
      @es_cells = TargRep::EsCell.update(params[:es_cells].keys, params[:es_cells].values).reject { |p| p.errors.empty? }
    end

    es_cell_names = ''
    if ! @es_cells.empty? || ! @distribution_qcs.empty?
      hash = {}
      @es_cells.each do |es_cell|
        hash[es_cell.name] = 1
      end
      @distribution_qcs.each do |distribution_qc|
        hash[distribution_qc.es_cell.name] = 1
      end
      hash.keys.each {|key| es_cell_names += "#{key}\n" }
    end

    if @es_cells.empty? && @distribution_qcs.empty?
      flash[:notice] = "ES Cells Updated"
      redirect_to :action => :bulk_edit
    else
      flash[:error] = "There was a problem updating some of your records - the failed entries are shown below"
      redirect_to :action => :bulk_edit, :es_cell_names => es_cell_names
    end
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
