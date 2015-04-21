class NetworkGraph::MiPlanNode < NetworkGraph::NodeWithStates
  def initialize(mi_plan, params)
    params[:rank] = "2"
    super(mi_plan, params)
    find_statuses(mi_plan)
    @injection_strategy = mi_plan.mutagenesis_via_crispr_cas9 == true ? 'CRISPR' : (mi_plan.phenotype_only == true ? 'None' : 'ES Cell')
    @modify_mouse_allele = 'Yes'
    @phenotype = 'Yes'
  end

  def label_html
    html = "<<table>" +
             "<tr><td colspan=\"2\" border=\"0\">Plan</td></tr>" +
             "<tr><td>Consortium:</td><td>#{CGI.escapeHTML(@consortium)}</td></tr>" +
             "<tr><td>Centre:</td><td>#{CGI.escapeHTML(@centre)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>" +
             "<tr><td border=\"0\">Plan Details</td><td border=\"0\"></td></tr>" +
             "<tr><td>Injection Strategy:</td><td>#{CGI.escapeHTML(@injection_strategy)}</td></tr>" +
             "<tr><td>Modify Mouse Allele:</td><td>#{CGI.escapeHTML(@modify_mouse_allele)}</td></tr>" +
             "<tr><td>Phenotype:</td><td>#{CGI.escapeHTML(@phenotype)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>" +
             "<tr><td border=\"0\">Status Details</td><td border=\"0\"></td></tr>" +
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
