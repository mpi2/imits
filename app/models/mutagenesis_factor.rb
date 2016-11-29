class MutagenesisFactor < ActiveRecord::Base
  acts_as_audited

  PRIVATE_ATTRIBUTES = %w{
    individually_set_grna_concentrations
    guides_generated_in_plasmid
    grna_concentration
    crisprs_attributes
    vectors_attributes
    genotype_primers_attributes
  }

  NUCLEASES = [nil, 'CAS9', 'D10A'].freeze

  attr_accessible :crisprs_attributes, :genotype_primers_attributes, :external_ref, :grna_concentration, :individually_set_grna_concentrations, :crisprs_attributes, :vectors_attributes

  # NOTE! make sure that the crispr association always appears above the mi_attempt association. Changing the order will prevent the mi_attempt from saving. This results from the implimention of the nested_attributes method
  has_many :crisprs, :class_name => 'TargRep::Crispr', :inverse_of => :mutagenesis_factor, dependent: :destroy
  has_many :vectors, :class_name => 'MutagenesisFactor::Vector', dependent: :destroy
  has_many :genotype_primers, :class_name => 'TargRep::GenotypePrimer', :inverse_of => :mutagenesis_factor, dependent: :destroy

  has_one :mi_attempt, :inverse_of => :mutagenesis_factor

  accepts_nested_attributes_for :crisprs
  accepts_nested_attributes_for :vectors, :allow_destroy => true
  accepts_nested_attributes_for :genotype_primers, :allow_destroy => true

  delegate :marker_symbol, :to => :mi_attempt

  before_validation do |mi|
    if ! mi.external_ref.nil?
      mi.external_ref = mi.external_ref.to_s.strip || mi.external_ref
      mi.external_ref = mi.external_ref.to_s.gsub(/\s+/, ' ')
    end
  end

  validates :external_ref, :uniqueness => {:case_sensitive => false}, :allow_nil => true

  validate do |m|
    if m.crisprs.length == 0
      m.errors.add :crisprs, "missing. Please input at least one crispr"
    end
  end

  # validate gRNA concentrations
  validate do |mf| 
    if mf.individually_set_grna_concentrations
      if mf.crisprs.any?{|c| c.grna_concentration.blank?}
        mf.errors.add :base, "All individual gRNA require a concentration when you set 'Indivdually Set Concentrations' to true"
      else
        mf.grna_concentration = nil
      end
    else
      if !mf.grna_concentration.blank? && mf.grna_concentration > 0
        mf.crisprs.each{|c| c.grna_concentration = nil}
      elsif mf.crisprs.any?{|c| !c.grna_concentration.blank?}
        mf.errors.add :base, "You must set all individual gRNA concentrations to 0 if you are not going to individually set the gRNA concentrations"
      end
    end
  end

  before_save :set_external_ref_if_blank

  def set_external_ref_if_blank
    if self.external_ref.blank?
      prefix = 'MF'
      i = 0
      begin
        i += 1
        self.external_ref = "#{prefix}-#{i}"
      end until self.class.find_by_external_ref(self.external_ref).blank?
    end

  end
  protected :set_external_ref_if_blank

  def crisprs_attributes
    return crisprs
  end

  def vectors_attributes
    return vectors
  end

  def genotype_primers_attributes
    return genotype_primers
  end

  def rest_serializer
    return Rest::MutagenesisFactorSerializer
  end

  def grid_serializer
    return Grid::MutagenesisFactorSerializer
  end
end

# == Schema Information
#
# Table name: mutagenesis_factors
#
#  id                                       :integer          not null, primary key
#  external_ref                             :string(255)
#  individually_set_grna_concentrations     :boolean          default(FALSE), not null
#  guides_generated_in_plasmid              :boolean          default(FALSE), not null
#  grna_concentration                       :float
#  no_g0_where_mutation_detected            :integer
#  no_nhej_g0_mutants                       :integer
#  no_deletion_g0_mutants                   :integer
#  no_hr_g0_mutants                         :integer
#  no_hdr_g0_mutants                        :integer
#  no_hdr_g0_mutants_all_donors_inserted    :integer
#  no_hdr_g0_mutants_subset_donors_inserted :integer
#  private                                  :boolean          default(FALSE), not null
#
