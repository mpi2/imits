class NetworkGraph::NodeWithStates < NetworkGraph::Node
  def initialize(params)
    super(params)
  end

  def find_statuses(status_stamps)
    @statuses = {}
    status_stamps.each do |stamps|
      @statuses[stamps.status.name] = (!stamps.status.created_at.nil? ? (stamps.status.created_at.strftime "%d/%m/%Y") : '')
    end
  end
end
