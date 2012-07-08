class Reports::MiProduction::ImpcGraphReportDisplay < Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediate

  def self.report_name; 'impc_graph_report_display'; end
  def self.report_title; 'IMPC Graph Report Display'; end
  def self.consortia; ['BaSH', 'DTCC', 'JAX']; end


  def initialize
    generated = self.class.generate
    @data = self.class.format(generated)
    @graph = create_graph
    draw_graph
  end

  def draw_graph
    format = 'jpg'
    require 'scruffy'
    graph.each do |consortium, graph_data|
      x_data_lables = graph_data['graph']['x_data']
      diff_data = graph_data['graph']['mi_diff_data']
      goals_data = graph_data['graph']['mi_goal_data']
      live_data = graph_data['graph']['mi_data']

      options = {
        :title => "#{consortium} MI Performance",
        :point_markers => x_data_lables
    #    :theme => {:background => [:black, '#4A465A']}
        }
      mi_graph = Scruffy::Graph.new(options)
 #     mi_graph.title = "#{consortium} MI Performance"
      mi_graph.theme = Scruffy::Themes::Base.new({:background => [:white, :white], :colors => [:red, :yellow, :green], :marker => :black})
#      mi_graph.theme =  :colors => [:red => 'red', :yellow => 'yellow', :green => 'green']
      mi_graph.add :area, 'diff', diff_data
      mi_graph.add :line, 'MI Cumulative', live_data
      mi_graph.add :line, 'MI Goals', goals_data
  #    mi_graph.point_markers = x_data_lables
      mi_graph.render(:width => 800, :min_value => 0, :padded => true, :to => "public/images/reports/charts/#{consortium}_mi_performance.#{format}", :as => "#{format}")

      goals_data = graph_data['graph']['gc_goal_data']
      live_data = graph_data['graph']['gc_data']
      diff_data = graph_data['graph']['gc_diff_data']

      gc_graph = Scruffy::Graph.new
      gc_graph.title = "#{consortium} GC Performance"
      gc_graph.theme = Scruffy::Themes::Keynote.new
      gc_graph.add :area, 'diff', diff_data
      gc_graph.add :line, 'GC Cumulative', live_data
      gc_graph.add :line, 'GC Goals', goals_data
      gc_graph.point_markers = x_data_lables
      gc_graph.render(:width => 800, :to => "public/images/reports/charts/#{consortium}_gc_performance.#{format}", :as => "#{format}")
    end
  end

end