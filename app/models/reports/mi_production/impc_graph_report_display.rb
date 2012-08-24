class Reports::MiProduction::ImpcGraphReportDisplay < Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediate

  def self.report_name; 'komp2_production_summaries'; end
  def self.report_title; 'KOMP2 Production Summaries'; end
  def self.consortia; ['BaSH', 'DTCC', 'JAX']; end
  def self.states; {'Assigned Date'=>'assigned_date', 'ES Cell QC In Progress'=>'assigned_es_cell_qc_in_progress_date', 'ES Cell QC Complete'=> 'assigned_es_cell_qc_complete_date', 'ES Cell QC Failed'=> 'aborted_es_cell_qc_failed_date', 'Micro-injection in progress'=> 'micro_injection_in_progress_date', 'Chimeras obtained'=> 'chimeras_obtained_date', 'Genotype confirmed'=> 'genotype_confirmed_date', 'Micro-injection aborted'=>'micro_injection_aborted_date', 'Phenotype Attempt Registered'=>'phenotype_attempt_registered_date', 'Rederivation Started'=>'rederivation_started_date', 'Rederivation Complete'=> 'rederivation_complete_date', 'Cre Excision Started'=>'cre_excision_started_date', 'Cre Excision Complete'=>'cre_excision_complete_date', 'Phenotyping Started'=>'phenotyping_started_date', 'Phenotyping Complete'=>'phenotyping_complete_date', 'Phenotype Attempt Aborted'=>'phenotype_attempt_aborted_date'}; end

  def initialize
    generated = self.class.generate
    @data = self.class.format(generated)
    @chart_file_names = {}
    @graph = create_graph
    @size = draw_all_graphs
    @csv = to_csv
  end

  def graph
    return @graph
  end

  def size
    return @size
  end

  def month
    return @month
  end

  def chart_file_names
    return @chart_file_names
  end

  def to_csv
    csv_by_consortium = {}
    @graph.each do |consortium, data|
      headers = ['Status', "Current Total (#{@month})", "Last Complete Month (#{@month})"]
      csv_string = headers.to_csv
      csv_string += ['Assigned genes', data['tabulate'][0]['assigned_genes'], data['tabulate'][1]['assigned_genes']].to_csv
      csv_string += ['ES QC', data['tabulate'][0]['es_qc'], data['tabulate'][1]['es_qc']].to_csv
      csv_string += ['ES QC Confirmed', data['tabulate'][0]['es_qc_confirmed'], data['tabulate'][1]['es_qc_confirmed']].to_csv
      csv_string += ['ES QC Failed', data['tabulate'][0]['es_qc_failed'], data['tabulate'][1]['es_qc_failed']].to_csv
      csv_string += ['Mouse Production', data['tabulate'][0]['mouse_production'], data['tabulate'][1]['mouse_production']].to_csv
      csv_string += ['Confirmed Mice', data['tabulate'][0]['confirmed_mice'], data['tabulate'][1]['confirmed_mice']].to_csv
      csv_string += ['Intent to Phenotype', data['tabulate'][0]['intent_to_phenotype'], data['tabulate'][1]['intent_to_phenotype']].to_csv
      csv_string += ['Cre Excision Complete', data['tabulate'][0]['cre_excision_complete'], data['tabulate'][1]['cre_excision_complete']].to_csv
      csv_string += ['Phenotyping Complete', data['tabulate'][0]['phenotyping_complete'], data['tabulate'][1]['phenotyping_complete']].to_csv
      csv_by_consortium[consortium] = csv_string
    end
    return csv_by_consortium
  end


  def create_graph

    year, month, day = self.class.convert_date(Time.now.prev_month)
    @month = Date::MONTHNAMES[month]
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
          tabulate_data['confirmed_mice'] = all_data['cumulative_genotype_confirmed']
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
          tabulate_data['confirmed_mice'] = all_data['genotype_confirmed']
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
    format = 'jpeg'
    one_width = []
    index = 0
    graph.each do |consortium, graph_data|
      x_data_lables = graph_data['graph']['x_data']
      mi_max = (([graph_data['graph']['mi_data'].max, graph_data['graph']['mi_goal_data'].max].max / 40) + 1) * 40
      gc_max = (([graph_data['graph']['gc_data'].max, graph_data['graph']['gc_goal_data'].max].max / 40) + 1) * 40
      one_width << [(graph_data['graph']['mi_data'].count + 2) * 40 , 600].max
      draw_graph({:title => "#{consortium} Total Mouse Production", :legend => ['Total Mouse Production (Genes)','Mouse Production Goals (Genes)'], :pointer_marker => x_data_lables, :live_data => graph_data['graph']['mi_data'], :goals_data => graph_data['graph']['mi_goal_data'], :diff_data => graph_data['graph']['mi_diff_data']},{:name => 'mi', :width => one_width[index], :height => 380, :min_value => 0, :max_value => mi_max, :consortium => consortium})
      draw_graph({:title => "#{consortium} Genotype Confirmed Mouse Production", :legend => ['Total Genotype Confirmed Mice (Genes)','Genotype Confirmed Goals (Genes)'], :pointer_marker => x_data_lables, :live_data => graph_data['graph']['gc_data'], :goals_data => graph_data['graph']['gc_goal_data'], :diff_data => graph_data['graph']['gc_diff_data']},{:name => 'gc', :width => one_width[index], :height =>380, :min_value => 0, :max_value => gc_max, :consortium => consortium})
      index += 1
    end
    return one_width
  end


  def draw_graph(graph = {:title => '', :legend => ['',''], :pointer_marker => [], :live_data => [], :goals_data => [], :diff_data => []}, render = {:name => '', :width => 600, :min_value => 0, :max_value => 500, :consortium => ''})
    format = 'jpeg'
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


    mi_graph = Scruffy::Graph.new(:title => graph[:title], :point_markers => graph[:pointer_marker], :point_markers_rotation => 90)
    mi_graph.theme = Scruffy::Themes::Base.new({:background => [:white, :white], :colors => ['#009966', '#6886B4', '#FFCC00', '#000DCC'], :marker => :black})
    layer1 = mi_graph.add :line, "#{graph[:legend][0]}", graph[:live_data], :stroke_width => 4, :dots => true
    layer2 = mi_graph.add :line, "#{graph[:legend][1]}", graph[:goals_data], :stroke_width => 4, :dots => true
    layer3 = mi_graph.add :area, 'Below', diff_data
    layer4 = mi_graph.add :area, 'Above', neg_diff_data
    mi_graph.renderer = Scruffy::Renderers::Base.new
    mi_graph.renderer.components << Scruffy::Components::Title.new(:title, :position => [5, 0], :size => [90, 7])
    mi_graph.renderer.components << Scruffy::Components::Viewport.new(:view, :position => [2, 26], :size => [89, 66], :layers => [layer4, layer3, layer2, layer1]) do |graph|
      graph << Scruffy::Components::ValueMarkers.new(:values, :position => [0, 12], :size => [10, 75])
      graph << Scruffy::Components::Grid.new(:grid, :position => [12, 10], :size => [92, 75], :stroke_width => 1, :markers => 5)
      graph << Scruffy::Components::DataMarkers.new(:labels, :position => [12, 92], :size => [92, 8])
      graph << Scruffy::Components::Graphs.new(:graphs, :position => [12, 10], :size => [92, 75])
    end
    mi_graph.renderer.components << Scruffy::Components::Legend.new(:legend, :position => [12, 10], :size => [70, 70], :vertical_legend => true)
    file = "#{Rails.application.config.paths.tmp.first}/reports/impc_graph_report_display/charts/#{render[:consortium].downcase}_#{render[:name]}_performance#{Time.now.strftime "%Y%m%d%H%M%S"}-#{rand(100)}.#{format}"
    FileUtils.mkdir_p File.dirname(file)
    mi_graph.render(:size => [render[:width],render[:height]], :min_value => render[:min_value], :max_value => render[:max_value], :to => file, :as => "#{format}")

    if !@chart_file_names.has_key?(render[:consortium].downcase)
      @chart_file_names[render[:consortium].downcase] = {}
    end
    @chart_file_names[render[:consortium].downcase][render[:name]] = file
  end

  def self.clear_charts_in_tmp_folder
    Dir.glob("#{Rails.application.config.paths.tmp.first}/reports/impc_graph_report_display/charts/*.jpeg") do |file|
      if File.file?(file)
        if File.atime(file) < (Time.now - 30.minutes)
          File.delete(file)
        end
      end
    end
  end

end
