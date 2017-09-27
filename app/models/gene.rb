class Gene < ActiveRecord::Base
  acts_as_reportable

  has_many :mi_plans
  has_many :mi_attempts, :through => :mi_plans
  has_many :mouse_allele_mods, :through => :mi_plans
  has_many :phenotyping_productions, :through => :mi_plans
  has_many :notifications
  has_many :contacts, :through => :notifications

  has_many :allele, :class_name => 'TargRep::Allele'
  has_many :crispr, :class_name => 'TargRep::Crispr'

  validates :marker_symbol, :presence => true, :uniqueness => true

  before_save :set_cgi_and_gm_feature_types

  # GENE PRODUCTS

  def vectors
    @vectors = @vectors || TargRep::TargetingVector.find_by_sql(retreive_genes_vectors_sql)
  end

  def phenotype_attempts
    phenotyping_productions.map{|pp| pp.phenotype_attempt_id}.uniq.map{|pa_id| Public::PhenotypeAttempt.find(pa_id)}
  end

  def retreive_genes_vectors_sql
    sql = <<-EOF
               WITH gene AS (SELECT genes.* FROM genes WHERE genes.marker_symbol = '#{self.marker_symbol}')

               SELECT targ_rep_alleles.type AS type, targ_rep_targeting_vectors.*
               FROM gene
               JOIN targ_rep_alleles ON targ_rep_alleles.gene_id = gene.id
               JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id
               WHERE targ_rep_targeting_vectors.report_to_public = true
               ORDER BY targ_rep_alleles.type, targ_rep_targeting_vectors.name
             EOF
  end
  private :retreive_genes_vectors_sql


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
    return @assigned_mi_plans ||= self.gene_production_summary({:gene_ids => self.id, :return_value => 'assigned plans'})
  end

  def non_assigned_mi_plans
    return @non_assigned_mi_plans ||= self.gene_production_summary({:gene_ids => self.id, :return_value => 'non assigned plans'})
  end

  def pretty_print_assigned_mi_plans
    return @pretty_print_assigned_mi_plans ||= self.gene_production_summary({:gene_ids => self.id, :return_value => 'pretty assigned plans'})
  end

  def pretty_print_non_assigned_mi_plans
    return @pretty_print_non_assigned_mi_plans ||= self.gene_production_summary({:gene_ids => self.id, :return_value => 'pretty non assigned plans'})
  end

  def pretty_print_mi_attempts_in_progress
    return @pretty_print_mi_attempts_in_progress ||= self.gene_production_summary({:gene_ids => self.id, :return_value => 'pretty in progress mi attempts'})
  end

  def pretty_print_mi_attempts_genotype_confirmed
    return @pretty_print_mi_attempts_genotype_confirmed ||= self.gene_production_summary({:gene_ids => self.id, :return_value => 'pretty genotype confirmed mi attempts'})
  end

  def pretty_print_aborted_mi_attempts
    return @pretty_print_aborted_mi_attempts ||= self.gene_production_summary({:gene_ids => self.id, :return_value => 'pretty aborted mi attempts'})
  end

  def pretty_print_phenotype_attempts
    return @pretty_print_phenotype_attempts ||= self.gene_production_summary({:gene_ids => self.id, :return_value => 'pretty phenotype attempts'})
  end

# generate all mi_plan summary attributes
  def gene_production_summary(options = {})
    gene_ids = options[:gene_ids] || nil
    return_value = options[:return_value] || nil
    crispr = options.has_key?(:crispr) ? options[:crispr] : nil

    gene_ids = [gene_ids] if !gene_ids.kind_of?(Array)
    @result = self.class.gene_production_summary({:gene_ids => gene_ids, :crispr => crispr}) if @result.nil?

    @assigned_mi_plans = self.class.assigned_mi_plans_in_bulk(:result => @result['assigned plans'])[self.marker_symbol]
    @non_assigned_mi_plans = self.class.non_assigned_mi_plans_in_bulk(:result => @result['non assigned plans'])[self.marker_symbol]
    @pretty_print_assigned_mi_plans = self.class.pretty_print_assigned_mi_plans_in_bulk(:result => @result['assigned plans'])[self.marker_symbol]
    @pretty_print_non_assigned_mi_plans = self.class.pretty_print_non_assigned_mi_plans_in_bulk(:result => @result['non assigned plans'])[self.marker_symbol]
    @pretty_print_mi_attempts_in_progress = self.class.pretty_print_mi_attempts_in_bulk_helper(:result => @result['in progress mi attempts'])[self.marker_symbol]
    @pretty_print_mi_attempts_genotype_confirmed = self.class.pretty_print_mi_attempts_in_bulk_helper(:result => @result['genotype confirmed mi attempts'])[self.marker_symbol]
    @pretty_print_aborted_mi_attempts = self.class.pretty_print_mi_attempts_in_bulk_helper(:result => @result['aborted mi attempts'])[self.marker_symbol]
    @pretty_print_phenotype_attempts = self.class.pretty_print_phenotype_attempts_in_bulk_helper(:result => @result['phenotype attempts'])[self.marker_symbol]

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

  def set_cgi_and_gm_feature_types
    if marker_symbol =~ /CGI/
      self.feature_type = 'CpG Island'
      self.marker_type = 'DNA Segment'
    end
  end
  private :set_cgi_and_gm_feature_types

# CLASS METHODS
# mi_plan summarys for a list of genes
  def self.pretty_print_mi_attempts_in_progress_in_bulk(gene_ids = nil)
    return pretty_print_mi_attempts_in_bulk_helper({:active => true, :statuses => [MiAttempt::Status.micro_injection_in_progress, MiAttempt::Status.chimeras_obtained], :gene_ids => gene_ids})
  end

  def self.pretty_print_mi_attempts_genotype_confirmed_in_bulk(gene_ids = nil)
    return pretty_print_mi_attempts_in_bulk_helper({:active => true, :statuses => [MiAttempt::Status.genotype_confirmed], :gene_ids => gene_ids})
  end

  def self.pretty_print_aborted_mi_attempts_in_bulk(gene_ids = nil)
    return pretty_print_mi_attempts_in_bulk_helper({:active => false, :gene_ids => gene_ids})
  end

  def self.pretty_print_phenotype_attempts_in_bulk(gene_ids = nil)
    return pretty_print_phenotype_attempts_in_bulk_helper({:gene_ids => gene_ids})
  end

# mi_plan summary formatting
  def self.non_assigned_mi_plans_in_bulk(options = {})
    gene_ids = options[:gene_ids] || nil
    result = options[:result] || nil
    crispr = options[:crispr] || false
    show_eucommtoolscre_data = options.has_key?(:show_eucommtoolscre_data) ? options[:show_eucommtoolscre_data] : true

    gene_ids = [gene_ids] if (!gene_ids.kind_of?(Array)) and (!gene_ids.nil?)
    result = self.gene_production_summary({:gene_ids => gene_ids, :return_value => 'non assigned plans', :crispr => crispr, :show_eucommtoolscre_data => show_eucommtoolscre_data}) if result.nil?

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


  def self.assigned_mi_plans_in_bulk(options = {})
    gene_ids = options[:gene_ids] || nil
    result = options[:result] || nil
    crispr = options[:crispr] || false
    show_eucommtoolscre_data = options.has_key?(:show_eucommtoolscre_data) ? options[:show_eucommtoolscre_data] : true

    gene_ids = [gene_ids] if (!gene_ids.kind_of?(Array)) and (!gene_ids.nil?)
    result = self.gene_production_summary({:gene_ids => gene_ids, :return_value => 'assigned plans', :crispr => crispr, :show_eucommtoolscre_data => show_eucommtoolscre_data}) if result.nil?

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


  def self.pretty_print_non_assigned_mi_plans_in_bulk(options = {})
    gene_ids = options[:gene_ids] || nil
    result = options[:result] || nil
    crispr = options[:crispr] || false
    show_eucommtoolscre_data = options.has_key?(:show_eucommtoolscre_data) ? options[:show_eucommtoolscre_data] : true

    #puts "#### pretty_print_non_assigned_mi_plans_in_bulk: crispr: #{crispr}"
    data = Gene.non_assigned_mi_plans_in_bulk({ :gene_ids => gene_ids, :result => result, :crispr => crispr, :show_eucommtoolscre_data => show_eucommtoolscre_data})

    data.each do |marker_symbol,mi_plans|
      strings = mi_plans.map do |mip|
       # pp mip
      #  next if crispr && ! mip[:mutagenesis_via_crispr_cas9]
        string = "[#{mip[:consortium]}"
        string << ":#{mip[:production_centre]}" unless mip[:production_centre].nil?
        string << ":#{mip[:status_name]}"
        string << "]"
      end
      data[marker_symbol] = strings.join('<br/>').html_safe
    end

    return data
  end

  def self.pretty_print_assigned_mi_plans_in_bulk(options = {})
    gene_ids = options[:gene_ids] || nil
    result = options[:result] || nil
    crispr = options[:crispr] || false
    show_eucommtoolscre_data = options.has_key?(:show_eucommtoolscre_data) ? options[:show_eucommtoolscre_data] : true

    data = Gene.assigned_mi_plans_in_bulk({ :gene_ids => gene_ids, :result => result, :crispr => crispr, :show_eucommtoolscre_data => show_eucommtoolscre_data})

    data.each do |marker_symbol,mi_plans|
      strings = mi_plans.map do |mip|
      #  next if crispr && ! mip[:mutagenesis_via_crispr_cas9]
        string = "[#{mip[:consortium]}"
        string << ":#{mip[:production_centre]}" unless mip[:production_centre].nil?
        string << "]"
      end
      data[marker_symbol] = strings.join('<br/>').html_safe
    end

    return data
  end


  def self.pretty_print_mi_attempts_in_bulk_helper( options = {})
    active = options[:active] || nil
    statuses = options[:statuses] || []
    gene_ids = options[:gene_ids] || nil
    result = options[:result] || nil
    crispr = options[:crispr] || false
    show_eucommtoolscre_data = options.has_key?(:show_eucommtoolscre_data) ? options[:show_eucommtoolscre_data] : true

    gene_ids = [gene_ids] if (!gene_ids.kind_of?(Array)) and (!gene_ids.nil?)

    if result.nil?
      if active

        if statuses.count == 1

          if statuses.map{|status| status.name}.include?('Genotype confirmed')
            result = self.gene_production_summary({:gene_ids => gene_ids, :return_value => 'genotype confirmed mi attempts', :crispr =>  crispr, :show_eucommtoolscre_data => show_eucommtoolscre_data})
          else
           result = self.gene_production_summary({:gene_ids => gene_ids, :return_value => 'in progress mi attempts', :crispr => crispr, :show_eucommtoolscre_data => show_eucommtoolscre_data})
          end

        else
          result = self.gene_production_summary({:gene_ids => gene_ids, :return_value => 'full_data', :statuses => statuses, :crispr => crispr, :show_eucommtoolscre_data => show_eucommtoolscre_data})
        end

      else
        result = self.gene_production_summary({:gene_ids => gene_ids, :return_value => 'aborted mi attempts', :crispr => crispr, :show_eucommtoolscre_data => show_eucommtoolscre_data})
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


  def self.pretty_print_phenotype_attempts_in_bulk_helper(options = {})
    gene_ids = options[:gene_ids] || nil
    result = options[:result] || nil
    show_eucommtoolscre_data = options[:show_eucommtoolscre_data] || true

    gene_ids = [gene_ids] if (!gene_ids.kind_of?(Array)) and (!gene_ids.nil?)
    result = self.gene_production_summary({:gene_ids => gene_ids, :return_value => 'phenotype attempts', :crispr => crispr, :show_eucommtoolscre_data => show_eucommtoolscre_data}) if result.nil?

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
  def self.gene_production_summary(options = {})
    gene_ids = options[:gene_ids] || nil
    return_value = options[:return_value] || nil
    statuses = options[:statuses] || nil
    crispr = options.has_key?(:crispr) ? options[:crispr] : nil
    show_eucommtoolscre_data = options.has_key?(:show_eucommtoolscre_data) ? options[:show_eucommtoolscre_data] : true

    sql = <<-EOF

      WITH status_summary AS (

      SELECT production_summary.mi_plan_id, production_summary.gene_id, production_summary.consortium_id, production_summary.production_centre_id, production_summary.status_name, count(production_summary.mi_plan_id) AS status_count
      FROM
      (
        (SELECT mi_plans.id AS mi_plan_id, mi_plans.gene_id, mi_plans.consortium_id, mi_plans.production_centre_id, CASE WHEN mi_attempt_statuses.name IS NOT NULL THEN mi_attempt_statuses.name ELSE mi_plan_statuses.name END AS status_name
         FROM mi_plans
           JOIN mi_plan_statuses ON mi_plans.status_id = mi_plan_statuses.id #{[true, false].include?(crispr) ? "AND mi_plans.mutagenesis_via_crispr_cas9 = #{crispr}" : ''}
           LEFT JOIN (mi_attempts JOIN mi_attempt_statuses ON mi_attempts.status_id = mi_attempt_statuses.id) ON mi_plans.id = mi_attempts.mi_plan_id
           #{ if !gene_ids.nil? || show_eucommtoolscre_data == false
                query = []
                query << "mi_plans.gene_id IN (#{gene_ids.join(', ')})" if !gene_ids.nil?
                query << "mi_plans.consortium_id != 17" if show_eucommtoolscre_data == false
                "WHERE #{query.join(' AND ')}"
              end
           }
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
           LEFT JOIN (phenotyping_productions JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = phenotyping_productions.status_id JOIN colonies parent_colony ON parent_colony.id = phenotyping_productions.parent_colony_id) ON phenotyping_productions.mi_plan_id = mi_plans.id
           LEFT JOIN (mouse_allele_mods JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id) ON (mouse_allele_mods.id = parent_colony.mouse_allele_mod_id) OR (mouse_allele_mods.mi_plan_id = mi_plans.id)

           JOIN ( mi_attempts JOIN colonies mi_attempt_colony ON mi_attempt_colony.mi_attempt_id = mi_attempts.id ) ON mi_attempt_colony.id = mouse_allele_mods.parent_colony_id OR mi_attempt_colony.id = phenotyping_productions.parent_colony_id

         WHERE mi_attempts.is_active = true AND (mouse_allele_mods.id IS NOT NULL OR phenotyping_productions.id IS NOT NULL)
           #{gene_ids.nil? ? "" : "AND mi_plans.gene_id IN (#{gene_ids.join(', ')})"} #{[true, false].include?(crispr) ? "AND mi_plans.mutagenesis_via_crispr_cas9 = #{crispr}" : ''}
           #{show_eucommtoolscre_data == false ? " AND mi_plans.consortium_id != 17" : ''}
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

   # puts "#### gene_production_summary: sql: #{sql}"

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


      if ['Micro-injection in progress', 'Chimeras obtained', 'Founder obtained'].include?(production_record['status_name'])
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

  def self.update_gene_list
    require 'open-uri'
    headers = []
    genes_data = {}
    ccds_data = {}
    human_data = {}

    logger.info "Load gene info"
    logger.info "downloading MGI_MRK_Coord"
    url = 'http://www.informatics.jax.org/downloads/reports/MGI_MRK_Coord.rpt'
    open(url) do |file|
      headers = file.readline.strip.split("\t")
      mgi_accession_index = headers.index('1. MGI Marker Accession ID')
      marker_symbol_index = headers.index('4. Marker Symbol')
      marker_name_index = headers.index('5. Marker Name')
      chr_index = headers.index('6. Chromosome')
      start_index = headers.index('7. Start Coordinate')
      end_index = headers.index('8. End Coordinate')
      strand_index = headers.index('9. Strand')
      genome_build_index = headers.index('10. Genome Build')
      marker_type_index = headers.index('2. Marker Type')
      feature_type_index = headers.index('3. Feature Type')

      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t")
        genes_data[row[mgi_accession_index]] = {
          'mgi_accession_id' => row[mgi_accession_index],
          'marker_symbol' => row[marker_symbol_index],
          'marker_name'   => row[marker_name_index],
          'chr'           => row[chr_index],
          'start'         => row[start_index],
          'end'           => row[end_index],
          'cm_position'    => '',
          'strand'        => row[strand_index],
          'genome_build'  => row[genome_build_index],
          'vega_ids'      => [],
          'ens_ids'       => [],
          'ncbi_ids'      => [],
          'marker_type'  => row[marker_type_index],
          'feature_type'  => row[feature_type_index],
          'synonyms'    => ''
        }
      end
    end

    if genes_data.blank?
      logger.error "failed to download file"
      exit
    end

    logger.info "Downloading Vega report"
    url = "http://www.informatics.jax.org/downloads/reports/MRK_VEGA.rpt"
    open(url) do |file|
      headers = file.readline.strip.split("\t")
      mgi_accession_id_index = 0
      vega_ids_index = 5
      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t")
        genes_data[row[mgi_accession_id_index]]['vega_ids'] << row[vega_ids_index] if genes_data.has_key?(row[mgi_accession_id_index])
      end
    end

    logger.info "Downloading Ensemble report"
    url = "http://www.informatics.jax.org/downloads/reports/MRK_ENSEMBL.rpt"
    open(url) do |file|
      headers = file.readline.strip.split("\t")
      mgi_accession_id_index = 0
      ens_ids_index = 5
      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t")
        genes_data[row[mgi_accession_id_index]]['ens_ids'] << row[ens_ids_index] if genes_data.has_key?(row[mgi_accession_id_index])
      end
    end

    logger.info "Downloading ncbi report"
    url = "http://www.informatics.jax.org/downloads/reports/MGI_EntrezGene.rpt"
    open(url) do |file|
      headers = file.readline.strip.split("\t")
      mgi_accession_id_index = 0
      cm_position_index = 4
      ncbi_ids_index = 8
      synonym_index = 9
      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t")
        if genes_data.has_key?(row[mgi_accession_id_index]) and !row[ncbi_ids_index].blank?
          genes_data[row[mgi_accession_id_index]]['ncbi_ids'] << row[ncbi_ids_index]
        end

        if genes_data.has_key?(row[mgi_accession_id_index]) and !row[synonym_index].blank?
          genes_data[row[mgi_accession_id_index]]['synonyms'] << row[synonym_index]
        end

        if genes_data.has_key?(row[mgi_accession_id_index]) and !row[cm_position_index].blank?
          genes_data[row[mgi_accession_id_index]]['cm_position'] = row[cm_position_index]
        end

      end
    end

    logger.info "Downloading human ortholog report"
    url = "http://www.informatics.jax.org/downloads/reports/HMD_HumanPhenotype.rpt"
    open(url) do |file|
      human_symbol_index = 0
      human_entrez_gene_id_index = 1
      human_homolo_gene_id_index = 2
      mouse_mgi_id_index = 5
      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t").map{|a| a.strip}
        if !human_data.has_key?(row[mouse_mgi_id_index])
          human_data[row[mouse_mgi_id_index]] = {
            'human_gene_symbol' => [], 'human_entrez_gene_id' => [], 'human_homolo_gene_id' => []
          }
        end
        human_data[row[mouse_mgi_id_index]]['human_gene_symbol'] << row[human_symbol_index]
        human_data[row[mouse_mgi_id_index]]['human_entrez_gene_id'] << row[human_entrez_gene_id_index]
        human_data[row[mouse_mgi_id_index]]['human_homolo_gene_id'] << row[human_homolo_gene_id_index]
      end
    end
    logger.error "failed to download file" if human_data.blank?


    logger.info "Downloading ccds report"
    url = "ftp://ftp.ncbi.nlm.nih.gov/pub/CCDS/current_mouse/CCDS.current.txt"
    open(url) do |file|
      headers = file.readline.strip.split("\t")
      ncbi_id_index = headers.index('gene_id')
      ccds_ids_index = headers.index('ccds_id')
      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t")
        if !ccds_data.has_key?(row[ncbi_id_index])
          ccds_data[row[ncbi_id_index]] = {
            'ccds_ids' => []
          }
        end
        ccds_data[row[ncbi_id_index]]['ccds_ids'] << row[ccds_ids_index]
      end
    end
    logger.error "failed to download file" if ccds_data.blank?


    logger.info "Update Gene List"

    Gene.all.each do |gene|
      gene_data = nil
      gene_data = genes_data.delete(gene.mgi_accession_id)
      if gene_data.blank?
        logger.info "MGI accession does not exist: #{gene.mgi_accession_id}"
        if gene.allele.count == 0 and gene.mi_plans.count == 0 and ! gene.mgi_accession_id =~ /CGI/
          gene.delete
          logger.info "Deleted MGI accession: #{gene.mgi_accession_id}"
        else
          logger.error "Cannot delete MGI accession: #{gene.mgi_accession_id}"
        end
        next
      end

      if gene_data['marker_name'] == 'withdrawn'
        logger.error "MGI Accession has been withdrawn: #{gene.mgi_accession_id}"
        next
      end
      if gene_data['genome_build'] != 'GRCm38'
        logger.error "genome build is not equal to GRCm38: #{gene.mgi_accession_id}"
        next
      end
      gene.marker_symbol = gene_data['marker_symbol']
      gene.chr = gene_data['chr']
      gene.marker_type = gene_data['marker_type']
      gene.marker_name = gene_data['marker_name']
      gene.feature_type = gene_data['feature_type']
      gene.synonyms = gene_data['synonyms']
      gene.start_coordinates = gene_data['start']
      gene.end_coordinates = gene_data['end']
      gene.cm_position = gene_data['cm_position']
      gene.strand_name = gene_data['strand']
      gene.vega_ids = gene_data['vega_ids'].join(',')
      gene.ensembl_ids = gene_data['ens_ids'].join(',')
      gene.ncbi_ids = gene_data['ncbi_ids'].join(',')
      gene.ccds_ids = gene_data['ncbi_ids'].map{|ncbi_id| ccds_data[ncbi_id]['ccds_ids'] if ccds_data.has_key?(ncbi_id)}.flatten.join(',')

      if human_data.has_key?(gene.mgi_accession_id)
        human_row = human_data[gene.mgi_accession_id]
        gene.human_marker_symbol = human_row['human_gene_symbol'].flatten.join('|')
        gene.human_entrez_gene_id = human_row['human_entrez_gene_id'].flatten.join('|')
        gene.human_homolo_gene_id = human_row['human_homolo_gene_id'].flatten.join('|')
      end

      if gene.changed?
        logger.info "update gene references for #{gene.mgi_accession_id}"
        if gene.valid?
          gene.save
          logger.info "Update Successful"
        else
          logger.error "Update FAILED"
        end
      end
    end

    puts "COUNT: #{genes_data.count}"
    genes_data.each do |key, new_gene|
      logger.info "Creating new gene: #{new_gene['mgi_accession_id']}"
      ng = Gene.new
      ng.mgi_accession_id = new_gene['mgi_accession_id']
      ng.marker_symbol = new_gene['marker_symbol']
      ng.chr = new_gene['chr']
      ng.marker_type = new_gene['marker_type']
      ng.feature_type = new_gene['feature_type']
      ng.synonyms = new_gene['synonyms']
      ng.start_coordinates = new_gene['start']
      ng.end_coordinates = new_gene['end']
      ng.strand_name = new_gene['strand']
      ng.vega_ids = new_gene['vega_ids'].join('')
      ng.ncbi_ids = new_gene['ens_ids'].join('')
      ng.ensembl_ids = new_gene['ncbi_ids'].join('')

      ng.ccds_ids = new_gene['ncbi_ids'].map{|ncbi_id| ccds_data[ncbi_id]['ccds_ids'] if ccds_data.has_key?(ncbi_id)}.flatten.join(',')

      if human_data.has_key?(new_gene['mgi_accession_id'])
        human_row = human_data[new_gene['mgi_accession_id']]
        ng.human_marker_symbol = human_row['human_gene_symbol'].flatten.join('|')
        ng.human_entrez_gene_id = human_row['human_entrez_gene_id'].flatten.join('|')
        ng.human_homolo_gene_id = human_row['human_homolo_gene_id'].flatten.join('|')
      end

      if ng.valid?
        logger.info "Successfuly Created new gene: #{new_gene['mgi_accession_id']}"
        ng.save
      else
        logger.error "Failed to create new gene: #{new_gene['mgi_accession_id']}"
      end
    end

    nil
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
#  id                                 :integer          not null, primary key
#  marker_symbol                      :string(75)       not null
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
#  chr                                :string(2)
#  start_coordinates                  :integer
#  end_coordinates                    :integer
#  strand_name                        :string(255)
#  vega_ids                           :string(255)
#  ncbi_ids                           :string(255)
#  ensembl_ids                        :string(255)
#  ccds_ids                           :string(255)
#  marker_type                        :string(255)
#  feature_type                       :string(255)
#  synonyms                           :string(255)
#  komp_repo_geneid                   :integer
#  marker_name                        :string(255)
#  cm_position                        :string(255)
#  human_marker_symbol                :string(255)
#  human_entrez_gene_id               :string(255)
#  human_homolo_gene_id               :string(255)
#
# Indexes
#
#  index_genes_on_marker_symbol     (marker_symbol) UNIQUE
#  index_genes_on_mgi_accession_id  (mgi_accession_id) UNIQUE
#
