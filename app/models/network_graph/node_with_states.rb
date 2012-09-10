class NetworkGraph::NodeWithStates < NetworkGraph::Node
  def initialize(params)
    super(params)
  end

  def find_statuses(status_stamps)
    @statuses = {}
    status_stamps.each do |stamps|
      @statuses[stamps.name] = (!stamps.created_at.nil? ? (stamps.created_at.strftime "%d/%m/%Y") : '')
    end
  end
end
