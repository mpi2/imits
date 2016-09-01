class NetworkGraph::PlanNode < NetworkGraph::NodeWithStates
  def initialize(plan, params)
    params[:rank] = "2"
    super(plan, params)
    @injection_strategy = []
    @injection_strategy << "ES Cell - #{plan.micro_injected_es_cell_intention.first.status.name}" unless plan.micro_injected_es_cell_intention.blank?   
    @injection_strategy << "CRISPR - #{plan.micro_injected_crispr_intention.first.status.name}"  unless plan.micro_injected_crispr_intention.blank?
    @injection_strategy << "None"  if plan.micro_injected_crispr_intention.blank? && plan.micro_injected_es_cell_intention.blank?
    @modify_mouse_allele = plan.modify_mice_allele_intention.blank? ? 'No' : "#{plan.modify_mice_allele_intention.first.withdrawn ? 'No' : 'Yes'}"
    @phenotype = plan.phenotype_mice_intention.blank? ? 'No' : "#{plan.phenotype_mice_intention.first.withdrawn ? 'No' : 'Yes'}"
    @es_cell_qc = plan.es_cell_qcs.blank? ? 'No' : 'Yes'
    @es_cell_qc_statuses = plan.es_cell_qcs.blank? ? {} : find_statuses(plan.es_cell_qcs.first)
    puts "HELLO #{@es_cell_qc_statuses}"
  end

  def label_html
    html = "<<table>" +
             "<tr><td colspan=\"2\" border=\"0\">Plan</td></tr>" +
             "<tr><td>Consortium:</td><td>#{CGI.escapeHTML(@consortium)}</td></tr>" +
             "<tr><td>Centre:</td><td>#{CGI.escapeHTML(@centre)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>" +
             "<tr><td border=\"0\">Plan Details</td><td border=\"0\"></td></tr>" +
             "#{@injection_strategy.map{|is| "<tr><td>Injection Strategy:</td><td>#{CGI.escapeHTML(is)}</td></tr>" }.join(' ')}" +            
             "<tr><td>Modify Mouse Allele:</td><td>#{CGI.escapeHTML(@modify_mouse_allele)}</td></tr>" +
             "<tr><td>Phenotype:</td><td>#{CGI.escapeHTML(@phenotype)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>"


    html << "<tr><td border=\"0\">ES Cell QC Status Details</td><td border=\"0\"></td></tr>" unless @es_cell_qc_statuses.blank?
    @es_cell_qc_statuses.each do |status, d|
        html << "<tr><td>#{CGI.escapeHTML(status)}:</td><td>#{CGI.escapeHTML(d)}</td></tr>"
    end
    html << "</table>>"
    return html
  end
end
