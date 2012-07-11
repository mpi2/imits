class Reports::MiProduction::ImpcGraphReportDisplay < Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediate

  def self.report_name; 'impc_graph_report_display'; end
  def self.report_title; 'IMPC Graph Report Display'; end
  def self.consortia; ['BaSH', 'DTCC', 'JAX']; end


  def initialize
    generated = self.class.generate
    @data = self.class.format(generated)
    @graph = create_graph
    @size = draw_all_graphs
  end

  def graph
    return @graph
  end

  def size
    return @size
  end

  def create_graph

    year, month, day = self.class.convert_date(Time.now.prev_month)
    dataset = {}
    data.each do |consortium, consdata|
      total = consdata['mi_attempt_data'].count
      (0...total).to_a.each do |rowno|
        all_data = consdata['mi_attempt_data'][rowno]
        all_data.update(consdata['phenotype_data'][rowno])

        if (all_data['year'].to_s + all_data['month'].to_s).to_i == (year.to_s + month.to_s).to_i
          dataset[consortium] = {}
          dataset[consortium]['tabulate'] = []
          dataset[consortium]['graph'] = {}
          dataset[consortium]['graph']['mi_goal_data'] = []
          dataset[consortium]['graph']['mi_data'] = []
          dataset[consortium]['graph']['mi_diff_data'] = []
          dataset[consortium]['graph']['gc_goal_data'] = []
          dataset[consortium]['graph']['gc_data'] = []
          dataset[consortium]['graph']['gc_diff_data'] = []
          dataset[consortium]['graph']['x_data'] = []
          tabulate_data = {}
          tabulate_data['assigned_genes'] = all_data['cummulative_assigned_date']
          tabulate_data['es_qc'] = all_data['cumulative_es_starts']
          tabulate_data['es_qc_confirmed'] = all_data['cumulative_es_complete']
          tabulate_data['es_qc_failed'] = all_data['cumulative_es_failed']
          tabulate_data['mouse_production'] = all_data['cumulative_mis']
          tabulate_data['confirmaed_mice'] = all_data['cumulative_genotype_confirmed']
          tabulate_data['intent_to_phenotype'] = all_data['cumulative_phenotype_registered']
          tabulate_data['cre_excision_complete'] = all_data['cumulative_cre_excision_complete']
          tabulate_data['phenotyping_complete'] = all_data['cumulative_phenotyping_complete']
          dataset[consortium]['tabulate'] << tabulate_data
          tabulate_data = {}
          tabulate_data['assigned_genes'] = all_data['assigned_date']
          tabulate_data['es_qc'] = all_data['es_cell_qc_in_progress']
          tabulate_data['es_qc_confirmed'] = all_data['es_cell_qc_complete']
          tabulate_data['es_qc_failed'] = all_data['es_cell_qc_failed']
          tabulate_data['mouse_production'] = all_data['micro_injection_in_progress']
          tabulate_data['confirmaed_mice'] = all_data['genotype_confirmed']
          tabulate_data['intent_to_phenotype'] = all_data['phenotype_attempt_registered']
          tabulate_data['cre_excision_complete'] = all_data['cre_excision_complete']
          tabulate_data['phenotyping_complete'] = all_data['phenotyping_complete']
          dataset[consortium]['tabulate'] << tabulate_data
        end

        if (all_data['year'].to_s + ('0' + all_data['month'].to_s)[-2..-1]).to_i <= (year.to_s + ('0'+month.to_s)[-2..-1]).to_i
          dataset[consortium]['graph']['mi_goal_data'].insert(0,  all_data['mi_goal'])
          dataset[consortium]['graph']['mi_data'].insert(0,  all_data['cumulative_mis'])
          dataset[consortium]['graph']['mi_diff_data'].insert(0,  all_data['mi_goal'] - all_data['cumulative_mis'])
          dataset[consortium]['graph']['gc_goal_data'].insert(0,  all_data['gc_goal'])
          dataset[consortium]['graph']['gc_data'].insert(0, all_data['cumulative_genotype_confirmed'])
          dataset[consortium]['graph']['gc_diff_data'].insert(0, all_data['gc_goal'] - all_data['cumulative_genotype_confirmed'])
          dataset[consortium]['graph']['x_data'].insert(0, [total - rowno - 1,"#{Date::ABBR_MONTHNAMES[all_data['month']]}-#{all_data['year'].to_s[2..3]}"])
        end
      end
    end
  return dataset
  end

  def draw_all_graphs
    format = 'jpg'
    one_width = []
    index = 0
    graph.each do |consortium, graph_data|
      x_data_lables = graph_data['graph']['x_data']
      mi_max = (([graph_data['graph']['mi_data'].max, graph_data['graph']['mi_goal_data'].max].max / 40) + 1) * 40
      gc_max = (([graph_data['graph']['gc_data'].max, graph_data['graph']['gc_goal_data'].max].max / 40) + 1) * 40
      one_width << [(graph_data['graph']['mi_data'].count + 2) * 40 , 600].max
      draw_graph({:title => 'mi', :pointer_marker => x_data_lables, :live_data => graph_data['graph']['mi_data'], :goals_data => graph_data['graph']['mi_goal_data'], :diff_data => graph_data['graph']['mi_diff_data']},{:width => one_width[index], :height => 320, :min_value => 0, :max_value => mi_max, :consortium => consortium})
      draw_graph({:title => 'gc', :pointer_marker => x_data_lables, :live_data => graph_data['graph']['gc_data'], :goals_data => graph_data['graph']['gc_goal_data'], :diff_data => graph_data['graph']['gc_diff_data']},{:width => one_width[index], :height =>320, :min_value => 0, :max_value => gc_max, :consortium => consortium})
      index += 1
    end
    return one_width
  end


  def draw_graph(graph = {:title => '', :pointer_marker => [], :live_data => [], :goals_data => [], :diff_data => []}, render = {:width => 600, :min_value => 0, :max_value => 500, :consortium => ''})

    format = 'jpg'
    diff_data = []
    neg_diff_data = []
    graph[:diff_data].each do |split|
      if split < 0
        diff_data << 0
        neg_diff_data << (split)*(-1)
      else
        diff_data << split
        neg_diff_data << 0
      end
    end
    mi_graph = Scruffy::Graph.new(:title => "#{render[:consortium]} #{graph[:title].upcase} Performance", :point_markers => graph[:pointer_marker], :point_markers_rotation => 90)
    mi_graph.theme = Scruffy::Themes::Base.new({:background => [:white, :white], :colors => ['#009966', '#6886B4', '#FFCC00', '#000DCC'], :marker => :black})
    layer1 = mi_graph.add :line, "#{graph[:title]} Cumulative", graph[:live_data], :stroke_width => 4, :dots => true
    layer2 = mi_graph.add :line, "#{graph[:title]} Goals", graph[:goals_data], :stroke_width => 4, :dots => true
    layer3 = mi_graph.add :area, 'Below', diff_data
    layer4 = mi_graph.add :area, 'Above', neg_diff_data
    mi_graph.renderer = Scruffy::Renderers::Base.new
    mi_graph.renderer.components << Scruffy::Components::Title.new(:title, :position => [5, 2], :size => [90, 7])
    mi_graph.renderer.components << Scruffy::Components::Viewport.new(:view, :position => [2, 26], :size => [89, 66], :layers => [layer4, layer3, layer2, layer1]) do |graph|
      graph << Scruffy::Components::ValueMarkers.new(:values, :position => [0, 2], :size => [10, 85])
      graph << Scruffy::Components::Grid.new(:grid, :position => [12, 0], :size => [92, 85], :stroke_width => 1, :markers => 5)
      graph << Scruffy::Components::DataMarkers.new(:labels, :position => [12, 92], :size => [92, 8])
      graph << Scruffy::Components::Graphs.new(:graphs, :position => [12, 0], :size => [92, 85])
    end
    mi_graph.renderer.components << Scruffy::Components::Legend.new(:legend, :position => [5, 13], :size => [90, 6])
    mi_graph.render(:size => [render[:width],render[:height]], :min_value => render[:min_value], :max_value => render[:max_value], :to => "public/images/reports/charts/#{render[:consortium]}_#{graph[:title]}_performance.#{format}", :as => "#{format}")

  end

end