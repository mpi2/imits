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

  def pretty_print_assigned_mi_plans
    html = []
    self.mi_plans
      .where( :mi_plan_status_id => MiPlanStatus.find_by_name!('Assigned').id )
      .without_active_mi_attempt
      .each do |mi_plan|
        string = "[#{mi_plan.consortium.name}"
        string << ":#{mi_plan.production_centre.name}" unless mi_plan.production_centre_id.nil?
        string << "]"
        html.push(string)
    end
    return html.join(' ').html_safe
  end

  def pretty_print_mi_attempts_in_progress
    return pretty_print_mi_attempts_helper(:in_progress)
  end

  def pretty_print_mi_attempts_genotype_confirmed
    return pretty_print_mi_attempts_helper(:genotype_confirmed)
  end

  def pretty_print_mi_attempts_helper(method)
    mi_counts = {}

    self.mi_attempts.send(method).each do |mi_attempt|
      key = "#{mi_attempt.mi_plan.consortium.name}:#{mi_attempt.mi_plan.production_centre.name}"
      if mi_counts[key].nil?
        mi_counts[key] = 1
      else
        mi_counts[key] = mi_counts[key] + 1
      end
    end

    html = []
    mi_counts.each do |key,count|
      html.push("[#{key}:#{count}]")
    end
    return html.join(' ').html_safe
  end

  private(:pretty_print_mi_attempts_helper)

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

end

# == Schema Information
# Schema version: 20110802094958
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

