class Gene < ActiveRecord::Base
  acts_as_reportable

  has_many :es_cells
  has_many :mi_plans
  has_many :mi_attempts, :through => :mi_plans

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
    return html.join('</br>').html_safe
  end

  def pretty_print_non_assigned_mi_plans
    html = Gene.pretty_print_non_assigned_mi_plans_in_bulk(self.id)[self.marker_symbol]
    return html ? html.html_safe : nil
  end

  def pretty_print_assigned_mi_plans
    html = Gene.pretty_print_assigned_mi_plans_in_bulk(self.id)[self.marker_symbol]
    return html ? html.html_safe : nil
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

  def self.pretty_print_non_assigned_mi_plans_in_bulk(gene_id=nil)
    sql = <<-SQL
      select distinct
        genes.marker_symbol,
        consortia.name as consortium,
        centres.name as production_centre,
        mi_plan_statuses.name as status
      from genes
      join mi_plans on mi_plans.gene_id = genes.id
      join mi_plan_statuses on mi_plans.mi_plan_status_id = mi_plan_statuses.id
      join consortia on mi_plans.consortium_id = consortia.id
      left join centres on mi_plans.production_centre_id = centres.id
      where mi_plan_statuses.name != 'Assigned'
    SQL
    sql << "and genes.id = #{gene_id}" unless gene_id.nil?

    genes = {}
    results = ActiveRecord::Base.connection.execute(sql)
    results.each do |res|
      string = "[#{res['consortium']}"
      string << ":#{res['production_centre']}" unless res['production_centre'].nil?
      string << ":#{res['status']}"
      string << "]"
      genes[ res['marker_symbol'] ] ||= []
      genes[ res['marker_symbol'] ] << string
    end

    genes.each do |marker_symbol,values|
      genes[marker_symbol] = values.join('</br>')
    end

    return genes
  end

  def self.pretty_print_assigned_mi_plans_in_bulk(gene_id=nil)
    sql = <<-SQL
      select distinct
        genes.marker_symbol,
        consortia.name as consortium,
        centres.name as production_centre
      from genes
      join mi_plans on mi_plans.gene_id = genes.id
      join mi_plan_statuses on mi_plans.mi_plan_status_id = mi_plan_statuses.id
      join consortia on mi_plans.consortium_id = consortia.id
      left join centres on mi_plans.production_centre_id = centres.id
      left join mi_attempts on mi_attempts.mi_plan_id = mi_plans.id
      where mi_plan_statuses.name = 'Assigned'
      and mi_attempts.id is null
    SQL
    sql << "and genes.id = #{gene_id}" unless gene_id.nil?

    genes = {}
    results = ActiveRecord::Base.connection.execute(sql)
    results.each do |res|
      string = "[#{res['consortium']}"
      string << ":#{res['production_centre']}" unless res['production_centre'].nil?
      string << "]"
      genes[ res['marker_symbol'] ] ||= []
      genes[ res['marker_symbol'] ] << string
    end

    genes.each do |marker_symbol,values|
      genes[marker_symbol] = values.join('</br>')
    end

    return genes
  end

  def self.pretty_print_mi_attempts_in_progress_in_bulk(gene_id=nil)
    return pretty_print_mi_attempts_helper('true','Micro-injection in progress',gene_id)
  end

  def self.pretty_print_mi_attempts_genotype_confirmed_in_bulk(gene_id=nil)
    return pretty_print_mi_attempts_helper('true','Genotype confirmed',gene_id)
  end

  def self.pretty_print_aborted_mi_attempts_in_bulk(gene_id=nil)
    return pretty_print_mi_attempts_helper('false',nil,gene_id)
  end

  private

  def self.pretty_print_mi_attempts_helper(active,status,gene_id=nil)
    sql = <<-SQL
      select
        genes.marker_symbol,
        consortia.name as consortium,
        centres.name as production_centre,
        count(mi_attempts.id) as count
      from genes
      join mi_plans on mi_plans.gene_id = genes.id
      join consortia on mi_plans.consortium_id = consortia.id
      join centres on mi_plans.production_centre_id = centres.id
      join mi_attempts on mi_attempts.mi_plan_id = mi_plans.id
      join mi_attempt_statuses on mi_attempt_statuses.id = mi_attempts.mi_attempt_status_id
    SQL
    sql << "where mi_attempts.is_active = #{active} "
    sql << "and mi_attempt_statuses.description = '#{status}' " unless status.nil?
    sql << "and genes.id = #{gene_id} " unless gene_id.nil?
    sql << "group by genes.marker_symbol, consortia.name, centres.name"

    genes = {}
    results = ActiveRecord::Base.connection.execute(sql)
    results.each do |res|
      string = "[#{res['consortium']}:#{res['production_centre']}:#{res['count']}]"
      genes[ res['marker_symbol'] ] ||= []
      genes[ res['marker_symbol'] ] << string
    end

    genes.each { |marker_symbol,values| genes[marker_symbol] = values.join('</br>') }

    return genes
  end

  public

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
      :attributes => ['mgi_accession_id','pipeline','escell_clone','mutation_subtype'],
      :required_attributes => ['escell_clone','mutation_subtype']
    )

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

    # create new genes
    new_mgi_ids_to_create = all_remote_mgi_accession_ids - all_current_mgi_accession_ids
    if new_mgi_ids_to_create.size > 0
      logger.debug "[Gene.sync_with_remotes] Gathering data for #{new_mgi_ids_to_create.size} new gene(s)..."
      new_genes_data = {}
      new_mgi_ids_to_create.each_slice(1000) { |slice| new_genes_data.merge!( get_gene_data_from_remotes(slice) ) }
      new_genes_data.each do |mgi_accession_id,gene_data|
        logger.debug "[Gene.sync_with_remotes] Creating gene entry for #{mgi_accession_id}"
        Gene.create!(gene_data)
      end
    else
      logger.debug "[Gene.sync_with_remotes] No new genes need to be created..."
    end

    # update existing genes
    logger.debug "[Gene.sync_with_remotes] Gathering data for existing genes to see if they need updating..."
    current_genes_data = {}
    all_current_mgi_accession_ids.each_slice(1000) { |slice| current_genes_data.merge!( get_gene_data_from_remotes(slice) ) }
    current_genes_data.each do |mgi_accession_id,gene_data|
      current_gene = Gene.find_by_mgi_accession_id(mgi_accession_id)

      do_update = false
      gene_data.each { |key,value| do_update = true if value != current_gene.send(key) }

      if do_update
        logger.debug "[Gene.sync_with_remotes] Updating information for #{current_gene.mgi_accession_id}"
        current_gene.update_attributes!(gene_data)
      end
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

  private

  def default_serializer_options(options = {})
    options ||= {}
    options.symbolize_keys!
    options[:methods] ||= [
      :pretty_print_types_of_cells_available,
      :pretty_print_non_assigned_mi_plans,
      :pretty_print_assigned_mi_plans,
      :pretty_print_mi_attempts_in_progress,
      :pretty_print_mi_attempts_genotype_confirmed,
      :pretty_print_aborted_mi_attempts
    ]
    options[:except] ||= PRIVATE_ATTRIBUTES.dup + []
    return options
  end

end

# == Schema Information
# Schema version: 20110922103626
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
#  index_genes_on_marker_symbol  (marker_symbol) UNIQUE
#

