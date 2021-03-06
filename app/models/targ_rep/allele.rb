class TargRep::Allele < ActiveRecord::Base

  acts_as_audited

  extend AccessAssociationByAttribute
  TEMPLATE_CHARACTER = '@'

  GENBANK_FILE_TRANSFORMATIONS = {'a'   => '',
                                  'e'   => '',
                                  ''    => '',
                                  'b'   => 'cre',
                                  'e.1' => 'cre',
                                  '.1'  => 'cre',
                                  'c'   => 'flp',
                                  'd'   => 'flp-cre'
                                 }

  ##
  ## Associations
  ##
  belongs_to :mutation_method, :class_name => 'TargRep::MutationMethod'
  belongs_to :mutation_type, :class_name => 'TargRep::MutationType'
  belongs_to :mutation_subtype, :class_name => 'TargRep::MutationSubtype'
  belongs_to :gene, :class_name => 'Gene'
  belongs_to :colony, :class_name => 'Colony'
  belongs_to :allele_genbank_file, :class_name => 'TargRep::GenbankFile', :dependent => :destroy, :foreign_key => 'allele_genbank_file_id'
  belongs_to :vector_genbank_file, :class_name => 'TargRep::GenbankFile', :dependent => :destroy, :foreign_key => 'vector_genbank_file_id'

  access_association_by_attribute :gene, :mgi_accession_id
  access_association_by_attribute :mutation_method,  :name
  access_association_by_attribute :mutation_type,    :name
  access_association_by_attribute :mutation_subtype, :name

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

  accepts_nested_attributes_for :allele_genbank_file, :update_only => true
  accepts_nested_attributes_for :vector_genbank_file, :update_only => true
  accepts_nested_attributes_for :targeting_vectors, :allow_destroy  => true
  accepts_nested_attributes_for :es_cells,          :allow_destroy  => true
  accepts_nested_attributes_for :allele_sequence_annotations, :allow_destroy => true

  delegate :mgi_accession_id, :to => :gene
  delegate :marker_symbol, :to => :gene

  ALLELE_JSON = {
    :include => {
        :es_cells => { 
            :except => [
                :allele_id, :ikmc_project_foreign_id,
                :legacy_id, :pipeline_id, :targeting_vector_id,
                :created_at, :updated_at
            ],
            :include => {
              :distribution_qcs => { :except => [:created_at, :updated_at] , :methods => [:es_cell_distribution_centre_name]}
            },
            :methods => [:allele_symbol_superscript, :pipeline_name, :user_qc_mouse_clinic_name, :targeting_vector_name, :alleles_attributes],
        },
        :targeting_vectors => { 
            :except => [
                :allele_id, :ikmc_project_foreign_id,
                :pipeline_id,
                :created_at, :updated_at
            ],
            :methods => [:pipeline_name]
        }
    },
    :methods => [
        :mutation_method_name,
        :mutation_type_name,
        :mutation_subtype_name,
        :marker_symbol,
        :allele_genbank_file_text,
        :vector_genbank_file_text
    ]}

  before_validation :set_chr_and_strand
  before_validation :set_empty_fields_to_nil
  before_validation :upper_case_sequence
  before_validation :manage_genbank_files

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


  after_save :sync_es_cell_genbank_files_with_design_allele

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

  def manage_genbank_files
    allele = self

    allele.vector_genbank_file_attributes = {:file_gb => allele.vector_genbank_file_text}
    allele.allele_genbank_file_attributes = {:file_gb => allele.allele_genbank_file_text}

    return true
  end
  protected :manage_genbank_files

  def sync_es_cell_genbank_files_with_design_allele
    allele = self

    allele.es_cells.each do |es_cell|
      es_allele = Allele.find(es_cell.alleles[0].id)
      if es_allele.genbank_file_id != allele.allele_genbank_file_id
        es_allele.genbank_file_id = allele.allele_genbank_file_id
        if es_allele.changed?
          es_allele.save
        end
      end
    end
    allele.reload
  end
  protected :sync_es_cell_genbank_files_with_design_allele
  ##
  ## Methods
  ##

  def allele_genbank_file_text
    return @allele_genbank_file unless @allele_genbank_file.nil?
    return allele_genbank_file.file_gb unless allele_genbank_file.nil?
    return nil
  end

  def allele_genbank_file_text=(arg)
    @allele_genbank_file = arg
  end

  def vector_genbank_file_text
    return @vector_genbank_file unless @vector_genbank_file.nil?
    return vector_genbank_file.file_gb unless vector_genbank_file.nil?
    return nil
  end

  def vector_genbank_file_text=(arg)
    @vector_genbank_file = arg
  end

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

    md = /\A(tm\d+|em\d+)([a-e]|.\d+|e.\d+)?(\([\w\/]+\)\w+)\Z/.match(mgi_allele_symbol_superscript)

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

    def self.genbank_file_url(allele_id, modified_allele_type = nil)

      return "" if allele_id.blank?

      transformation = GENBANK_FILE_TRANSFORMATIONS[modified_allele_type]
      return "https://www.i-dcc.org/imits/targ_rep/alleles/#{allele_id}/escell-clone-#{!transformation.blank? ? transformation + '-' : ''}genbank-file"
    end

    def self.allele_image_url(marker_symbol, allele_id, modified_allele_type = nil, modified_allele_subtype = nil)
      return "" if modified_allele_type.nil? || marker_symbol.blank?

      if marker_symbol =~ /Cpgi/
        if modified_allele_type == ''
          return "https://www.i-dcc.org/imits/images/targ_rep/nc_rna_tm1.jpg"
        elsif modified_allele_type == '.1'
          return "https://www.i-dcc.org/imits/images/targ_rep/nrna_tm1_1.jpg"
        elsif modified_allele_type == '.2'
          return "https://www.i-dcc.org/imits/images/targ_rep/nrna_tm1_2.jpg"
        elsif modified_allele_type == '.3'
          return "https://www.i-dcc.org/imits/images/targ_rep/nrna_tm1_3.jpg"
        else
          ""
        end
      end

      if ["NHEJ", "Deletion", "HR", "HDR"].include?(modified_allele_type)
        return "https://www.i-dcc.org/imits/images/targ_rep/cripsr_map.jpg" if ["Indel", "Intra-exdel deletion"].include?(modified_allele_subtype)
        return "https://www.i-dcc.org/imits/images/targ_rep/crispr_exon_deletion_map.jpg" if ['Exon Deletion', 'Inter-exdel deletion', 'Whole-gene deletion'].include?(modified_allele_subtype)
        return "https://www.i-dcc.org/imits/images/targ_rep/cripsr_hdr_map.jpg" if ['Null reporter', 'Point Mutation'].include?(modified_allele_subtype)
        return "https://www.i-dcc.org/imits/images/targ_rep/crispr_conditional_map.jpg" if modified_allele_subtype == "Conditional Ready"
      end

      return "" if allele_id.blank?

      transformation = GENBANK_FILE_TRANSFORMATIONS[modified_allele_type]
      return "https://www.i-dcc.org/imits/targ_rep/alleles/#{allele_id}/allele-image#{!transformation.blank? ? '-' + transformation : ''}"
    end

    def self.simple_allele_image_url(marker_symbol, allele_id, modified_allele_type = nil, modified_allele_subtype = nil)
      return "" if modified_allele_type.nil? || marker_symbol.blank?

      if marker_symbol =~ /Cpgi/
        if modified_allele_type == ''
          return "https://www.i-dcc.org/imits/images/targ_rep/nc_rna_tm1.jpg"
        elsif modified_allele_type == '.1'
          return "https://www.i-dcc.org/imits/images/targ_rep/nrna_tm1_1_cre.jpg"
        elsif modified_allele_type == '.2'
          return "https://www.i-dcc.org/imits/images/targ_rep/nrna_tm1_2_flp.jpg"
        elsif modified_allele_type == '.3'
          return "https://www.i-dcc.org/imits/images/targ_rep/nrna_tm1_3_dre.jpg"
        else
          ""
        end
      end

      if ["NHEJ", "Deletion", "HR", "HDR"].include?(modified_allele_type)
        return "https://www.i-dcc.org/imits/images/targ_rep/cripsr_map.jpg" if ["Indel", "Intra-exdel deletion"].include?(modified_allele_subtype)
        return "https://www.i-dcc.org/imits/images/targ_rep/crispr_exon_deletion_map.jpg" if ['Exon Deletion', 'Inter-exdel deletion', 'Whole-gene deletion'].include?(modified_allele_subtype)
        return "https://www.i-dcc.org/imits/images/targ_rep/cripsr_hdr_map.jpg" if ['Null reporter', 'Point Mutation'].include?(modified_allele_subtype)
        return "https://www.i-dcc.org/imits/images/targ_rep/crispr_conditional_map.jpg" if modified_allele_subtype == "Conditional Ready"
      end

      return "" if allele_id.blank?

      transformation = GENBANK_FILE_TRANSFORMATIONS[modified_allele_type]
      return "https://www.i-dcc.org/imits/targ_rep/alleles/#{allele_id}/allele-image#{!transformation.blank? ? '-' + transformation : ''}?simple=true.jpg"
    end

    def self.targeting_vector_genbank_file_url(allele_id)
      return "" if allele_id.blank?
      return "https://www.i-dcc.org/imits/targ_rep/alleles/#{allele_id}/targeting-vector-genbank-file"
    end

    def self.vector_image_url(allele_id)
      return "" if allele_id.blank?
      return "https://www.i-dcc.org/imits/targ_rep/alleles/#{allele_id}/vector-image"
    end

    def self.design_url(design_id)
      return "" if design_id.blank?
      return "http://www.sanger.ac.uk/htgt/htgt2/design/designedit/refresh_design?design_id=#{design_id}"
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
#  allele_genbank_file_id         :integer
#  vector_genbank_file_id         :integer
#
