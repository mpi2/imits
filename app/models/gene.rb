class Gene < ActiveRecord::Base
  acts_as_reportable

  has_many :mi_plans
  has_many :mi_attempts, :through => :mi_plans
  has_many :phenotype_attempts, :through => :mi_plans
  has_many :mouse_allele_mods, :through => :mi_plans
  has_many :phenotyping_productions, :through => :mi_plans
  has_many :notifications
  has_many :contacts, :through => :notifications

  has_many :allele, :class_name => 'TargRep::Allele'

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

  def relevant_status
    @selected_status = Hash.new

    self.mi_plans.each do |plan|
      this_status = plan.relevant_status_stamp

      if @selected_status.empty?
        @selected_status = this_status

      elsif (this_status[:order_by] > @selected_status[:order_by]) or ( this_status[:order_by] == @selected_status[:order_by] and this_status[:date] < @selected_status[:date])
        @selected_status = this_status

      end
    end

    return @selected_status
  end

  def relevant_plan
    this_plan = nil
    @selected_status = Hash.new

    self.mi_plans.each do |plan|

      this_status = plan.relevant_status_stamp

      if @selected_status.empty?
        this_plan = plan
        @selected_status = this_status

      elsif (this_status[:order_by] > @selected_status[:order_by]) or ( this_status[:order_by] == @selected_status[:order_by] and this_status[:date] < @selected_status[:date])
        @selected_status = this_status
        this_plan = plan

      end
    end

    return this_plan
  end


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

# mi_plan summaries and pretty formatting
  def assigned_mi_plans
    return @assigned_mi_plans ||= self.gene_production_summary(self.id, 'assigned plans')
  end

  def non_assigned_mi_plans
    return @non_assigned_mi_plans ||= self.gene_production_summary(self.id, 'non assigned plans')
  end

  def pretty_print_assigned_mi_plans
    return @pretty_print_assigned_mi_plans ||= self.gene_production_summary(self.id, 'pretty assigned plans')
  end

  def pretty_print_non_assigned_mi_plans
    return @pretty_print_non_assigned_mi_plans ||= self.gene_production_summary(self.id, 'pretty non assigned plans')
  end

  def pretty_print_mi_attempts_in_progress
    return @pretty_print_mi_attempts_in_progress ||= self.gene_production_summary(self.id, 'pretty in progress mi attempts')
  end

  def pretty_print_mi_attempts_genotype_confirmed
    return @pretty_print_mi_attempts_genotype_confirmed ||= self.gene_production_summary(self.id, 'pretty genotype confirmed mi attempts')
  end

  def pretty_print_aborted_mi_attempts
    return @pretty_print_aborted_mi_attempts ||= self.gene_production_summary(self.id, 'pretty aborted mi attempts')
  end

  def pretty_print_phenotype_attempts
    return @pretty_print_phenotype_attempts ||= self.gene_production_summary(self.id, 'pretty phenotype attempts')
  end

# generate all mi_plan summary attributes
  def gene_production_summary(gene_ids = nil, return_value = nil)
    gene_ids = [gene_ids] if !gene_ids.kind_of?(Array)
    result = self.class.gene_production_summary(gene_ids)

    @assigned_mi_plans = self.class.assigned_mi_plans_in_bulk(nil, result['assigned plans'])[self.marker_symbol]
    @non_assigned_mi_plans = self.class.non_assigned_mi_plans_in_bulk(nil, result['non assigned plans'])[self.marker_symbol]
    @pretty_print_assigned_mi_plans = self.class.pretty_print_assigned_mi_plans_in_bulk(nil, result['assigned plans'])[self.marker_symbol]
    @pretty_print_non_assigned_mi_plans = self.class.pretty_print_non_assigned_mi_plans_in_bulk(nil, result['non assigned plans'])[self.marker_symbol]
    @pretty_print_mi_attempts_in_progress = self.class.pretty_print_mi_attempts_in_bulk_helper(nil, nil, nil, result['in progress mi attempts'])[self.marker_symbol]
    @pretty_print_mi_attempts_genotype_confirmed = self.class.pretty_print_mi_attempts_in_bulk_helper(nil, nil, nil, result['genotype confirmed mi attempts'])[self.marker_symbol]
    @pretty_print_aborted_mi_attempts = self.class.pretty_print_mi_attempts_in_bulk_helper(nil, nil, nil, result['aborted mi attempts'])[self.marker_symbol]
    @pretty_print_phenotype_attempts = self.class.pretty_print_phenotype_attempts_in_bulk_helper(nil, result['phenotype attempts'])[self.marker_symbol]

    case return_value
    when 'assigned plans'
      return @assigned_mi_plans
    when 'non assigned plans'
      return @non_assigned_mi_plans
    when 'pretty assigned plans'
      return @pretty_print_assigned_mi_plans
    when 'pretty non assigned plans'
      return @pretty_print_non_assigned_mi_plans
    when 'pretty in progress mi attempts'
      return @pretty_print_mi_attempts_in_progress
    when 'pretty genotype confirmed mi attempts'
      return @pretty_print_mi_attempts_genotype_confirmed
    when 'pretty aborted mi attempts'
      return @pretty_print_aborted_mi_attempts
    when 'pretty phenotype attempts'
      return @pretty_print_phenotype_attempts
    else
      return result
    end
  end


# CLASS METHODS
# mi_plan summarys for a list of genes
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

# mi_plan summary formatting
  def self.non_assigned_mi_plans_in_bulk(gene_ids = nil, result = nil)
    gene_ids = [gene_ids] if (!gene_ids.kind_of?(Array)) and (!gene_ids.nil?)
    result = self.gene_production_summary(gene_ids, 'non assigned plans') if result.nil?

    genes = {}
    result.each do |mi_plan_id, res|
      genes[ res[:marker_symbol] ] ||= []
      genes[ res[:marker_symbol] ] << {
        :id => mi_plan_id.to_i,
        :consortium => res[:consortium],
        :production_centre => res[:centre],
        :status_name => res[:status_name],
        :mi_plan => mi_plan_id
      }
    end

    return genes
  end

  def self.assigned_mi_plans_in_bulk(gene_ids = nil, result = nil)
    gene_ids = [gene_ids] if (!gene_ids.kind_of?(Array)) and (!gene_ids.nil?)
    result = self.gene_production_summary(gene_ids, 'assigned plans') if result.nil?

    genes = {}
    result.each do |mi_plan_id, res|
      genes[ res[:marker_symbol] ] ||= []
      genes[ res[:marker_symbol] ] << {
        :id => mi_plan_id.to_i,
        :consortium => res[:consortium],
        :production_centre => res[:centre],
        :status_name => res[:status_name],
        :mi_plan => mi_plan_id
      }
    end

    return genes
  end


  def self.pretty_print_non_assigned_mi_plans_in_bulk(gene_id=nil, result = nil)
    data = Gene.non_assigned_mi_plans_in_bulk(gene_id, result)

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

  def self.pretty_print_assigned_mi_plans_in_bulk(gene_id=nil, result = nil)
    data = Gene.assigned_mi_plans_in_bulk(gene_id, result)

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


  def self.pretty_print_mi_attempts_in_bulk_helper(active, statuses, gene_ids = nil, result = nil)
    gene_ids = [gene_ids] if (!gene_ids.kind_of?(Array)) and (!gene_ids.nil?)

    if result.nil?
      if active

        if statuses.count == 1

          if statuses.map{|status| status.name}.include?('Genotype confirmed')
            result = self.gene_production_summary(gene_ids, 'genotype confirmed mi attempts')
          else
           result = self.gene_production_summary(gene_ids, 'in progress mi attempts')
          end

        else
          result = self.gene_production_summary(gene_ids, 'full_data', statuses)
        end

      else
        result = self.gene_production_summary(gene_ids, 'aborted mi attempts')
      end
    end

    genes = {}
    result.each do |mi_plan_id, res|
      string = "[#{res[:consortium]}:#{res[:centre]}:#{res[:status_count]}]"
      genes[ res[:marker_symbol] ] ||= []
      genes[ res[:marker_symbol] ] << string
    end

    genes.each { |marker_symbol,values| genes[marker_symbol] = values.join('<br/>') }

    return genes
  end


  def self.pretty_print_phenotype_attempts_in_bulk_helper(gene_ids = nil, result = nil)
    gene_ids = [gene_ids] if (!gene_ids.kind_of?(Array)) and (!gene_ids.nil?)
    result = self.gene_production_summary(gene_ids, 'phenotype attempts') if result.nil?

    genes = {}
    result.each do |mi_plan_id, res|
      string = "[#{res[:consortium]}:#{res[:centre]}:#{res[:status_count].to_s}]"
      genes[ res[:marker_symbol] ] ||= []
      genes[ res[:marker_symbol] ] << string
    end

    genes.each { |marker_symbol,values| genes[marker_symbol] = values.join('<br/>') }

    return genes
  end


# mi_plan summary SQL query.
  def self.gene_production_summary(gene_ids = nil, return_value = nil, statuses = nil)

    sql = <<-EOF

      WITH status_summary AS (

      SELECT production_summary.mi_plan_id, production_summary.gene_id, production_summary.consortium_id, production_summary.production_centre_id, production_summary.status_name, count(production_summary.mi_plan_id) AS status_count
      FROM
      (
        (SELECT mi_plans.id AS mi_plan_id, mi_plans.gene_id, mi_plans.consortium_id, mi_plans.production_centre_id, CASE WHEN mi_attempt_statuses.name IS NOT NULL THEN mi_attempt_statuses.name ELSE mi_plan_statuses.name END AS status_name
         FROM mi_plans
           JOIN mi_plan_statuses ON mi_plans.status_id = mi_plan_statuses.id
           LEFT JOIN (mi_attempts JOIN mi_attempt_statuses ON mi_attempts.status_id = mi_attempt_statuses.id) ON mi_plans.id = mi_attempts.mi_plan_id
         #{gene_ids.nil? ? "" : "WHERE mi_plans.gene_id IN (#{gene_ids.join(', ')})"}
        )

        UNION ALL

        (SELECT mi_plans.id AS mi_plan_id, mi_plans.gene_id, mi_plans.consortium_id, mi_plans.production_centre_id,
                CASE
                  WHEN phenotyping_production_statuses.name = 'Phenotype Production Aborted' AND (mouse_allele_mod_statuses.name IS NULL OR mouse_allele_mod_statuses.name = 'Mouse Allele Modification Aborted')
                    THEN 'Phenotype Attempt Aborted'
                 WHEN phenotyping_production_statuses.name IS NOT NULL AND (mouse_allele_mod_statuses.name IS NULL OR phenotyping_production_statuses.order_by > mouse_allele_mod_statuses.order_by)
                   THEN phenotyping_production_statuses.name
                 WHEN mouse_allele_mod_statuses.name = 'Mouse Allele Modification Aborted'
                   THEN 'Phenotype Attempt Aborted'
                 ELSE mouse_allele_mod_statuses.name
               END AS status_name

         FROM mi_plans

           LEFT JOIN (mouse_allele_mods JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id) ON mouse_allele_mods.mi_plan_id = mi_plans.id
           LEFT JOIN (phenotyping_productions JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = phenotyping_productions.status_id JOIN mouse_allele_mods AS mam2 ON mam2.id = phenotyping_productions.mouse_allele_mod_id) ON phenotyping_productions.mi_plan_id = mi_plans.id
           JOIN mi_attempts ON (mi_attempts.id = mouse_allele_mods.mi_attempt_id OR mi_attempts.id = mam2.mi_attempt_id)

         WHERE mi_attempts.is_active = true AND (mouse_allele_mods.id IS NOT NULL OR phenotyping_productions.id IS NOT NULL)
           #{gene_ids.nil? ? "" : "AND mi_plans.gene_id IN (#{gene_ids.join(', ')})"}
        )
      ) AS production_summary
      #{statuses.nil? ? "" : "WHERE production_summary.status_name IN ('#{statuses.map{|status| status.name}.join("','")}')"}
      GROUP BY production_summary.mi_plan_id, production_summary.gene_id, production_summary.consortium_id, production_summary.production_centre_id, production_summary.status_name
      )

      SELECT genes.marker_symbol AS marker_symbol, consortia.name AS consortium, centres.name AS centre, status_summary.status_name AS status_name, status_summary.mi_plan_id AS mi_plan_id, status_summary.status_count AS status_count
      FROM status_summary
        JOIN genes ON genes.id = status_summary.gene_id
        JOIN consortia ON consortia.id = status_summary.consortium_id
        LEFT JOIN centres ON centres.id = status_summary.production_centre_id
      ORDER BY genes.marker_symbol, status_summary.status_name, consortia.name, centres.name
    EOF

    result = ActiveRecord::Base.connection.execute(sql)

    data = {}
    data['full_data'] = {}
    data['assigned plans'] = {}
    data['non assigned plans'] = {}
    data['in progress mi attempts'] = {}
    data['genotype confirmed mi attempts'] = {}
    data['aborted mi attempts'] = {}
    data['phenotype attempts'] = {}

    result.each do |production_record|

      if !data['full_data'].has_key?(production_record['mi_plan_id'])
        data['full_data'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_count => 0}
      end
      data['full_data'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i


      if ['Micro-injection in progress', 'Chimeras obtained'].include?(production_record['status_name'])
        if !data['in progress mi attempts'].has_key?(production_record['mi_plan_id'])
          data['in progress mi attempts'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => 0}
        end
        data['in progress mi attempts'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i

      elsif ['Genotype confirmed'].include?(production_record['status_name'])
        if !data['genotype confirmed mi attempts'].has_key?(production_record['mi_plan_id'])
          data['genotype confirmed mi attempts'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => 0}
        end
        data['genotype confirmed mi attempts'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i

      elsif ['Micro-injection aborted'].include?(production_record['status_name'])
        if !data['aborted mi attempts'].has_key?(production_record['mi_plan_id'])
          data['aborted mi attempts'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => 0}
        end
        data['aborted mi attempts'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i

      elsif ['Phenotype Attempt Registered', 'Rederivation Started', 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete', 'Phenotyping Started', 'Phenotyping Complete', 'Phenotype Attempt Aborted'].include?(production_record['status_name'])
        if !data['phenotype attempts'].has_key?(production_record['mi_plan_id'])
          data['phenotype attempts'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => 0}
        end
        data['phenotype attempts'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i

      elsif ['Assigned', 'Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete'].include?(production_record['status_name'])
        if !data['assigned plans'].has_key?(production_record['mi_plan_id'])
          data['assigned plans'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => 0}
        end
        data['assigned plans'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i

      elsif !['Inactive'].include?(production_record['status_name'])
        if !data['non assigned plans'].has_key?(production_record['mi_plan_id'])
          data['non assigned plans'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => 0}
        end
        data['non assigned plans'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i
      end
    end
    return return_value.nil? ? data : data[return_value]
  end


# other class methods
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

