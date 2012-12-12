class Gene < ActiveRecord::Base
  acts_as_reportable

  has_many :es_cells
  has_many :mi_plans
  has_many :mi_attempts, :through => :mi_plans
  has_many :phenotype_attempts, :through => :mi_plans

  has_many :notifications
  has_many :contacts, :through => :notifications

  validates :marker_symbol, :presence => true, :uniqueness => true

  # BEGIN Helper functions for clean reporting

  def pretty_print_types_of_cells_available
    html = []
    {
      :conditional_es_cells_count     => 'Conditional',
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

  # BEGIN Mart Operations

  def self.find_or_create_from_marts_by_mgi_accession_id(mgi_accession_id)
    return nil if mgi_accession_id.blank?

    gene = self.find_by_mgi_accession_id(mgi_accession_id)
    return gene if gene

    mart_data = get_gene_data_from_remotes([mgi_accession_id])

    if mart_data[mgi_accession_id].blank?
      return nil
    else
      return self.find_or_create_by_mgi_accession_id(mart_data[mgi_accession_id])
    end
  end

  def self.get_gene_data_from_remotes(mgi_accession_ids)
    raise ArgumentError, 'Need an array of MGI Accession IDs' unless mgi_accession_ids.kind_of?(Array)
    raise ArgumentError, 'You must specify some MGI Accession IDs to search for' if mgi_accession_ids.empty?

    ikmc_projects = ['KOMP-CSD','KOMP-Regeneron','EUCOMM','NorCOMM','mirKO']
    data          = {}

    # We have to do two seperate queries here as we may be looking for genes that do
    # not have any IKMC products...

    dcc_data = DCC_BIOMART.search(
      :process_results => true,
      :timeout => 600,
      :filters =>  { 'mgi_accession_id' => mgi_accession_ids },
      :attributes => ['mgi_accession_id','marker_symbol','ikmc_project','ikmc_project_id']
    )

    targ_rep_data = TARG_REP_BIOMART.search(
      :process_results => true,
      :timeout => 600,
      :filters => { 'mgi_accession_id' => mgi_accession_ids },
      :attributes => ['mgi_accession_id','pipeline','escell_clone','mutation_subtype','mutation_type'],
      :required_attributes => ['escell_clone','mutation_subtype']
    )

    targ_rep_data.each do |result|
      result['mutation_subtype'] = result['mutation_type'].downcase.gsub(/\s+/, '_') if result['mutation_type']
      result.delete('mutation_type')
    end

    dcc_data.each do |row|
      gene = data[ row['mgi_accession_id'] ] ||= {
        :marker_symbol                    => row['marker_symbol'],
        :mgi_accession_id                 => row['mgi_accession_id'],
        :ikmc_project_id                  => [],
        :conditional_ready                => [],
        :targeted_non_conditional         => [],
        :deletion                         => []
      }

      if ikmc_projects.include?( row['ikmc_project'] )
        gene[:ikmc_project_id].push( row['ikmc_project_id'] )
      end
    end

    targ_rep_data.each do |row|
      gene = data[ row['mgi_accession_id'] ]
      if !gene.nil? and ikmc_projects.include?( row['pipeline'] )
        gene[ row['mutation_subtype'].to_sym ].push( row['escell_clone'] )
      end
    end

    data.each do |mgi_accession_id,gene_details|
      gene_details[:ikmc_projects_count]            = gene_details[:ikmc_project_id].uniq.compact.count
      gene_details[:conditional_es_cells_count]     = gene_details[:conditional_ready].uniq.compact.count
      gene_details[:non_conditional_es_cells_count] = gene_details[:targeted_non_conditional].uniq.compact.count
      gene_details[:deletion_es_cells_count]        = gene_details[:deletion].uniq.compact.count

      [
        :ikmc_projects_count,
        :conditional_es_cells_count,
        :non_conditional_es_cells_count,
        :deletion_es_cells_count
      ].each do |count|
        gene_details[count] = nil if gene_details[count] == 0
      end

      gene_details.delete :ikmc_project_id
      gene_details.delete :conditional_ready
      gene_details.delete :targeted_non_conditional
      gene_details.delete :deletion
    end

    return data
  end

  def self.sync_with_remotes(logger=Rails.logger)
    all_genes                     = Gene.all
    all_current_mgi_accession_ids = all_genes.map(&:mgi_accession_id).compact
    all_remote_mgi_accession_ids  = DCC_BIOMART.search(
      :process_results => true,
      :filters => {},
      :attributes => ['mgi_accession_id'],
      :required_attributes => ['mgi_accession_id']
    ).map { |row| row['mgi_accession_id'] }

    # update existing genes
    logger.debug "[Gene.sync_with_remotes] Gathering data for existing genes to see if they need updating..."
    current_genes_data = {}
    all_current_mgi_accession_ids.each_slice(1000) { |slice| current_genes_data.merge!( get_gene_data_from_remotes(slice) ) }
    current_genes_data.each do |mgi_accession_id, gene_data|
      current_gene = Gene.find_by_mgi_accession_id(mgi_accession_id)

      current_gene.attributes = gene_data

      if current_gene.changes.present?
        logger.debug "[Gene.sync_with_remotes] Updating information for #{current_gene.mgi_accession_id}"
        current_gene.save!
      end
    end

    # create new genes
    new_mgi_ids_to_create = all_remote_mgi_accession_ids - all_current_mgi_accession_ids
    if new_mgi_ids_to_create.size > 0
      logger.debug "[Gene.sync_with_remotes] Gathering data for #{new_mgi_ids_to_create.size} new gene(s)..."
      new_genes_data = {}
      new_mgi_ids_to_create.each_slice(1000) { |slice| new_genes_data.merge!( get_gene_data_from_remotes(slice) ) }
      new_genes_data.each do |mgi_accession_id, gene_data|
        logger.debug "[Gene.sync_with_remotes] Creating gene entry for #{mgi_accession_id}"
        Gene.create!(gene_data)
      end
    else
      logger.debug "[Gene.sync_with_remotes] No new genes need to be created..."
    end

    # remove old genes that are no longer in the DCC_BIOMART - as long as they
    # don't have any mi_plans hanging off them...
    mgi_ids_to_delete = all_current_mgi_accession_ids - all_remote_mgi_accession_ids
    if mgi_ids_to_delete.size > 0
      logger.debug "[Gene.sync_with_remotes] Evaluating #{mgi_ids_to_delete.size} gene(s) for deletion..."
      mgi_ids_to_delete.each do |mgi_accession_id|
        current_gene = Gene.find_by_mgi_accession_id(mgi_accession_id)
        if current_gene.mi_plans.size == 0
          logger.debug "[Gene.sync_with_remotes] Deleting gene data for #{current_gene.mgi_accession_id}"
          current_gene.destroy
        end
      end
    else
      logger.debug "[Gene.sync_with_remotes] No gene entries look like they need to be deleted..."
    end
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

