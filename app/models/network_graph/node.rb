class NetworkGraph::Node

  def initialize(params={})
    @rank = params[:rank]
    @node_symbol = params[:symbol]
    @id = params[:id]
    @consortium  = params[:consortium]
    @centre = params[:centre]
    @url = params[:url]
  end

  def rank
    return @rank
  end

  def url
    return @url
  end

  def node_symbol
    return @node_symbol
  end
end
