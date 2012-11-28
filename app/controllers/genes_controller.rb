class GenesController < ApplicationController
  respond_to :json
  before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token, :only => :autocomplete

  def index
    respond_to do |format|
      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def network_graph
    gene = Gene.find_by_id(params[:id])
    if !gene.nil?
      dot_file = NetworkGraph.new(gene.id).dot_file
      gv=IO.popen("dot -q -Tpng","w+")
      gv.puts dot_file
      gv.close_write
      data = gv.read
      send_data data,
        :filename => "#{gene.marker_symbol}network_graph.png?#{Time.now.strftime "%d%m%Y%H%M%S"}",
        :type => 'image/png',
        :disposition => 'inline'
    end
  end

  private

  def data_for_serialized(format)
    super(format, 'marker_symbol', Gene, :search)
  end
end
