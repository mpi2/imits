class GenesController < ApplicationController
  respond_to :json
  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def draw_network_graph
    gene = Genes.find_by_id(params[:id])
    network_graph = gene.draw_network_graph
    send_data network_graph, :type => 'svg', :filename => 'network_graph', :disposition => 'inline'
  end
  private

  def data_for_serialized(format)
    super(format, 'marker_symbol', Gene, :search)
  end

end
