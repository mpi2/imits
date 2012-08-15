class NetworkGraph::GeneNode < NetworkGraph::Node
  def initialize(params)
    params[:rank] = 'source'
    super(params)
    @marker_symbol = params[:marker_symbol]
  end

  def label_html
    html = "<<table> " +
             "<tr><td colspan=\"2\">Gene</td></tr>" +
             "<tr><td>Marker Symbol:</td><td>#{CGI.escapeHTML(@marker_symbol)}</td></tr>" +
           "</table>>"
    return html
  end
end
