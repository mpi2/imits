class NetworkGraph

  def initialize(params)
    @gene = Gene.find_by_id(params[:gene])
    @report_to_public = '(true, false)'
    if params[:report_to_public] and params[:report_to_public] = true
      @report_to_public = '(true)'
    end
    @nodes = {}
    @relations = []
    @ranks = {'source' => [], "2" => [], "3" => [], "4" => []}
    setup
    @dot_file = create_dot_file
  end

  def setup

    @nodes[['G',@gene.id]] = NetworkGraph::GeneNode.new(@gene, params = {:symbol =>'G1', :url=>""})

    plan_no = 0
    mi_no = 0
    phen_no = 0

    @gene.mi_plans.where("report_to_public IN #{@report_to_public}").order("created_at, id").each do |mi_plan|
      plan_no += 1
      @nodes[['MP', mi_plan.id]] = NetworkGraph::MiPlanNode.new(mi_plan, params = {:symbol => "P#{plan_no}", :url => ''})
      @relations << [@nodes[['G',@gene.id]], @nodes[['MP',mi_plan.id]]]

      mi_plan.mi_attempts.where("report_to_public IN #{@report_to_public}").order("created_at, id").each do |mi_attempt|
        mi_no += 1
        @nodes[['MA', mi_attempt.id]] = NetworkGraph::MiAttemptNode.new(mi_attempt, params = {:symbol => "MA#{mi_no}", :url => ""})
        @relations<<[@nodes[['MP',mi_plan.id]], @nodes[['MA',mi_attempt.id]]]

        mi_attempt.phenotype_attempts.where("report_to_public IN #{@report_to_public}").order("created_at, id").each do |phenotype_attempt|
          if ! @nodes.include?(['PA',phenotype_attempt.id])
            phen_no += 1
            @nodes[['PA',phenotype_attempt.id]] = NetworkGraph::PhenotypeAttemptNode.new(phenotype_attempt, params = {:symbol => "PA#{phen_no}", :url => ""})
          end
          @relations<<[@nodes[['MA',mi_attempt.id]], @nodes[['PA',phenotype_attempt.id]]]
        end #end phenotype attempts associated with mi_attempt
      end  #end mi Attempts

      phenotype_attempts = mi_plan.phenotype_attempts.where("report_to_public IN #{@report_to_public}").order("created_at, id")
      if ! phenotype_attempts.nil?
        phenotype_attempts.each do |phenotype_attempt|
          if ! @nodes.include?(['PA',phenotype_attempt.id])
            phen_no += 1
            @nodes[['PA',phenotype_attempt.id]] = NetworkGraph::PhenotypeAttemptNode.new(phenotype_attempt, params = {:symbol => "PA#{phen_no}", :url => ""})
          end
          if phenotype_attempt.mi_plan_id != phenotype_attempt.mi_attempt.mi_plan_id
            @relations<<[@nodes[['MP',mi_plan.id]], @nodes[['PA',phenotype_attempt.id]]]
          end
        end
      end  #end phenotypes Attempts associated with mi_plans without mi_attempt

    end  #end mi plan
    @nodes.each do |key,node|
      @ranks[node.rank] << node
    end
  end

  def create_dot_file(orientation = "LR")
    dot_string = "digraph \"Production Graph\"{rankdir=\"#{orientation}\";\n"
    dot_string << "{node [shape=\"plaintext\", fontsize=16];\n \"Gene\" -> \"Plan\" -> \"Mouse Production\" -> \"Phenotype Attempt\";}\n" if orientation == "UD"
    @nodes.each do |key,node|
      dot_string << "\"#{node.node_symbol}\" [shape=none, margin=0, fontsize=10#{(node.url != ''?", URL=\"#{node.url}\"":"")}, label=#{node.label_html}];\n"
    end
    @relations.each do |from_node, to_node|
      dot_string << "\"#{from_node.node_symbol}\" -> \"#{to_node.node_symbol}\";\n"
    end
    dot_string << "{node [shape=\"plaintext\", fontsize=16];\n \"Gene\" -> \"Plan\" -> \"Mouse Production\" -> \"Phenotype Attempt\";}\n" if orientation == "LR"
    @ranks.each do |rank, nodes|
      if nodes.length > 0
        case rank
          when "source"
            dot_string << "{rank=same;\"Gene\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
          when "2"
            dot_string << "{rank=same;\"Plan\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
          when "3"
            dot_string << "{rank=same;\"Mouse Production\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
          when "4"
            dot_string << "{rank=same;\"Phenotype Attempt\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
        end
      end
    end
    dot_string << "}\n"
  end

  def dot_file
    return @dot_file
  end
end
