class NetworkGraph::MiPlanNode < NetworkGraph::NodeWithStates
  def initialize(params)
    params[:rank] = "2"
    super(params)
    find_statuses(MiPlan.find_by_id(@id).status_stamps.order("created_at DESC"))
  end

  def label_html
    html = "<<table> " +
             "<tr><td colspan=\"2\">Mi Plan</td></tr>" +
             "<tr><td>Consortium:</td><td>#{CGI.escapeHTML(@consortium)}</td></tr>" +
             "<tr><td>Centre:</td><td>#{CGI.escapeHTML(@centre)}</td></tr>"
    ['Assigned', 'Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Aborted - ES Cell QC Failed'].each do |status|
      if @statuses.has_key?(status)
        html << "<tr><td>#{CGI.escapeHTML(status)}:</td><td>#{CGI.escapeHTML(@statuses[status])}</td></tr>"
      end
    end
    html << "</table>>"
    return html
  end
end
