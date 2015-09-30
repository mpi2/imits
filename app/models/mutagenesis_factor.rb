class MutagenesisFactor < ActiveRecord::Base
  acts_as_audited

  NUCLEASES = [nil, 'CAS9 mRNA', 'CAS9 Protein', 'D10A mRNA', 'D10A Protein'].freeze

  attr_accessible :vector_name, :crisprs_attributes, :genotype_primers_attributes, :external_ref, :nuclease

  # NOTE! make sure that the crispr association always appears above the mi_attempt association. Changing the order will prevent the mi_attempt from saving. This results from the implimention of the nested_attributes method
  has_many :crisprs, :class_name => 'TargRep::Crispr', :inverse_of => :mutagenesis_factor, dependent: :destroy
  has_many :genotype_primers, :class_name => 'TargRep::GenotypePrimer', :inverse_of => :mutagenesis_factor, dependent: :destroy

  belongs_to :gene_target
  belongs_to :vector, :class_name => 'TargRep::TargetingVector'

  accepts_nested_attributes_for :crisprs
  accepts_nested_attributes_for :genotype_primers, :allow_destroy => true

  before_validation :set_vector_from_vector_name

  before_validation do |mi|
    if ! mi.external_ref.nil?
      mi.external_ref = mi.external_ref.to_s.strip || mi.external_ref
      mi.external_ref = mi.external_ref.to_s.gsub(/\s+/, ' ')
    end
  end

  before_validation do |mf|
    mf.nuclease = nil if mf.nuclease.blank?
  end

  validates :external_ref, :uniqueness => {:case_sensitive => false}, :allow_nil => true
  validates :nuclease, :inclusion => { :in => NUCLEASES}, :allow_nil => true

  validate do |m|
    if m.crisprs.length == 0
      m.errors.add :crisprs, "missing. Please input at least one crispr"
    end
  end

  before_save :set_external_ref_if_blank

  def set_vector_from_vector_name
    if self.vector.nil? or self.vector.name != vector_name
      self.vector = TargRep::TargetingVector.find_by_name(self.vector_name)
    end
  end
  protected :set_vector_from_vector_name


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


  def marker_symbol
    return gene_target.marker_symbol unless gene_target.blank?
    plan = MiPlan.find(mi_plan_id)
    return nil if mi_plan.blank?
    return plan.marker_symbol
  end

  def mi_plan_id
    @mi_plan_id unless @mi_plan_id.blank?
    return nil if gene_target.blank?
    return gene_target.mi_plan_id
  end

  def mi_plan_id=(arg)
    return nil if arg.class.name != 'Fixnum'
    plan = MiPlan.find(arg)
    return nil if plan.blank?

    @mi_plan_id = plan.id
  end

  def vector_name
    if @vector_name
      return @vector_name
    elsif self.vector
      return self.vector.name
    else
      return nil
    end
  end


  def vector_name=(arg)
    if self.vector.nil? or self.vector.name != arg
      @vector_name = arg
    end
  end

end

# == Schema Information
#
# Table name: mutagenesis_factors
#
#  id             :integer          not null, primary key
#  vector_id      :integer
#  external_ref   :string(255)
#  nuclease       :text
#  gene_target_id :integer
#
