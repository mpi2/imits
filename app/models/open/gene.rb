class Open::Gene < ::Gene

  # BEGIN Helper functions for clean reporting


  def self.pretty_print_mi_attempts_in_bulk_helper(active, statuses, gene_id = nil)
    sql = <<-"SQL"
      SELECT
        genes.marker_symbol,
        consortia.name AS consortium,
        centres.name AS production_centre,
        count(mi_attempts.id) AS count
      FROM genes
      JOIN mi_plans ON mi_plans.gene_id = genes.id AND mi_plans.report_to_public = true
      JOIN consortia ON mi_plans.consortium_id = consortia.id
      JOIN centres ON mi_plans.production_centre_id = centres.id
      JOIN mi_attempts ON mi_attempts.mi_plan_id = mi_plans.id AND mi_attempts.report_to_public = true
    SQL
    sql << "WHERE mi_attempts.is_active = #{active}\n"
    if ! statuses.empty?
      status_ids_string = statuses.map(&:id).join(', ')
      sql << "AND mi_attempts.status_id IN (#{status_ids_string})\n"
    end
    sql << "AND genes.id = #{gene_id}\n" unless gene_id.nil?
    sql << "group by genes.marker_symbol, consortia.name, centres.name\n"

    genes = {}
    results = ActiveRecord::Base.connection.execute(sql)

    results.each do |result|
      string = "[#{result['consortium']}:#{result['production_centre']}:#{result['count']}]"
      genes[ result['marker_symbol'] ] ||= []
      genes[ result['marker_symbol'] ] << string
    end

    genes.each { |marker_symbol,values| genes[marker_symbol] = values.join('<br/>') }

    return genes
  end

  def self.pretty_print_phenotype_attempts_in_bulk_helper(gene_id = nil)
    #Only interested in active mi_attempts, no specific status set for mi_attempts
    #although they all should be genotype_confirmed

    sql = <<-"SQL"
      SELECT
        genes.marker_symbol,
        consortia.name AS consortium,
        centres.name AS production_centre,
        count(phenotype_attempts.id) AS count
      FROM genes
      JOIN mi_plans ON mi_plans.gene_id = genes.id AND mi_plans.report_to_public = true
      JOIN consortia ON mi_plans.consortium_id = consortia.id
      JOIN centres ON mi_plans.production_centre_id = centres.id
      JOIN phenotype_attempts ON phenotype_attempts.mi_plan_id = mi_plans.id AND phenotype_attempts.report_to_public = true
      JOIN mi_attempts ON mi_attempts.id = phenotype_attempts.mi_attempt_id AND mi_attempts.report_to_public = true
    SQL
    sql << "WHERE mi_attempts.is_active = true\n"
    sql << "AND genes.id = #{gene_id}\n" unless gene_id.nil?
    sql << "group by genes.marker_symbol, consortia.name, centres.name\n"

    genes = {}
    results = ActiveRecord::Base.connection.execute(sql)

    results.each do |result|
      string = "[#{result['consortium']}:#{result['production_centre']}:#{result['count']}]"
      genes[ result['marker_symbol'] ] ||= []
      genes[ result['marker_symbol'] ] << string
    end

    genes.each { |marker_symbol,values| genes[marker_symbol] = values.join('<br/>') }

    return genes
  end


  def self.pretty_print_non_assigned_mi_plans_in_bulk(gene_id=nil)
    data = Gene.non_assigned_mi_plans_in_bulk(gene_id)

    data.each do |marker_symbol,mi_plans|
      strings = mi_plans.map do |mip|
        string = "[#{mip[:consortium]}"
        string << ":#{mip[:production_centre]}" unless mip[:production_centre].nil?
        string << ":#{mip[:status_name]}"
        string << "]"
      end
      data[marker_symbol] = strings.join('<br/>').html_safe
    end

    return data
  end

  # == Non-Assigned MiPlans

  def self.non_assigned_mi_plans_in_bulk(gene_id=nil)
    sql = <<-"SQL"
      select distinct
        mi_plans.id,
        genes.marker_symbol,
        consortia.name as consortium,
        centres.name as production_centre,
        mi_plan_statuses.name as status_name
      from genes
      join mi_plans on mi_plans.gene_id = genes.id AND mi_plans.report_to_public = true
      join mi_plan_statuses on mi_plans.status_id = mi_plan_statuses.id
      join consortia on mi_plans.consortium_id = consortia.id
      left join centres on mi_plans.production_centre_id = centres.id
      where mi_plan_statuses.name in
        (#{MiPlan::Status.all_non_assigned.map {|i| Gene.connection.quote(i.name) }.join(',')})
    SQL
    sql << "and genes.id = #{gene_id}" unless gene_id.nil?

    genes = {}
    results = Gene.connection.execute(sql)
    results.each do |res|
      genes[ res['marker_symbol'] ] ||= []
      genes[ res['marker_symbol'] ] << {
        :id => res['id'].to_i,
        :consortium => res['consortium'],
        :production_centre => res['production_centre'],
        :status_name => res['status_name']
      }
    end

    return genes
  end

  def self.assigned_mi_plans_in_bulk(gene_id=nil)
    sql = <<-"SQL"
      select distinct
        mi_plans.id,
        genes.marker_symbol,
        consortia.name as consortium,
        centres.name as production_centre
      from genes
      join mi_plans on mi_plans.gene_id = genes.id AND mi_plans.report_to_public = true
      join mi_plan_statuses on mi_plans.status_id = mi_plan_statuses.id
      join consortia on mi_plans.consortium_id = consortia.id
      left join centres on mi_plans.production_centre_id = centres.id
      left join mi_attempts on mi_attempts.mi_plan_id = mi_plans.id AND mi_attempts.report_to_public = true
      where mi_plan_statuses.name in
        (#{MiPlan::Status.all_assigned.map {|i| Gene.connection.quote(i.name) }.join(',')})
      and mi_attempts.id is null
    SQL
    sql << "and genes.id = #{gene_id}" unless gene_id.nil?

    genes = {}
    results = ActiveRecord::Base.connection.execute(sql)
    results.each do |res|
      genes[ res['marker_symbol'] ] ||= []
      genes[ res['marker_symbol'] ] << {
        :id => res['id'].to_i,
        :consortium => res['consortium'],
        :production_centre => res['production_centre']
      }
    end

    return genes
  end

end

# == Schema Information
#
# Table name: genes
#
#  id                                 :integer         not null, primary key
#  marker_symbol                      :string(75)      not null
#  mgi_accession_id                   :string(40)
#  ikmc_projects_count                :integer
#  conditional_es_cells_count         :integer
#  non_conditional_es_cells_count     :integer
#  deletion_es_cells_count            :integer
#  other_targeted_mice_count          :integer
#  other_condtional_mice_count        :integer
#  mutation_published_as_lethal_count :integer
#  publications_for_gene_count        :integer
#  go_annotations_for_gene_count      :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#
# Indexes
#
#  index_genes_on_marker_symbol     (marker_symbol) UNIQUE
#  index_genes_on_mgi_accession_id  (mgi_accession_id) UNIQUE
#

