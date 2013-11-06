class GraphReportDisplay < BaseSummaryByMonthReport

  def initialize(consortia_list=nil)
    @chart_file_names = {}
    super
    graph_data = self.generate_graphs
    @size = self.draw_all_graphs(graph_data)
  end

  def summary_by_month
    ActiveRecord::Base.connection.execute(summary_by_month_sql(previous_month = true))
  end

  def chart_file_names
    return @chart_file_names
  end

  def size
    return @size
  end

  def generate_graphs #_with_2016_goals

    dataset = {}
    dates = []
    cut_off_date = '2011-06-01'.to_date
    report_date = date_previous_month.to_date.at_beginning_of_month

    sql = <<-EOF
      SELECT consortia.name AS consortium, production_goals.gc_goal AS gc_goal, to_date( production_goals.year || ' ' || production_goals.month || ' 01', 'YYYY MM DD') AS date
      FROM production_goals
        JOIN consortia ON consortia.id = production_goals.consortium_id
      WHERE to_date( production_goals.year || ' ' || production_goals.month || ' 01', 'YYYY MM DD')  >= '#{report_date}'
      ORDER BY consortia.name, to_date( production_goals.year || ' ' || production_goals.month || ' 01', 'YYYY MM DD')
    EOF
    report_data = ActiveRecord::Base.connection.execute(sql)
    future_goals = {}
    report_data.each do |report_row|
      if ! future_goals.has_key?(report_row['consortium'])
        future_goals[report_row['consortium']] = []
      end
      future_goals[report_row['consortium']] << {:date => report_row['date'].to_date,  :goal => report_row['gc_goal'].to_i}
    end


    while report_date >= cut_off_date do
      dates.insert(0, report_date)
      report_date = report_date.prev_month
    end

    available_consortia.each do |consortium|

      dataset[consortium] = {}
      dataset[consortium]['mi_goal_data'] = []
      dataset[consortium]['mi_data'] = []
      dataset[consortium]['pos_mi_diff_data'] = []
      dataset[consortium]['neg_mi_diff_data'] = []
      dataset[consortium]['cre_excised_data'] = []
      dataset[consortium]['gc_goal_data'] = []
      dataset[consortium]['gc_data'] = []
      dataset[consortium]['pos_gc_diff_data'] = []
      dataset[consortium]['neg_gc_diff_data'] = []
      dataset[consortium]['x_data'] = []

      rowno = 0
      dates.each do |date|
        dataset[consortium]['mi_goal_data'].append(@report_hash["#{consortium}-#{date}-MI Goal"].to_i)
        dataset[consortium]['mi_data'].append(@report_hash["#{consortium}-#{date}-Cumulative MIs"].to_i)
        dataset[consortium]['pos_mi_diff_data'].append([0, @report_hash["#{consortium}-#{date}-MI Goal"].to_i - @report_hash["#{consortium}-#{date}-Cumulative MIs"].to_i].max)
        dataset[consortium]['neg_mi_diff_data'].append(([0, @report_hash["#{consortium}-#{date}-MI Goal"].to_i - @report_hash["#{consortium}-#{date}-Cumulative MIs"].to_i].min)*(-1))

        dataset[consortium]['gc_goal_data'].append(@report_hash["#{consortium}-#{date}-GC Goal"].to_i)
        dataset[consortium]['gc_data'].append(@report_hash["#{consortium}-#{date}-Cumulative genotype confirmed"].to_i)
        dataset[consortium]['pos_gc_diff_data'].append([0, @report_hash["#{consortium}-#{date}-GC Goal"].to_i - @report_hash["#{consortium}-#{date}-Cumulative genotype confirmed"].to_i].max)
        dataset[consortium]['neg_gc_diff_data'].append(([0, @report_hash["#{consortium}-#{date}-GC Goal"].to_i - @report_hash["#{consortium}-#{date}-Cumulative genotype confirmed"].to_i].min)*(-1))

        dataset[consortium]['cre_excised_data'].append(@report_hash["#{consortium}-#{date}-Cumulative Cre Excision Complete"].to_i)
        dataset[consortium]['x_data'].append([rowno,"#{Date::ABBR_MONTHNAMES[date.month]}-#{date.year.to_s[2..3]}"])

        rowno +=1
      end
      dataset[consortium]['pos_gc_diff_data'].append(0)
      dataset[consortium]['neg_gc_diff_data'].append(0)
      size = dataset[consortium]['x_data'].count
      dataset[consortium]['x_data_extended'] = Array.new(size){ |index| (index+1)%2 == 0 ? nil : dataset[consortium]['x_data'][index] }.compact
      dataset[consortium]['extended_gc_goals'] = dataset[consortium]['gc_goal_data'].dup

      rowno -=1 # readjust rowno
      if future_goals.has_key?(consortium)
        last_date_so_far = dates.last
        last_date = "2016-07-01".to_date
        future_goals[consortium].insert(0, {:date => dates.last , :goal => dataset[consortium]['extended_gc_goals'].last})
        if future_goals[consortium].last[:date] < last_date and dates.last < last_date
          future_goals[consortium] << { :date => last_date.to_date, :goal => 820}
        end

        if future_goals[consortium].count > 0
          loop_number = future_goals[consortium].count - 1
          for i in 1..loop_number

            number_of_month_diffences = (future_goals[consortium][i+1][:date].year - future_goals[consortium][i][:date].year) * 12 + (future_goals[consortium][i+1][:date].month - future_goals[consortium][i][:date].month)
            if number_of_month_diffences > 1
              goal_difference = (future_goals[consortium][i+1][:goal].to_f - future_goals[consortium][i][:goal].to_f)/number_of_month_diffences
              for j in 1..(number_of_month_diffences - 1)
                dataset[consortium]['extended_gc_goals'] << future_goals[consortium][i][:goal] + (j*(goal_difference)).to_i
                rowno += 1
                append_x_data(dataset, rowno, future_goals[consortium][i][:date] + j.month, consortium, i)
              end
              dataset[consortium]['extended_gc_goals'] << future_goals[consortium][i+1][:goal]
              rowno += 1
              append_x_data(dataset, rowno, future_goals[consortium][i+1][:date], consortium, i)
            elsif number_of_month_diffences == 1
              dataset[consortium]['extended_gc_goals'] << future_goals[consortium][i+1][:goal]
              rowno += 1
              append_x_data(dataset, rowno, future_goals[consortium][i+1][:date], consortium, i)
            end

            if future_goals[consortium][i+1][:date] == last_date
              break
            end
          end
        end
      end
    end

    return dataset
  end


  def append_x_data(dataset, rowno, date, consortium, i)
    if rowno%2 == 0
      dataset[consortium]['x_data_extended'].append([rowno, "#{Date::ABBR_MONTHNAMES[date.month]}-#{date.year.to_s[2..3]}"])
    else
      dataset[consortium]['x_data_extended'].append([rowno,''])
    end
  end


  def draw_all_graphs(graph)
    one_width = []
    index = 0
    graph.each do |consortium, graph_data|
      x_data_lables = graph_data['x_data']
      x_data_lables_to_2016 = graph_data['x_data_extended']
      mi_max = (([graph_data['mi_data'].max, graph_data['mi_goal_data'].max].max / 40) + 1) * 40
      gc_max = (([graph_data['gc_data'].max, graph_data['gc_goal_data'].max].max / 40) + 1) * 40
      extended_gc_max = (([graph_data['gc_data'].max, graph_data['gc_goal_data'].max, graph_data['extended_gc_goals'].max].max / 40) + 1) * 40
      one_width << [(graph_data['mi_data'].count + 2) * 40 , 600].max
      draw_graph({:title => "#{consortium} Total Microinjections",
                  :legend => ['Total Mouse Production (Genes)','Mouse Production Goals (Genes)', 'Below', 'Above'],
                  :pointer_marker => x_data_lables,
                  :data => graph_data,
                  :line_data_plots => ['mi_data', 'mi_goal_data'],
                  :area_data_plots => ['pos_mi_diff_data', 'neg_mi_diff_data']
                 },
                 {:name => 'mi',
                  :colour => ['#009966', '#6886B4', '#FFCC00', '#000DCC'],
                  :width => one_width[index],
                  :height => 380, :min_value => 0,
                  :max_value => mi_max,
                  :consortium => consortium}
                )

      draw_graph({:title => "#{consortium} Genotype Confirmed Mouse Production",
                  :legend => ['Total Genotype Confirmed Mice (Genes)','Genotype Confirmed Goals (Genes)', 'Cre Excision Complete Mice (Genes)', 'Below', 'Above'],
                  :pointer_marker => x_data_lables,
                  :data => graph_data,
                  :line_data_plots => ['gc_data', 'gc_goal_data', 'cre_excised_data'],
                  :area_data_plots => ['pos_gc_diff_data', 'neg_gc_diff_data'],
                 },
                 {:name => 'gc',
                  :colour => ['#009966', '#6886B4','#662266', '#FFCC00', '#000DCC'],
                  :width => one_width[index],
                  :height =>380, :min_value => 0,
                  :max_value => gc_max,
                  :consortium => consortium}
                )

      draw_graph({:title => "#{consortium} Genotype Confirmed Mouse Production (inc 2016 goals)",
                  :legend => ['Total Genotype Confirmed Mice (Genes)','Genotype Confirmed Goals (Genes)', 'Cre Excision Complete Mice (Genes)', 'Below', 'Above'],
                  :pointer_marker => x_data_lables_to_2016,
                  :data => graph_data,
                  :line_data_plots => ['gc_data', 'extended_gc_goals', 'cre_excised_data'],
                  :area_data_plots => ['pos_gc_diff_data', 'neg_gc_diff_data'],
                 },
                 {:name => 'all_inc_gc',
                  :colour => ['#009966', '#6886B4','#662266', '#FFCC00', '#000DCC'],
                  :width => one_width[index],
                  :height =>380, :min_value => 0,
                  :max_value => extended_gc_max,
                  :consortium => consortium}
                )
      index += 1
    end
    return one_width
  end

  def draw_graph(graph = {:title => '', :legend => ['',''], :pointer_marker => [], :data => {}, :line_data_plots => [], :area_data_plots => [], }, render = {:name => '', :colour => ['#009966', '#6886B4','#662266', '#FFCC00', '#000DCC'], :width => 600, :min_value => 0, :max_value => 500, :consortium => ''})
    format = 'jpeg'

    mi_graph = Scruffy::Graph.new(:title => graph[:title], :point_markers => graph[:pointer_marker], :point_markers_rotation => 90)
    mi_graph.theme = Scruffy::Themes::Base.new({:background => [:white, :white], :colors => render[:colour], :marker => :black})
    layers = []
    layer_count = 0
    if graph.has_key?(:line_data_plots)
      graph[:line_data_plots].each do |data2|
        layers << mi_graph.add(:line, graph[:legend][layer_count], graph[:data][data2], :stroke_width => 3, :dots => true)
        layer_count += 1
      end
    end
    if graph.has_key?(:area_data_plots)
      graph[:area_data_plots].each do |data2|
        layers << mi_graph.add(:area, graph[:legend][layer_count], graph[:data][data2])
        layer_count += 1
      end
    end
    mi_graph.renderer = Scruffy::Renderers::Base.new
    mi_graph.renderer.components << Scruffy::Components::Title.new(:title, :position => [5, 0], :size => [90, 7])
    mi_graph.renderer.components << Scruffy::Components::Viewport.new(:view, :position => [2, 26], :size => [89, 61], :layers => layers.reverse) do |graph|
      graph << Scruffy::Components::ValueMarkers.new(:values, :position => [0, 22], :size => [10, 75])
      graph << Scruffy::Components::Grid.new(:grid, :position => [12, 20], :size => [92, 75], :stroke_width => 1, :markers => 5)
      graph << Scruffy::Components::DataMarkers.new(:labels, :position => [12, 102], :size => [92, 8])
      graph << Scruffy::Components::Graphs.new(:graphs, :position => [12, 20], :size => [92, 75])
    end
    mi_graph.renderer.components << Scruffy::Components::Legend.new(:legend, :position => [12, 10], :size => [70, 70], :vertical_legend => true)
    charts_folder = File.join(Rails.application.config.paths['tmp'].first, "reports/impc_graph_report_display/charts")
    file_name = File.join("#{render[:consortium].downcase}_#{render[:name]}_performance#{Time.now.strftime "%Y%m%d%H%M%S"}-#{rand(100)}.#{format}")
    file_path = File.join(charts_folder, file_name)
    FileUtils.mkdir_p File.dirname(file_path)
    mi_graph.render(:size => [render[:width],render[:height]], :min_value => render[:min_value], :max_value => render[:max_value], :to => file_path, :as => "#{format}")

    if !@chart_file_names.has_key?(render[:consortium].downcase)
      @chart_file_names[render[:consortium].downcase] = {}
    end
    @chart_file_names[render[:consortium].downcase][render[:name]] = file_name
  end

  def self.clear_charts_in_tmp_folder
    Dir.glob("#{Rails.application.config.paths['tmp'].first}/reports/impc_graph_report_display/charts/*.jpeg") do |file|
      if File.file?(file)
        if File.atime(file) < (Time.now - 30.minutes)
          File.delete(file)
        end
      end
    end
  end

end
