class network_graph < ApplicationModel

  def initialise(gene_id)
    @gene = Gene.find_by_id(gene_id)
    @starting_node = @gene_node.new({:id=> @gene.id, :marker_symbol => @gene.marker_symbol, :es_cell=> @gene.es_cell.name})
    @nodes = {}
    @relations = {}
    @ranks = {1 => [], 2 => [], 3 => [], 4 => []}
    setup
    @dot_file = create_dot_file
  end

  def setup
    @nodes[['G',@gene.id]] = gene_node.new(params={:symbol =>'G1', :id => @gene.id, :marker_symbol => @gene.marker_symbol})
    plan_no = 0
    mi_no = 0
    phen_no = 0

    @gene.mi_plans.each do |mi_plan|
      plan_no += 1
      @nodes[['MP', mi_plan.id]] = mi_plan_node.new(params={:symbol => "P#{plan_no}", :id => mi_plan.id, :consortium=> mi_plan.consortium.name, :centre=>mi_plan.production_centre.name})
      @relations[nodes[['G',gene.id]]] = nodes[['MP',mi_plan.id]]

      mi_plan.mi_attempts.each do |mi_attempt|
        mi_no += 1
        @nodes[['MA', mi_attempt.id]] = mi_attempt_node.new(params = {:symbol => "MA#{mi_no}", :id => mi_attempt.id, :consortium=> mi_plan.consortium.name, :centre=>mi_plan.production_centre.name})
        @relations[nodes[['MP',mi_plan.id]]] = nodes[['MA',mi_attempt.id]]

        mi_attempt.phenotype_attempt.each do |phenotype_attempt|
          if ! nodes.include?(['PA',phenotype_attempt.id])
            phen_no += 1
            @nodes[['PA',phenotype_attempt.id]] = phenotype_attempt_node.new(params = {:symbol => "PA#{phen_no}", :id => phenotype_attempt.id, :cre_deleter_strain => (phenotype_attempt.cre_deleter_strain.nil? ? '' : phenotype_attempt.cre_deleter_strain.name), :consortium=> mi_plan.consortium.name, :centre=>mi_plan.production_centre.name })
            @relations[nodes[['MA',mi_attempt.id]]] = nodes[['PA',phenotype_attempt.id]]
        end #end phenotype attempts associated with mi_attempt

      end  #end mi Attempts

      phenotype_attempt = mi_plan.phenotype_attempt
      if ! phenotype_attempt.nil?
        if ! nodes.include?(['PA',phenotype_attempt.id])
          phen_no += 1
          @nodes[['PA',phenotype_attempt.id]] = phenotype_attempt_node.new(params = {:symbol => "PA#{phen_no}", :id => phenotype_attempt.id, :cre_deleter_strain => (phenotype_attempt.cre_deleter_strain.nil? ? '' : phenotype_attempt.cre_deleter_strain.name), :consortium=> mi_plan.consortium.name, :centre=>mi_plan.production_centre.name })
        @relations[nodes[['MP',mi_plan.id]]] = nodes[['PA',phenotype_attempt.id]]
      end  #end mi Attempts associated with mi_plans without mi_attempt

    end  #end mi plan
    @nodes.each do |node|
      ranks[node.rank] << node
  end

  def create_dot_file
  end

  def dot_file
    reuturn @dot_file
  end
end

class node

  def initialise(params => {})
    @rank = params[:rank]
    @node_symbol = params[:symbol]
    @id = params[:id]
    @consortium  = params[:consortium]
    @centre = params[:centre]
  end

  def rank
    return @rank
  end

  def node_symbol
    return @node_symbol
  end
end


class node_with_states < node
  def initialise(params => {})
    super(params)
  end

  def states(states)
    @states = {}
    states.each do |state|
      @states[state.name] = state.created_at
  end
end


class gene_node < node
  def initialise(params => {})
    params[:rank] = 1
    super(params)
    @marker_symbol = params[:marker_symbol]
  end

  def label_html
    html = "<table> " +
             "<tr><th>Marker Symbol:</th><td>#{@marker_symbol}</td></tr>"
           "</table>"
    return html
  end
end


class mi_plan_node < node_with_states
  def initialise(params => {})
    params[:rank] = 2
    super(params)
    super.states(MiPlan.find_by_id(@id).status_stamps.order("created_at DESC"))
  end

  def label_html
    html = "<table> " +
             "<tr><th>Consortium:</th><td>#{@consortium}</td></tr>" +
             "<tr><th>Centre:</th><td>#{@centre}</td></tr>"
    ['Assigned', 'Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Aborted - ES Cell QC Failed'].each do |status|
      if @statuses.includes?(status)
        html << "<tr><th>#{status}:</th><td>#{@statuses[status]}</td></tr>"
      end
    end
    html << "</table>"
    return html
  end
end


class mi_attempt_node < node_with_states
  def initialise(params => {})
    params[:rank] = 3
    super(params)
    super.states(MiAttempt.find_by_id(@id).status_stamps.order("created_at DESC"))
  end

  def label_html
    html = "<table> " +
             "<tr><th>Consortium:</th><td>#{@consortium}</td></tr>" +
             "<tr><th>Centre:</th><td>#{@centre}</td></tr>"
    ['Micro-injection in progress', 'Chimeras obtained', 'Genotype confirmed', 'Micro-injection aborted'].each do |state|
    if @statuses.includes?(status)
      html << "<tr><th>#{status}:</th><td>#{@statuses[status]}</td></tr>"
    end
    html << "</table>"
    return html
  end
end


class phenotype_attempt_node < node_with_states
  def initialise(params => {})
    params[:rank] = 4
    super(params)
    super.states(PhenotypeAttempt.find_by_id(@id).status_stamps.order("created_at DESC"))
  end

  def label_html
    html = "<table> " +
             "<tr><th>Consortium:</th><td>#{@consortium}</td></tr>" +
             "<tr><th>Centre:</th><td>#{@centre}</td></tr>" +
             "<tr><th>Cre Deleter Strain:</th><td>#{@cre_deleter_strain}</td></tr>" +
    ['Phenotype Attempt Registered', 'Rederivation Started', 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete','Phenotyping Started', 'Phenotyping Complete', 'Phenotype Attempt Aborted'].each do |state|
    if @state.includes?(state)
      html << "<tr><th>#{state}:</th><td>#{@state[state]}</td></tr>"
    end
    html << "</table>"
    return html
  end
end
