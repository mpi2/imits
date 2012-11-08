class NetworkGraph::MiPlanNode < NetworkGraph::NodeWithStates
  def initialize(mi_plan, params)
    params[:rank] = "2"
    super(mi_plan, params)
    find_statuses(mi_plan)
  end

  def label_html
    html = "<<table>" +
             "<tr><td colspan=\"2\">Mi Plan</td></tr>" +
             "<tr><td>Consortium:</td><td>#{CGI.escapeHTML(@consortium)}</td></tr>" +
             "<tr><td>Centre:</td><td>#{CGI.escapeHTML(@centre)}</td></tr>" +
             "<tr><td>Current Status:</td><td>#{CGI.escapeHTML(@current_status)}</td></tr>"
    ['Assigned', 'Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Aborted - ES Cell QC Failed'].each do |status|
      if @statuses.has_key?(status)
        html << "<tr><td>#{CGI.escapeHTML(status)}:</td><td>#{CGI.escapeHTML(@statuses[status])}</td></tr>"
      end
    end
    html << "</table>>"
    return html
  end
end
