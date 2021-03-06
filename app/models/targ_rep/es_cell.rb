# encoding: utf-8

class TargRep::EsCell < ActiveRecord::Base

  acts_as_audited
  acts_as_reportable
  extend AccessAssociationByAttribute
  attr_accessor :nested, :bulk

  class Error < RuntimeError; end
  class SyncError < Error; end

  JSON_OPTIONS = {
      :include => {
        :allele => { :except => [:created_at, :updated_at, :gene_id, :id, :mutation_method_id, :mutation_type_id, :mutation_subtype_id],
                     :methods => [:mutation_method_name, :mutation_type_name, :mutation_subtype_name, :marker_symbol, :mgi_accession_id]},
        :distribution_qcs => { :except => [:created_at, :updated_at] , :methods => [:es_cell_distribution_centre_name]}
      },
      :methods => [:allele_symbol, :allele_symbol_superscript, :pipeline_name, :user_qc_mouse_clinic_name, :alleles_attributes]
  }

  ##
  ## Relationships
  ##
  belongs_to :pipeline
  belongs_to :allele, :class_name => "TargRep::Allele"
  belongs_to :ikmc_project, :class_name => "TargRep::IkmcProject", :foreign_key => :ikmc_project_foreign_id
  belongs_to :targeting_vector
  belongs_to :user_qc_mouse_clinic, :class_name => 'Centre'

  has_many :distribution_qcs, :dependent => :destroy
  has_many :mi_attempts
  has_many :alleles, :class_name => "::Allele", :inverse_of => :es_cell

  scope :has_targeting_vector, where('targeting_vector_id is not NULL')
  scope :no_targeting_vector, where(:targeting_vector_id => nil)

  access_association_by_attribute :user_qc_mouse_clinic, :name

  accepts_nested_attributes_for :distribution_qcs, :allow_destroy => true
  accepts_nested_attributes_for :alleles, :allow_destroy => true

  ##
  ## Filters
  ##

  before_validation :convert_blanks_to_nil
  before_validation :stamp_tv_project_id_on_cell,       :if     => Proc.new { |a| a.ikmc_project_id.nil? }
  before_validation :convert_ikmc_project_id_to_string, :unless => Proc.new { |a| a.ikmc_project_id.is_a?(String) }
  before_validation :remove_empty_distribution_qcs

  before_save :set_mirko_ikmc_project_id

  ##
  ## Validations
  ##

  validates :name,
    :uniqueness => {:message => 'has already been taken'},
    :presence => true

  validates :pipeline_id, :presence => true
  validates :allele_id, :presence => {:unless => :nested}
  validates :parental_cell_line, :presence => true
  validates :targeting_vector, :consistent_allele => {:if => :has_allele_and_targeting_vector?}

  validate :set_and_check_strain

  ##
  ## QC validations
  ##

  def self.qc_options
    hash = {
      "user_qc_karyotype"                     => { :name => "Karyotype",     :values => ["pass","fail","limit"] },
      "user_qc_southern_blot"                 => { :name => "Southern Blot", :values => ["pass","fail 5' end","fail 3' end","fail both ends","double integration"] },
      "user_qc_five_prime_lr_pcr"             => { :name => "5' LR-PCR" },
      "user_qc_three_prime_lr_pcr"            => { :name => "3' LR-PCR" },
      "user_qc_map_test"                      => { :name => "Map Test" },
      "user_qc_tv_backbone_assay"             => { :name => "TV Backbone Assay" },
      "user_qc_loxp_confirmation"             => { :name => "LoxP Confirmation" },
      "user_qc_loss_of_wt_allele"             => { :name => "Loss of WT Allele (LOA)" },
      "user_qc_neo_count_qpcr"                => { :name => "Neo Count (qPCR)" },
      "user_qc_lacz_sr_pcr"                   => { :name => "LacZ SR-PCR" },
      "user_qc_mutant_specific_sr_pcr"        => { :name => "Mutant Specific SR-PCR" },
      "user_qc_five_prime_cassette_integrity" => { :name => "5' Cassette Integrity" },
      "user_qc_neo_sr_pcr"                    => { :name => "Neo SR-PCR" },

      "user_qc_karyotype_spread"              => { :name => "Karyotype Spread" },
      "user_qc_karyotype_pcr"                 => { :name => "Karyotype PCR" },
      "user_qc_loxp_srpcr_and_sequencing"     => { :name => "Loxp SRPCR and Sequencing" },

      "user_qc_chr1"                          => { :name => "Chr1"},
      "user_qc_chr11"                         => { :name => "Chr11"},
      "user_qc_chr8"                          => { :name => "Chr8"},
      "user_qc_chry"                          => { :name => "Chry"},
      "user_qc_lacz_qpcr"                     => { :name => "LacZ qPCR"}
    }

    hash.each do |field,data|
      if data[:values].nil?
        hash[field][:values] = ['pass', 'passb','fail']
      end
    end

    hash
  end

  TargRep::EsCell.qc_options.each_key do |qc_field|
    validates_inclusion_of qc_field,
      :in        => TargRep::EsCell.qc_options[qc_field.to_s][:values],
      :message   => "This QC metric can only be set as: #{TargRep::EsCell.qc_options[qc_field.to_s][:values].join(', ')}",
      :allow_nil => true
  end

  validate do |plan|
    return true if user_qc_mouse_clinic_name.blank?
    centre_names = Centre.pluck(:name)
    unless centre_names.include?(self.user_qc_mouse_clinic_name)
      self.errors.add(:user_qc_mouse_clinic_name, "This QC metric can only be set as: #{centre_names.join(', ')}.")
    end
  end

  ##
  ## Methods
  ##

  public
    delegate :gene, :to => :allele
    delegate :marker_symbol, :to => :gene

    def pipeline_name
      self.pipeline.name
    end

    def targeting_vector_name
      targeting_vector.name if targeting_vector
    end

    def targeting_vector_name=(name)
      self.targeting_vector = TargRep::TargetingVector.find_by_name(name) unless name.blank?
    end

    def report_to_public?
      self.report_to_public
    end

    def build_distribution_qc(centre)
      return if centre.blank?
      return if self.distribution_qcs.find_by_es_cell_distribution_centre_id(centre.id)
      self.distribution_qcs.push centre.distribution_qcs.build(:es_cell => self)
    end

    def alleles_attributes
      return alleles.map(&:as_json) unless alleles.blank?
      return nil
    end

    ##
    ## iMits methods
    ##

#    def mgi_allele_id=(arg)
#      return nil
#    end
#
#    def mgi_allele_id
#      return alleles.first.mgi_allele_accession_id unless alleles.blank? || alleles.first.mgi_allele_accession_id.blank?
#      return nil
#    end
#
#    def mgi_allele_symbol_superscript
#      return @mgi_allele_symbol_superscript unless @mgi_allele_symbol_superscript.blank?
#      return alleles.first.mgi_allele_symbol_superscript unless alleles.blank?
#      return nil
#    end
#    alias_method :allele_symbol_superscript, :mgi_allele_symbol_superscript
#
#    def mgi_allele_symbol_superscript=(text)
#      @mgi_allele_symbol_superscript = text
#    end
#    alias_method :allele_symbol_superscript=, :mgi_allele_symbol_superscript=
#
#    def allele_symbol
#      if allele_symbol_superscript
#        return "#{self.marker_symbol}<sup>#{allele_symbol_superscript}</sup>"
#      else
#        return nil
#      end
#    end
#
#    def allele_symbol_superscript_template
#      return Allele.extract_symbol_superscript_template(@mgi_allele_symbol_superscript) unless @mgi_allele_symbol_superscript.blank?
#      return alleles.first.allele_symbol_superscript_template unless alleles.blank?
#      return nil
#    end

    def to_json( options = {} )
      TargRep::EsCell.include_root_in_json = false
      super( JSON_OPTIONS )
    end

    def to_xml( options = {} )
      JSON.parse(self.to_json).to_xml(:root => :my_root)
    end

    def self.southern_tools_url(es_cell_name)
      return '' if es_cell_name.blank?
      return "http://www.sanger.ac.uk/htgt/htgt2/tools/restrictionenzymes?es_clone_name=#{es_cell_name}&iframe=true&width=100%&height=100%"
    end

  protected

#    def set_allele_type
#      return if mgi_allele_symbol_superscript_changed?
#
#      if mgi_allele_symbol_superscript.blank?
#        self.allele_symbol_superscript_template = nil
#        self.allele_type = nil
#        return
#      end
#
#      allele_symbol_superscript_template, self.allele_type = TargRep::Allele.extract_symbol_superscript_template(mgi_allele_symbol_superscript)
#    end

    # Convert any blank attribute strings to nil...
    def convert_blanks_to_nil
      self.attributes.each do |name,value|
        self.send("#{name}=".to_sym, nil) if value.is_a?(String) && value.empty?
      end
    end

    # Helper function to solve the IKMC Project ID consistency validation
    # errors when people are passing integers in as the id...
    def convert_ikmc_project_id_to_string
      self.ikmc_project_id = ikmc_project_id.to_s
    end

    # Helper function to stamp the IKMC Project ID from
    # the parent targeting vector on this cell if it's not
    # been specifically entered
    def stamp_tv_project_id_on_cell
      if ikmc_project_id.nil? and targeting_vector
        self.ikmc_project_id = targeting_vector.ikmc_project_id
      end
    end

    # Set mirKO ikmc_project_ids to "mirKO#{self.allele_id}"
    def set_mirko_ikmc_project_id
      if ( self.ikmc_project_id.blank? or self.ikmc_project_id =~ /^mirko$/i ) and self.pipeline.name == "mirKO"
        self.ikmc_project_id = "mirKO#{ self.allele_id }"
      end
    end

    def remove_empty_distribution_qcs
      self.distribution_qcs.each do |distribution_qc|
        next if ! distribution_qc.is_empty?
        self.distribution_qcs.delete distribution_qc
      end
    end

    # Set the ES Cell Strain
    def set_and_check_strain
      self.strain = case self.parental_cell_line
      when /^JM8A/   then 'C57BL/6N-A<tm1Brd>/a'
      when /^JM8\.A/ then 'C57BL/6N-A<tm1Brd>/a'
      when /^JM8/    then 'C57BL/6N'
      when /^C2/     then 'C57BL/6N'
      when /^AB2/    then '129S7'
      when /^SI/     then '129S7'
      when 'VGB6'    then 'C57BL/6N'
      when 'WCW'     then 'C57BL/6N'
      else
        errors.add( :parental_cell_line, "The parental cell line '#{self.parental_cell_line}' is not recognised" )
      end
    end

  private
    def has_allele_and_targeting_vector?
      !(self.allele.blank? && self.targeting_vector.blank?)
    end


end

# == Schema Information
#
# Table name: targ_rep_es_cells
#
#  id                                    :integer          not null, primary key
#  allele_id                             :integer          not null
#  targeting_vector_id                   :integer
#  parental_cell_line                    :string(255)
#  name                                  :string(100)      not null
#  comment                               :string(255)
#  contact                               :string(255)
#  ikmc_project_id                       :string(255)
#  pipeline_id                           :integer
#  report_to_public                      :boolean          default(TRUE), not null
#  strain                                :string(25)
#  user_qc_map_test                      :string(255)
#  user_qc_karyotype                     :string(255)
#  user_qc_tv_backbone_assay             :string(255)
#  user_qc_loxp_confirmation             :string(255)
#  user_qc_southern_blot                 :string(255)
#  user_qc_loss_of_wt_allele             :string(255)
#  user_qc_neo_count_qpcr                :string(255)
#  user_qc_lacz_sr_pcr                   :string(255)
#  user_qc_mutant_specific_sr_pcr        :string(255)
#  user_qc_five_prime_cassette_integrity :string(255)
#  user_qc_neo_sr_pcr                    :string(255)
#  user_qc_five_prime_lr_pcr             :string(255)
#  user_qc_three_prime_lr_pcr            :string(255)
#  user_qc_comment                       :text
#  mutation_subtype                      :string(100)
#  legacy_id                             :integer
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#  production_centre_auto_update         :boolean          default(TRUE)
#  user_qc_loxp_srpcr_and_sequencing     :string(255)
#  user_qc_karyotype_spread              :string(255)
#  user_qc_karyotype_pcr                 :string(255)
#  user_qc_mouse_clinic_id               :integer
#  user_qc_chr1                          :string(255)
#  user_qc_chr11                         :string(255)
#  user_qc_chr8                          :string(255)
#  user_qc_chry                          :string(255)
#  user_qc_lacz_qpcr                     :string(255)
#  ikmc_project_foreign_id               :integer
#
# Indexes
#
#  es_cells_allele_id_fk            (allele_id)
#  es_cells_pipeline_id_fk          (pipeline_id)
#  targ_rep_index_es_cells_on_name  (name) UNIQUE
#
