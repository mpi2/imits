class TargRep::Allele < ActiveRecord::Base

  acts_as_audited

  extend AccessAssociationByAttribute
  ##
  ## Associations
  ##
  belongs_to :mutation_method, :class_name => 'TargRep::MutationMethod'
  belongs_to :mutation_type, :class_name => 'TargRep::MutationType'
  belongs_to :mutation_subtype, :class_name => 'TargRep::MutationSubtype'
  belongs_to :gene

  access_association_by_attribute :gene, :mgi_accession_id
  access_association_by_attribute :mutation_method,  :name
  access_association_by_attribute :mutation_type,    :name
  access_association_by_attribute :mutation_subtype, :name

  has_one    :genbank_file,      :dependent => :destroy, :foreign_key => 'allele_id'
  has_many   :targeting_vectors, :dependent => :destroy, :foreign_key => 'allele_id'
  has_many   :es_cells,          :dependent => :destroy, :foreign_key => 'allele_id' do
    def unique_public_info
      info_map = ActiveSupport::OrderedHash.new

      self.order('id ASC').each do |es_cell|
        next if !es_cell.pipeline.report_to_public || !es_cell.report_to_public

        key = {
          :strain => es_cell.strain,
          :mgi_allele_symbol_superscript => es_cell.mgi_allele_symbol_superscript,
          :ikmc_project_id => es_cell.ikmc_project_id.to_s,
          :ikmc_project_status_name => '',
          :ikmc_project_name => '',
          :ikmc_project_pipeline => ''
        }

        if es_cell.ikmc_project && es_cell.ikmc_project.status && es_cell.ikmc_project.status.name
          key[:ikmc_project_name] = es_cell.ikmc_project.name
          key[:ikmc_project_status_name] = es_cell.ikmc_project.status.name
          key[:ikmc_project_pipeline] = es_cell.ikmc_project.pipeline.name
        end

        info_map[key] ||= {:pipelines => []}
        info_map[key][:pipelines].push(es_cell.pipeline.name)
      end

      info = info_map.map do |key, value|
        key.merge(:pipeline => value[:pipelines].first)
      end
      return info
    end
  end

  accepts_nested_attributes_for :genbank_file,      :allow_destroy  => true
  accepts_nested_attributes_for :targeting_vectors, :allow_destroy  => true
  accepts_nested_attributes_for :es_cells,          :allow_destroy  => true

  delegate :mgi_accession_id, :to => :gene
  delegate :marker_symbol, :to => :gene

  ALLELE_JSON = {
    :include => {
        :es_cells => { :except => [
            :allele_id,
            :created_at, :updated_at,
            :creator, :updater
        ],
        :include => {
            :distribution_qcs => { :except => [:created_at, :updated_at] , :methods => [:es_cell_distribution_centre_name]}
            },
        :methods => [:allele_symbol_superscript, :pipeline_name, :user_qc_mouse_clinic_name]},
        :targeting_vectors => { :except => [
            :allele_id,
            :created_at, :updated_at,
            :creator, :updater
        ]},
        :genbank_file => { :except => [
            :allele_id,
            :created_at, :updated_at,
            :creator, :updater
        ]},
    },
    :methods => [
        :mutation_method_name,
        :mutation_type_name,
        :mutation_subtype_name,
        :marker_symbol
    ]}

  ##
  ## Validations
  ##

  validates :assembly,           :presence => true
  validates :chromosome,         :presence => true
  validates :strand,             :presence => true
  validates :mutation_method,    :presence => true
  validates :mutation_type,      :presence => true

  validates_inclusion_of :strand,
    :in         => ["+", "-"],
    :message    => "should be '+' or '-'."

  validates_inclusion_of :chromosome,
    :in         => ('1'..'19').to_a + ['X', 'Y', 'MT'],
    :message    => "is not a valid mouse chromosome"

  validates_associated :mutation_method,
    :message    => "should be a valid mutation method"

  validates_associated :mutation_type,
    :message    => "should be a valid mutation type"

  validates_associated :mutation_subtype,
    :message    => "should be a valid mutation subtype"

  validates :gene, :presence => true

  def missing_fields?
    assembly.blank? ||
    chromosome.blank? ||
    strand.blank? ||
    mutation_type.blank?
  end

  def self.targeted_allele?; false; end
  def self.gene_trap?; false; end
  def self.hdr_allele?; false; end
  def self.nhej_allele?; false; end
  def self.crispr_targeted_allele?; false; end
  ##
  ## Methods
  ##

  public
    def to_json( options = {} )
      TargRep::Allele.include_root_in_json = false
      super( ALLELE_JSON )
    end

    def to_xml( options = {} )
      options.update(
        :skip_types => true,
        :include => {
          :es_cells => { :except => [
              :allele_id,
              :created_at, :updated_at,
              :creator, :updater
          ]},
          :targeting_vectors => { :except => [
              :allele_id,
              :created_at, :updated_at,
              :creator, :updater
          ]}
        },
        :methods => [
            :mutation_method_name,
            :mutation_type_name,
            :mutation_subtype_name,
            :marker_symbol
                    ]
      )
      super( options )
    end

    def targeted_trap?
      if self.mutation_type.targeted_non_conditional?
        return 'Yes'
      else
        return 'No'
      end
    end

    def pipeline_names
      pipelines = {}
      self.targeting_vectors.each { |tv| pipelines[tv.pipeline.name] = true } if self.targeting_vectors
      self.es_cells.each { |esc| pipelines[esc.pipeline.name] = true } if self.es_cells
      pipelines.keys.sort.join(', ')
    end

end



# == Schema Information
#
# Table name: targ_rep_alleles
#
#  id                  :integer         not null, primary key
#  gene_id             :integer
#  assembly            :string(255)     default("GRCm38"), not null
#  chromosome          :string(2)       not null
#  strand              :string(1)       not null
#  homology_arm_start  :integer
#  homology_arm_end    :integer
#  loxp_start          :integer
#  loxp_end            :integer
#  cassette_start      :integer
#  cassette_end        :integer
#  cassette            :string(100)
#  backbone            :string(100)
#  subtype_description :string(255)
#  floxed_start_exon   :string(255)
#  floxed_end_exon     :string(255)
#  project_design_id   :integer
#  reporter            :string(255)
#  mutation_method_id  :integer
#  mutation_type_id    :integer
#  mutation_subtype_id :integer
#  cassette_type       :string(50)
#  created_at          :datetime        not null
#  updated_at          :datetime        not null
#  intron              :integer
#  type                :string(255)     default("TargRep::TargetedAllele")
#  sequence            :text
#

