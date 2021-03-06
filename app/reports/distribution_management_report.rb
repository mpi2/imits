class DistributionManagementReport
  include ActionView::Helpers::TagHelper

  attr_accessor :klass, :results, :results_by_distribution

  def initialize(model_table_name)
    @klass = Colony::DistributionCentre
    @model_table_name = model_table_name
    results
  end

  def results
    @results ||= ActiveRecord::Base.connection.execute(raw_sql)
  end

  def results_by_distribution
    return @results_by_distribution if @results_by_distribution
    results_by_distribution = {}

    results.each do |r|
      if row = results_by_distribution["#{r['consortium_name']}-#{r['pc_name']}"]
        row["#{r['distribution_network']}-#{r['dc_name']}"] = r['count']
      else
        results_by_distribution["#{r['consortium_name']}-#{r['pc_name']}"] = {
          "consortium_name" => r['consortium_name'],
          "pc_name" => r['pc_name'],
          "#{r['distribution_network']}-#{r['dc_name']}" => r['count']
        }
      end
    end

    @results_by_distribution = results_by_distribution
  end

  def network_header_columns
    String.new.tap do |s|
      s << content_tag(:td)
      s << content_tag(:td)
      s << content_tag(:td)
      distribution_networks.reverse.each do |dn|
        child_dcs = has_distribution_network(dn).map {|r| r["dc_name"]}.uniq.compact
        s << content_tag(:td, dn || 'No network', :colspan => child_dcs.size)
      end
    end.html_safe
  end

  def centre_header_columns
    String.new.tap do |s|
      s << content_tag(:td)
      s << content_tag(:td)
      s << content_tag(:td, 'No centre')
      distribution_networks.reverse.each do |dn|
        distribution_centres = has_distribution_network(dn).map {|r| r["dc_name"]}.uniq.compact
        if distribution_centres.empty?
          s << content_tag(:td)
        end
        distribution_centres.each do |distribution_centre|
          s << content_tag(:td, distribution_centre)
        end
      end
    end.html_safe
  end

  def consortia
    @results.map {|r| r["consortium_name"]}.uniq
  end

  def production_centres
    @results.map {|r| r["pc_name"]}.uniq
  end

  def distribution_centres
    @results.map {|r| r["dc_name"]}.uniq
  end

  def distribution_networks
    @results.map {|r| r["distribution_network"]}.uniq
  end

  def has_distribution_network(network)
    @results.select {|r| r['distribution_network'] == network}
  end

  def number_of_columns
    number_of_columns = 1
    self.distribution_networks.each do |dn|
      self.has_distribution_network(dn).map {|r| r["dc_name"]}.uniq.compact.each do |dc|
        number_of_columns += 1
      end
    end

    number_of_columns == 1 ? 2 : number_of_columns
  end

  def foreign_key
    @model_table_name.gsub(/s$/, '_id')
  end

  def status_id
    @model_table_name == 'mi_attempts' ? 2 : [6, 7, 8].join(', ')
  end

  def raw_sql
    sql = <<-EOF
      SELECT
      consortia.name AS consortium_name,
      pc.name AS pc_name,
      dc.name AS dc_name,
      midc.distribution_network,
      COUNT(*)
      FROM genes
      JOIN mi_plans ON mi_plans.gene_id = genes.id
      JOIN consortia ON consortia.id = mi_plans.consortium_id
      JOIN centres pc ON mi_plans.production_centre_id = pc.id
      JOIN #{@model_table_name} ON (#{@model_table_name}.mi_plan_id = mi_plans.id and #{@model_table_name}.status_id IN (#{status_id}))
      JOIN colonies ON colonies.#{foreign_key} = #{@model_table_name}.id
      LEFT OUTER JOIN colony_distribution_centres midc ON midc.colony_id = colonies.id
      LEFT OUTER JOIN centres dc ON dc.id = midc.centre_id
      GROUP BY consortium_name, pc_name, midc.distribution_network,dc_name
      ORDER BY  consortium_name, pc_name, midc.distribution_network,dc_name;
    EOF
  end


end
