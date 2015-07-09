class NetworkGraph

  def initialize(params)
    @gene = Gene.find_by_id(params[:gene])
    @report_to_public = '(true, false)'
    if params[:report_to_public] && params[:report_to_public] = true
      @report_to_public = '(true)'
    end
    @nodes = {}
    @relations = []
    @ranks = {'source' => [], "2" => [], "3" => [], "4" => [], "5" => []}
    setup
    @dot_file = create_dot_file
  end

  def setup

    @nodes[['G',@gene.id]] = NetworkGraph::GeneNode.new(@gene, params = {:symbol =>'G1', :url=>""})

    plan_no = 0
    mi_no = 0
    mam_no = 0
    phen_no = 0

    @gene.mi_plans.where("report_to_public IN #{@report_to_public}").order("created_at, id").each do |mi_plan|
      plan_no += 1
      @nodes[['MP', mi_plan.id]] = NetworkGraph::MiPlanNode.new(mi_plan, params = {:symbol => "P#{plan_no}", :url => ''})
      @relations << [@nodes[['G',@gene.id]], @nodes[['MP',mi_plan.id]]]

      mi_plan.mi_attempts.where("report_to_public IN #{@report_to_public}").order("created_at, id").each do |mi_attempt|
        mi_no += 1
        @nodes[['MA', mi_attempt.id]] = NetworkGraph::MiAttemptNode.new(mi_attempt, params = {:symbol => "MA#{mi_no}", :url => ""})
        @relations<<[@nodes[['MP',mi_plan.id]], @nodes[['MA',mi_attempt.id]]]

        MouseAlleleMod.joins(parent_colony: :mi_attempt).where("mi_attempts.id = #{mi_attempt.id} AND mouse_allele_mods.report_to_public IN #{@report_to_public}").order("created_at, id").each do |mouse_allele_mod|
          if ! @nodes.include?(['MAM',mouse_allele_mod.id])
            mam_no += 1
            @nodes[['MAM',mouse_allele_mod.id]] = NetworkGraph::MouseAlleleModNode.new(mouse_allele_mod, params = {:symbol => "MAM#{mam_no}", :url => ""})
          end
          @relations<<[@nodes[['MA',mi_attempt.id]], @nodes[['MAM',mouse_allele_mod.id]]]

          PhenotypingProduction.joins(parent_colony: :mouse_allele_mod).where("mouse_allele_mods.id = #{mouse_allele_mod.id} AND phenotyping_productions.report_to_public IN #{@report_to_public}").order("created_at", "id").each do |phenotyping_production|
            if ! @nodes.include?(['PP',phenotyping_production.id])
              phen_no += 1
              @nodes[['PP',phenotyping_production.id]] = NetworkGraph::PhenotypingProductionNode.new(phenotyping_production, params = {:symbol => "PP#{phen_no}", :url => ""})
            end
            @relations<<[@nodes[['MAM',mouse_allele_mod.id]], @nodes[['PP',phenotyping_production.id]]]
          end #end phenotyping_production associated with mouse_allele_mod
        end #end mouse_allele_mods associated with mi_attempt

        PhenotypingProduction.joins(parent_colony: :mi_attempt).where("mi_attempts.id = #{mi_attempt.id} AND phenotyping_productions.report_to_public IN #{@report_to_public}").order("created_at", "id").each do |phenotyping_production|
          if ! @nodes.include?(['PP',phenotyping_production.id])
            phen_no += 1
            @nodes[['PP',phenotyping_production.id]] = NetworkGraph::PhenotypingProductionNode.new(phenotyping_production, params = {:symbol => "PP#{phen_no}", :url => ""})
          end
          @relations<<[@nodes[['MA',mi_attempt.id]], @nodes[['PP',phenotyping_production.id]]]
        end #end phenotyping_production associated with mi_attempt

      end  #end mi Attempts


      mouse_allele_mods = mi_plan.mouse_allele_mods.where("report_to_public IN #{@report_to_public}").order("created_at, id")
      if ! mouse_allele_mods.nil?
        mouse_allele_mods.each do |mouse_allele_mod|
          if ! @nodes.include?(['MAM',mouse_allele_mod.id])
            mam_no += 1
            @nodes[['MAM',mouse_allele_mod.id]] = NetworkGraph::MouseAlleleModNode.new(mouse_allele_mod, params = {:symbol => "MAM#{mam_no}", :url => ""})
          end
          if mouse_allele_mod.mi_plan_id != mouse_allele_mod.parent_colony.mi_attempt.mi_plan_id
            @relations<<[@nodes[['MP',mi_plan.id]], @nodes[['MAM',mouse_allele_mod.id]]]

            PhenotypingProduction.joins(parent_colony: :mouse_allele_mod).where("mouse_allele_mods.id = #{mouse_allele_mod.id} AND phenotyping_productions.report_to_public IN #{@report_to_public}").order("created_at", "id").each do |phenotyping_production|
              if ! @nodes.include?(['PP',phenotyping_production.id])
                phen_no += 1
                @nodes[['PP',phenotyping_production.id]] = NetworkGraph::PhenotypingProductionNode.new(phenotyping_production, params = {:symbol => "PP#{phen_no}", :url => ""})
              end
              @relations<<[@nodes[['MAM',mouse_allele_mod.id]], @nodes[['PP',phenotyping_production.id]]]
            end
          end
        end
      end  #end mouse_allele_mods associated with mi_plans without mi_attempt


      phenotyping_productions = mi_plan.phenotyping_productions.where("report_to_public IN #{@report_to_public}").order("created_at, id")
      if ! phenotyping_productions.nil?
        phenotyping_productions.each do |phenotyping_production|
          if ! @nodes.include?(['PP',phenotyping_production.id])
            phen_no += 1
            @nodes[['PP',phenotyping_production.id]] = NetworkGraph::PhenotypingProductionNode.new(phenotyping_production, params = {:symbol => "PP#{phen_no}", :url => ""})
          end
          if (!phenotyping_production.parent_colony.mi_attempt_id.nil? && phenotyping_production.mi_plan_id != phenotyping_production.parent_colony.mi_attempt.mi_plan_id) ||
              (!phenotyping_production.parent_colony.mouse_allele_mod.nil? && phenotyping_production.mi_plan_id != phenotyping_production.parent_colony.mouse_allele_mod.mi_plan_id)
            @relations<<[@nodes[['MP',mi_plan.id]], @nodes[['PP',phenotyping_production.id]]]
          end
        end
      end

    end  #end mi plan

    @nodes.each do |key,node|
      @ranks[node.rank] << node
    end
  end

  def create_dot_file(orientation = "LR")
    dot_string = "digraph \"Production Graph\"{rankdir=\"#{orientation}\";\n"
    dot_string << "{node [shape=\"plaintext\", fontsize=16];\n \"Gene\" -> \"Plan\" -> \"Micro Injection\" -> \"Mouse Allele Modification\" -> \"Phenotyping\";}\n" if orientation == "UD"
    @nodes.each do |key,node|
      dot_string << "\"#{node.node_symbol}\" [shape=none, margin=0, fontsize=10#{(node.url != ''?", URL=\"#{node.url}\"":"")}, label=#{node.label_html}];\n"
    end
    @relations.each do |from_node, to_node|
      dot_string << "\"#{from_node.node_symbol}\" -> \"#{to_node.node_symbol}\";\n"
    end
    dot_string << "{node [shape=\"plaintext\", fontsize=16];\n \"Gene\" -> \"Plan\" -> \"Micro Injection\" -> \"Mouse Allele Modification\" -> \"Phenotyping\";}\n" if orientation == "LR"
    @ranks.each do |rank, nodes|
      if nodes.length > 0
        case rank
          when "source"
            dot_string << "{rank=same;\"Gene\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
          when "2"
            dot_string << "{rank=same;\"Plan\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
          when "3"
            dot_string << "{rank=same;\"Micro Injection\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
          when "4"
            dot_string << "{rank=same;\"Mouse Allele Modification\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
          when "5"
            dot_string << "{rank=same;\"Phenotyping\";\"#{nodes.map{|node| node.node_symbol}.join('";"')}\"}\n"
        end
      end
    end
    dot_string << "}\n"
  end

  def dot_file
    return @dot_file
  end


end
