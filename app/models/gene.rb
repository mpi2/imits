class Gene < ActiveRecord::Base
  acts_as_reportable

  has_many :mi_plans
  has_many :mi_attempts, :through => :mi_plans
  has_many :phenotype_attempts, :through => :mi_plans

  has_many :notifications
  has_many :contacts, :through => :notifications

  has_many :allele, :class_name => "TargRep::Allele"

  validates :marker_symbol, :presence => true, :uniqueness => true

  # BEGIN Helper functions for clean reporting

  def pretty_print_types_of_cells_available
    html = []
    {
      :conditional_es_cells_count     => 'Knockout First, Tm1a',
      :non_conditional_es_cells_count => 'Targeted Trap',
      :deletion_es_cells_count        => 'Deletion'
    }.each do |method,type|
      html.push("#{self.send(method)} #{type}") unless self.send(method).nil?
    end
    return html.join('<br/>').html_safe
  end

  def pretty_print_mi_attempts_in_progress
    return Gene.pretty_print_mi_attempts_in_progress_in_bulk(self.id)[self.marker_symbol]
  end

  def pretty_print_mi_attempts_genotype_confirmed
    return Gene.pretty_print_mi_attempts_genotype_confirmed_in_bulk(self.id)[self.marker_symbol]
  end

  def pretty_print_aborted_mi_attempts
    return Gene.pretty_print_aborted_mi_attempts_in_bulk(self.id)[self.marker_symbol]
  end

  def pretty_print_phenotype_attempts
    return Gene.pretty_print_phenotype_attempts_in_bulk(self.id)[self.marker_symbol]
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
      join mi_plans on mi_plans.gene_id = genes.id
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

  def non_assigned_mi_plans
    Gene.non_assigned_mi_plans_in_bulk(self.id)[self.marker_symbol]
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

  def pretty_print_non_assigned_mi_plans
    Gene.pretty_print_non_assigned_mi_plans_in_bulk(self.id)[self.marker_symbol]
  end

  # == Assigned MiPlans

  def self.assigned_mi_plans_in_bulk(gene_id=nil)
    sql = <<-"SQL"
      select distinct
        mi_plans.id,
        genes.marker_symbol,
        consortia.name as consortium,
        centres.name as production_centre
      from genes
      join mi_plans on mi_plans.gene_id = genes.id
      join mi_plan_statuses on mi_plans.status_id = mi_plan_statuses.id
      join consortia on mi_plans.consortium_id = consortia.id
      left join centres on mi_plans.production_centre_id = centres.id
      left join mi_attempts on mi_attempts.mi_plan_id = mi_plans.id
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

  def assigned_mi_plans
    Gene.assigned_mi_plans_in_bulk(self.id)[self.marker_symbol]
  end

  def self.pretty_print_assigned_mi_plans_in_bulk(gene_id=nil)
    data = Gene.assigned_mi_plans_in_bulk(gene_id)

    data.each do |marker_symbol,mi_plans|
      strings = mi_plans.map do |mip|
        string = "[#{mip[:consortium]}"
        string << ":#{mip[:production_centre]}" unless mip[:production_centre].nil?
        string << "]"
      end
      data[marker_symbol] = strings.join('<br/>').html_safe
    end

    return data
  end

  def pretty_print_assigned_mi_plans
    Gene.pretty_print_assigned_mi_plans_in_bulk(self.id)[self.marker_symbol]
  end


  def self.pretty_print_mi_attempts_in_progress_in_bulk(gene_id = nil)
    return pretty_print_mi_attempts_in_bulk_helper(true, [MiAttempt::Status.micro_injection_in_progress, MiAttempt::Status.chimeras_obtained], gene_id)
  end

  def self.pretty_print_mi_attempts_genotype_confirmed_in_bulk(gene_id = nil)
    return pretty_print_mi_attempts_in_bulk_helper(true, [MiAttempt::Status.genotype_confirmed], gene_id)
  end

  def self.pretty_print_aborted_mi_attempts_in_bulk(gene_id=nil)
    return pretty_print_mi_attempts_in_bulk_helper(false, [], gene_id)
  end

  def self.pretty_print_phenotype_attempts_in_bulk(gene_id = nil)
    return pretty_print_phenotype_attempts_in_bulk_helper(gene_id)
  end

  def relevant_status
    @selected_status = Hash.new

    self.mi_plans.each do |plan|
      this_status = plan.relevant_status_stamp

      if @selected_status.empty?
        @selected_status = this_status

      elsif this_status[:order_by] > @selected_status[:order_by]
        @selected_status = this_status

      end
    end

    return @selected_status
  end

  def self.pretty_print_mi_attempts_in_bulk_helper(active, statuses, gene_id = nil)
    sql = <<-"SQL"
      SELECT
        genes.marker_symbol,
        consortia.name AS consortium,
        centres.name AS production_centre,
        count(mi_attempts.id) AS count
      FROM genes
      JOIN mi_plans ON mi_plans.gene_id = genes.id
      JOIN consortia ON mi_plans.consortium_id = consortia.id
      JOIN centres ON mi_plans.production_centre_id = centres.id
      JOIN mi_attempts ON mi_attempts.mi_plan_id = mi_plans.id
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
      JOIN mi_plans ON mi_plans.gene_id = genes.id
      JOIN consortia ON mi_plans.consortium_id = consortia.id
      JOIN centres ON mi_plans.production_centre_id = centres.id
      JOIN phenotype_attempts ON phenotype_attempts.mi_plan_id = mi_plans.id
      JOIN mi_attempts ON mi_attempts.id = phenotype_attempts.mi_attempt_id
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

  # END Helper functions for clean reporting

  def update_cached_counts(logger=Rails.logger)
    self.ikmc_projects_count            = self.allele.select(:ikmc_project_id).joins(:es_cells).group(:ikmc_project_id).length
    self.conditional_es_cells_count     = self.allele.joins(:mutation_type, :es_cells).where(:targ_rep_mutation_types => {:code => :crd}).count
    self.non_conditional_es_cells_count = self.allele.joins(:mutation_type, :es_cells).where(:targ_rep_mutation_types => {:code => :tnc}).count
    self.deletion_es_cells_count        = self.allele.joins(:mutation_type, :es_cells).where(:targ_rep_mutation_types => {:code => :del}).count

    if self.changes.present?
      logged.debug "[@gene.update_cached_counts] Updating gene cached counts..."
      self.save
    end
  end

  def self.update_cached_counts_old(logger=Rails.logger)
    all_genes = Gene.all
    # update existing genes
    logger.debug "[Gene.update_cached_counts] Gathering data for existing genes to see if they need updating..."

    all_genes.each do |gene|
      gene.update_cached_counts
    end

  end

  def self.update_cached_counts(logger=Rails.logger)

    count_clones_by_gene_and_mutation_type_sql = <<-EOF
      SELECT
        targ_rep_alleles.gene_id as gene,
        targ_rep_mutation_types.code as mutation_type,
        ikmc_project_id,
        count(*) as es_cell_count
      FROM targ_rep_es_cells
      INNER JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
      LEFT OUTER JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
      WHERE targ_rep_es_cells.report_to_public is true
      --AND targ_rep_alleles.gene_id = 88
      GROUP BY gene, mutation_type, ikmc_project_id
    EOF

    count_clones_by_gene_and_mutation_type = ActiveRecord::Base.connection.execute(count_clones_by_gene_and_mutation_type_sql).to_a

    count_clones_by_gene_and_mutation_type.group_by {|r| r["gene"]}.each do |gene_id, row_hashes|

      ikmc_projects = []
      conditional_es_cells_count     = 0
      non_conditional_es_cells_count = 0
      deletion_es_cells_count        = 0

      row_hashes.each do |row_hash|
        case row_hash['mutation_type']
          when 'crd'
            conditional_es_cells_count += row_hash['es_cell_count'].to_i
          when 'tnc'
            non_conditional_es_cells_count += row_hash['es_cell_count'].to_i
          when 'del'
            deletion_es_cells_count += row_hash['es_cell_count'].to_i
        end

        unless ikmc_projects.include?(row_hash['ikmc_project_id'])
          ikmc_projects << row_hash['ikmc_project_id']
        end
      end

      Gene.update_all({
        ikmc_projects_count: ikmc_projects.size,
        conditional_es_cells_count: conditional_es_cells_count,
        non_conditional_es_cells_count: non_conditional_es_cells_count,
        deletion_es_cells_count: deletion_es_cells_count,
        updated_at: Time.now.to_s(:db)
      }, {:id => gene_id.to_i})

    end

    true
  end

  # END Mart Operations

  def es_cells_count
    return conditional_es_cells_count.to_i + non_conditional_es_cells_count.to_i + deletion_es_cells_count.to_i
  end

  def as_json(options = {})
    super(default_serializer_options(options))
  end

  def to_xml(options = {})
    super(default_serializer_options(options))
  end

  PRIVATE_ATTRIBUTES = [
    'created_at', 'updated_at', 'updated_by', 'updated_by_id',
  ]

  attr_protected *PRIVATE_ATTRIBUTES

  def default_serializer_options(options = {})
    options ||= {}
    options.symbolize_keys!
    options[:methods] ||= [
      :pretty_print_types_of_cells_available,
      :non_assigned_mi_plans,
      :assigned_mi_plans,
      :pretty_print_mi_attempts_in_progress,
      :pretty_print_mi_attempts_genotype_confirmed,
      :pretty_print_aborted_mi_attempts,
      :pretty_print_phenotype_attempts
    ]
    options[:except] ||= PRIVATE_ATTRIBUTES.dup + []
    return options
  end
  private :default_serializer_options

  def create_extjs_relationship_tree_node(object, extra_attributes = {})
    return {
      'id' => object.id,
      'type' => object.class.name,
      'status' => object.status.name,
      'consortium_name' => object.consortium.name,
      'production_centre_name' => object.production_centre.name
    }.merge(extra_attributes)
  end
  protected :create_extjs_relationship_tree_node

  def to_extjs_relationship_tree_structure
    retval = []

    mi_plans.group_by {|i| i.consortium.name}.each do |consortium_name, consortium_mi_plans|

      consortium_group = {'name' => consortium_name, 'consortium_name' => consortium_name, 'type' => 'Consortium', 'children' => []}
      retval << consortium_group

      consortium_mi_plans.group_by {|i| i.production_centre.name}.each do |production_centre_name, fully_grouped_mi_plans|

        centre_group = {'name' => production_centre_name, 'type' => 'Centre', 'consortium_name' => consortium_name, 'production_centre_name' => production_centre_name, 'children' => []}
        consortium_group['children'] << centre_group

        fully_grouped_mi_plans.each do |plan|
          plan_data = create_extjs_relationship_tree_node(plan,
            'name' => 'Plan',
            'sub_project_name' => plan.sub_project.name,
            'children' => []
          )
          centre_group['children'] << plan_data

          plan.mi_attempts.each do |mi|
            plan_data['children'] << create_extjs_relationship_tree_node(mi,
              'name' => 'MI Attempt',
              'colony_name' => mi.colony_name,
              'mi_plan_id' => mi.mi_plan.id,
              'leaf' => true
            )
          end

          plan.phenotype_attempts.each do |pa|
            plan_data['children'] << create_extjs_relationship_tree_node(pa,
              'name' => 'Phenotype Attempt',
              'colony_name' => pa.colony_name,
              'mi_plan_id' => pa.mi_plan.id,
              'leaf' => true
            )
          end
        end

      end
    end

    return retval
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

