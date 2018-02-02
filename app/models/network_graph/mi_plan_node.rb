class NetworkGraph::MiPlanNode < NetworkGraph::NodeWithStates
  def initialize(mi_plan, params)
    params[:rank] = "2"
    super(mi_plan, params)
    find_statuses(mi_plan)

    @es_cell_qc = 'No'
    @modify_mouse_allele = 'Yes'
    @phenotype = 'Yes'

    if mi_plan.es_cell_qc_only == true || mi_plan.phenotype_only == true
      @injection_strategy = 'None'
      @es_cell_qc = 'Yes' if mi_plan.es_cell_qc_only == true
      if mi_plan.phenotype_only == false
        @phenotype = 'No' 
        @modify_mouse_allele = 'No'
      end
    elsif mi_plan.mutagenesis_via_crispr_cas9 == true
      @injection_strategy = 'CRISPR'
    else
      @injection_strategy = 'ES Cell'
    end

    @es_cell_qc = 'Yes' if [8, 9, 10, 14].include?(mi_plan.status_id)
  end

  def label_html
    html = "<<table>" +
             "<tr><td colspan=\"2\" border=\"0\">Plan</td></tr>" +
             "<tr><td>Consortium:</td><td>#{CGI.escapeHTML(@consortium)}</td></tr>" +
             "<tr><td>Centre:</td><td>#{CGI.escapeHTML(@centre)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>" +
             "<tr><td border=\"0\">Plan Details</td><td border=\"0\"></td></tr>" +
             "<tr><td>ES Cell QC:</td><td>#{CGI.escapeHTML(@es_cell_qc)}</td></tr>" +
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
