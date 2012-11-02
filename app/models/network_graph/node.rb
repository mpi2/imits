class NetworkGraph::Node

  def initialize(object, params={})
    @rank = params[:rank]
    @node_symbol = params[:symbol]
    @id = object.id
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
