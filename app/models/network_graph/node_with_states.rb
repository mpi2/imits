class NetworkGraph::NodeWithStates < NetworkGraph::Node
  def initialize(params)
    super(params)
  end

  def find_statuses(object)
    @current_status = object.status.name
    @statuses = {}
    object.status_stamps.order("created_at DESC").each do |stamps|
      @statuses[stamps.name] = (!stamps.created_at.nil? ? (stamps.created_at.strftime "%d/%m/%Y") : '')
    end
  end
end
