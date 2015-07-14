class TargRep::Allele < ActiveRecord::Base

  acts_as_audited

  extend AccessAssociationByAttribute
  TEMPLATE_CHARACTER = '@'

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
  has_many   :allele_sequence_annotations, :dependent => :destroy, :foreign_key => 'allele_id'
  has_many   :es_cells,          :dependent => :destroy, :foreign_key => 'allele_id' do
    def unique_public_info
      info_map = ActiveSupport::OrderedHash.new

      self.order('id ASC').each do |es_cell|
        next if !es_cell.pipeline.blank? && es_cell.pipeline.name == 'EUCOMMToolsCre'
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
  accepts_nested_attributes_for :allele_sequence_annotations, :allow_destroy => true

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
        :allele_sequence_annotations => { :except => [
            :allele_id
        ]},
    },
    :methods => [
        :mutation_method_name,
        :mutation_type_name,
        :mutation_subtype_name,
        :marker_symbol
    ]}

  before_validation :set_chr_and_strand
  before_validation :set_empty_fields_to_nil
  before_validation :upper_case_sequence

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

  validates_inclusion_of :has_issue,
    :in         => [ nil, true, false ],
    :message    => "should be either nil, true or false",
    :allow_nil  => true

  validates_associated :mutation_method,
    :message    => "should be a valid mutation method"

  validates_associated :mutation_type,
    :message    => "should be a valid mutation type"

  validates_associated :mutation_subtype,
    :message    => "should be a valid mutation subtype"

  validates :gene, :presence => true

  validates_format_of :sequence,
      :with        => /^[ACGT]+$/i,
      :message     => "must consist of a sequence of 'A', 'C', 'G' or 'T'",
      :allow_blank => true

  validates_format_of :wildtype_oligos_sequence,
      :with        => /^[ACGT]+$/i,
      :message     => "must consist of a sequence of 'A', 'C', 'G' or 'T'",
      :allow_blank => true


  # fix for error where form tries to insert empty strings when there are no floxed exons
  def set_empty_fields_to_nil
    self.floxed_start_exon = nil if self.floxed_start_exon.to_s.empty?
    self.floxed_end_exon   = nil if self.floxed_end_exon.to_s.empty?
  end

  def set_chr_and_strand
    return if gene.blank?

    self.chromosome = gene.chr if !gene.chr.blank?
    self.strand = gene.strand_name if !gene.strand_name.blank?
  end

  def upper_case_sequence
    self.sequence = self.sequence.upcase if !self.sequence.blank?
    self.wildtype_oligos_sequence = self.wildtype_oligos_sequence.upcase if !self.wildtype_oligos_sequence.blank?
  end
  protected :upper_case_sequence
  ##
  ## Methods
  ##

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

  def self.extract_symbol_superscript_template(mgi_allele_symbol_superscript)
    symbol_superscript_template = nil
    type = nil
    errors = []

    md = /\A(tm\d+)([a-e]|.\d+|e.\d+)?(\(\w+\)\w+)\Z/.match(mgi_allele_symbol_superscript)

    if md
      symbol_superscript_template = md[1] + TEMPLATE_CHARACTER + md[3]
      type = md[2]
    else
      md = /\AGt\(\w+\)\w+\Z/.match(mgi_allele_symbol_superscript)
      if md
        symbol_superscript_template = mgi_allele_symbol_superscript
        type = nil
      else
        errors << [:allele_symbol_superscript, "Bad allele symbol superscript '#{mgi_allele_symbol_superscript}'"]
      end
    end

    return [symbol_superscript_template, type, errors]
  end
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

    def self.allele_description (options)
      marker_symbol = options.has_key?('marker_symbol') ? options['marker_symbol'] : nil
      cassette       = options.has_key?('cassette') ? options['cassette'] : nil
      allele_type   = options.has_key?('allele_type') ? options['allele_type'] : nil
      colony_name   = options.has_key?('colony_name') ? options['colony_name'] : nil
      crispr_mutation_description = options.has_key?('crispr_mutation_description') ? options['crispr_mutation_description'] : nil
      exon_id = options.has_key?('exon_id') ? options['exon_id'] : nil

      return '' if allele_type.nil?

      allele_descriptions = { 'tma'     => "KO first allele (reporter-tagged insertion with conditional potential)",
                              'tme'     => "Targeted, non-conditional allele",
                              'tme.1'   => "Targeted, non-conditional allele (post-Cre)",
                              'tm'      => "Reporter-tagged deletion allele (with selection cassette)",
                              'tmb'     => "Reporter-tagged deletion allele (post-Cre)",
                              'tm.1'    => "Reporter-tagged deletion allele (post Cre, with no selection cassette)",
                              'tmc'     => "Wild type floxed exon (post-Flp)",
                              'tm.2'    => "Reporter-tagged deletion allele (post Flp, with no reporter and selection cassette)",
                              'tmd'     => "Deletion allele (post-Flp and Cre with no reporter)",
                              'tmCreSC' => "Cre driver allele (with selection cassette)",
                              'tmCre'   => "Cre driver allele",
                              'tmCGI'   => "Truncation cassette with conditional potential",
                              'gt'      => "Gene Trap",
                              'Gene Trap' => "Gene Trap",
                              'em'      => "#{if !exon_id.blank? && !crispr_mutation_description.blank?;"Frameshift mutation caused by a #{crispr_mutation_description}  in #{exon_id}" ; else; "Frameshift mutation"; end}"
                            }

      return allele_descriptions['tmCGI'] if !marker_symbol.blank? && marker_symbol =~ /CGI/

      return allele_descriptions['tma'] if allele_type == 'a'
      return allele_descriptions['tmb'] if allele_type == 'b'
      return allele_descriptions['tmc'] if allele_type == 'c'
      return allele_descriptions['tmd'] if allele_type == 'd'
      return allele_descriptions['tme'] if allele_type == 'e'
      return allele_descriptions['gt'] if allele_type == 'gt'
      return allele_descriptions['em'] if allele_type == 'em'

      if !cassette.blank? && cassette =~ /Cre/
        return allele_descriptions['tmCreSC'] if allele_type == ''
        return allele_descriptions['tmCre'] if allele_type == '.1'
      end

      return allele_descriptions['tm'] if allele_type == ''
      return allele_descriptions['tm.1'] if allele_type == '.1'
      return allele_descriptions['tm.2'] if allele_type == '.2'

    end
end

# == Schema Information
#
# Table name: targ_rep_alleles
#
#  id                             :integer          not null, primary key
#  gene_id                        :integer
#  assembly                       :string(255)      default("GRCm38"), not null
#  chromosome                     :string(2)        not null
#  strand                         :string(1)        not null
#  homology_arm_start             :integer
#  homology_arm_end               :integer
#  loxp_start                     :integer
#  loxp_end                       :integer
#  cassette_start                 :integer
#  cassette_end                   :integer
#  cassette                       :string(100)
#  backbone                       :string(100)
#  subtype_description            :string(255)
#  floxed_start_exon              :string(255)
#  floxed_end_exon                :string(255)
#  project_design_id              :integer
#  reporter                       :string(255)
#  mutation_method_id             :integer
#  mutation_type_id               :integer
#  mutation_subtype_id            :integer
#  cassette_type                  :string(50)
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  intron                         :integer
#  type                           :string(255)      default("TargRep::TargetedAllele")
#  has_issue                      :boolean          default(FALSE), not null
#  issue_description              :text
#  sequence                       :text
#  taqman_critical_del_assay_id   :string(255)
#  taqman_upstream_del_assay_id   :string(255)
#  taqman_downstream_del_assay_id :string(255)
#  wildtype_oligos_sequence       :string(255)
#
