class NetworkGraph

  def initialize(gene_id)
    @gene = Gene.find_by_id(gene_id)
    @nodes = {}
    @relations = []
    @ranks = {'source' => [], "2" => [], "3" => [], "4" => []}
    setup
    @dot_file = create_dot_file
  end

  def setup
    @nodes[['G',@gene.id]] = NetworkGraph::GeneNode.new(params={:symbol =>'G1', :id => @gene.id, :marker_symbol => @gene.marker_symbol, :url=>""})
    plan_no = 0
    mi_no = 0
    phen_no = 0
    @gene.mi_plans(:order => "created_at, id").each do |mi_plan|
      plan_no += 1
      @nodes[['MP', mi_plan.id]] = NetworkGraph::MiPlanNode.new(params={:symbol => "P#{plan_no}", :id => mi_plan.id, :consortium=> mi_plan.consortium.name, :centre=>mi_plan.production_centre.name, :url=>''})
      @relations << [@nodes[['G',@gene.id]], @nodes[['MP',mi_plan.id]]]
      mi_plan.mi_attempts(:order => "created_at, id").each do |mi_attempt|
        mi_no += 1
        @nodes[['MA', mi_attempt.id]] = NetworkGraph::MiAttemptNode.new(params = {:symbol => "MA#{mi_no}", :id => mi_attempt.id, :consortium=> mi_plan.consortium.name, :centre=>mi_plan.production_centre.name, :url=>"", :colony_background_strain => (!mi_attempt.colony_background_strain.nil? ? mi_attempt.colony_background_strain.name : ''), :test_cross_strain => (! mi_attempt.test_cross_strain.nil? ? mi_attempt.test_cross_strain.name : '')})
        @relations<<[@nodes[['MP',mi_plan.id]], @nodes[['MA',mi_attempt.id]]]
        mi_attempt.phenotype_attempts(:order => "created_at, id").each do |phenotype_attempt|
          if ! @nodes.include?(['PA',phenotype_attempt.id])
            phen_no += 1
            @nodes[['PA',phenotype_attempt.id]] = NetworkGraph::PhenotypeAttemptNode.new(params = {:symbol => "PA#{phen_no}", :id => phenotype_attempt.id, :cre_deleter_strain => (phenotype_attempt.deleter_strain.nil? ? '' : phenotype_attempt.deleter_strain.name), :consortium=> phenotype_attempt.mi_plan.consortium.name, :centre=>phenotype_attempt.mi_plan.production_centre.name, :url=>""})
          end
          @relations<<[@nodes[['MA',mi_attempt.id]], @nodes[['PA',phenotype_attempt.id]]]
        end #end phenotype attempts associated with mi_attempt
      end  #end mi Attempts
      phenotype_attempts = mi_plan.phenotype_attempts(:order => "created_at, id")
      if ! phenotype_attempts.nil?
        phenotype_attempts.each do |phenotype_attempt|
          if ! @nodes.include?(['PA',phenotype_attempt.id])
            phen_no += 1
            @nodes[['PA',phenotype_attempt.id]] = NetworkGraph::PhenotypeAttemptNode.new(params = {:symbol => "PA#{phen_no}", :id => phenotype_attempt.id, :cre_deleter_strain => (phenotype_attempt.deleter_strain.nil? ? '' : phenotype_attempt.deleter_strain.name), :consortium=> phenotype_attempt.mi_plan.consortium.name, :centre=>phenotype_attempt.mi_plan.production_centre.name, :url=>""})
          end
          if phenotype_attempt.mi_plan_id != phenotype_attempt.mi_attempt.mi_plan_id
            @relations<<[@nodes[['MP',mi_plan.id]], @nodes[['PA',phenotype_attempt.id]]]
          end
        end
      end  #end mi Attempts associated with mi_plans without mi_attempt

    end  #end mi plan
    @nodes.each do |key,node|
      @ranks[node.rank] << node
    end
  end

  def create_dot_file
    dot_string = "digraph \"Production Graph\"{rankdir=\"LR\";\n"
    @nodes.each do |key,node|
      dot_string << "\"#{node.node_symbol}\" [shape=none, margin=0, fontsize=10#{(node.url != ''?", URL=\"#{node.url}\"":"")}, label=#{node.label_html}];\n"
    end
    @relations.each do |from_node, to_node|
      dot_string << "\"#{from_node.node_symbol}\" -> \"#{to_node.node_symbol}\";\n"
    end
    dot_string << "{node [shape=\"plaintext\", fontsize=16];\n \"Gene\" -> \"Mi Plans\" -> \"Mi Attempts\" -> \"Phenotype Attempts\";}\n"
    @ranks.each do |rank, nodes|
      if nodes.length > 0
        case rank
          when "source"
            dot_string << "{rank=same;\"Gene\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
          when "2"
            dot_string << "{rank=same;\"Mi Plans\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
          when "3"
            dot_string << "{rank=same;\"Mi Attempts\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
          when "4"
            dot_string << "{rank=same;\"Phenotype Attempts\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
        end
      end
    end
    dot_string << "}\n"
  end

  def dot_file
    return @dot_file
  end
end
