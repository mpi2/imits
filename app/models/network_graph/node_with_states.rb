class NetworkGraph::NodeWithStates < NetworkGraph::Node
  def initialize(object, params)
    super(object, params)
    @consortium  = object.consortium.try(:name).to_s
    @centre = object.production_centre.try(:name).to_s
  end

  def find_statuses(object)
    @current_status = object.status.try(:name)
    @statuses = {}
    object.status_stamps.order("created_at DESC").each do |stamps|
      @statuses[stamps.name] = (!stamps.created_at.nil? ? (stamps.created_at.strftime "%d/%m/%Y") : '')
    end
  end
end
