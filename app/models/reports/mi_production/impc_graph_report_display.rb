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

  def draw_all_graphs
    format = 'jpg'
    require 'scruffy'
    width = 600
    height = 320
    graph.each do |consortium, graph_data|
      x_data_lables = graph_data['graph']['x_data']
      draw_graph({:title => 'mi', :pointer_marker => x_data_lables, :live_data => graph_data['graph']['mi_data'], :goals_data => graph_data['graph']['mi_goal_data'], :diff_data => graph_data['graph']['mi_diff_data']},{:width => 600, :min_value => 0, :consortium => consortium})
      draw_graph({:title => 'gc', :pointer_marker => x_data_lables, :live_data => graph_data['graph']['gc_data'], :goals_data => graph_data['graph']['gc_goal_data'], :diff_data => graph_data['graph']['gc_diff_data']},{:width => 600, :min_value => 0, :consortium => consortium})
    end
    [width, height]
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
    mi_graph = Scruffy::Graph.new(:title => "#{render[:consortium]} #{graph[:title].upcase} Performance", :point_markers => graph[:pointer_marker])
    mi_graph.theme = Scruffy::Themes::Base.new({:background => [:white, :white], :colors => ['#009966', '#6886B4', '#FFCC00', '#000DCC'], :marker => :black})
    layer1 = mi_graph.add :line, "#{graph[:title]} Cumulative", graph[:live_data]
    layer2 = mi_graph.add :line, "#{graph[:title]} Goals", graph[:goals_data]
    layer3 = mi_graph.add :area, 'Below', diff_data
    layer4 = mi_graph.add :area, 'Above', neg_diff_data

    mi_graph.renderer = Scruffy::Renderers::Base.new
    mi_graph.renderer.components << Scruffy::Components::Title.new(:title, :position => [5, 2], :size => [90, 7])
    mi_graph.renderer.components << Scruffy::Components::Viewport.new(:view, :position => [2, 26], :size => [89, 66], :layers => [layer4, layer3, layer2, layer1]) do |graph|
      graph << Scruffy::Components::ValueMarkers.new(:values, :position => [0, 2], :size => [10, 89])
      graph << Scruffy::Components::Grid.new(:grid, :position => [12, 0], :size => [92, 89], :stroke_width => 1, :markers => 5)
      graph << Scruffy::Components::DataMarkers.new(:labels, :position => [12, 92], :size => [92, 8])
      graph << Scruffy::Components::Graphs.new(:graphs, :position => [12, 0], :size => [92, 89])
    end
    mi_graph.renderer.components << Scruffy::Components::Legend.new(:legend, :position => [5, 13], :size => [90, 6])
    mi_graph.render(:width => render[:width], :min_value => render[:min_value], :to => "public/images/reports/charts/#{render[:consortium]}_#{graph[:title]}_performance.#{format}", :as => "#{format}")

  end

end