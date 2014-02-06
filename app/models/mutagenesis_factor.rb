class MutagenesisFactor < ActiveRecord::Base
  acts_as_audited

  attr_accessible :crispr_method, :vector_name, :crisprs_attributes

  has_one :mi_attempt
  has_many :crisprs, :class_name => 'TargRep::Crispr'
  belongs_to :vector, :class_name => 'TargRep::TargetingVector'

  accepts_nested_attributes_for :crisprs

  before_validation :set_vector_from_vector_name


  validate do |mf|
    crispr_count = mf.crisprs.length
    case self.crispr_method
    when 1
      #1 crispr
      if crispr_count != 1
        mf.errors.add(:crispr_method, '= 1 requires 1 crispr')
      end
    when 2
      #1 crispr with vector
      if crispr_count != 1 or self.vector.blank?
        mf.errors.add(:crispr_method, '= 2 requires 1 crispr and a vector')
      end
    when 3
      #2 crisprs
      if crispr_count != 2
        mf.errors.add(:crispr_method, '= 3 requires 2 crisprs')
      end
    when 4
      #2 crisprs with vector
      if crispr_count != 2 or self.vector.blank?
        mf.errors.add(:crispr_method, '= 4 requires 2 crisprs and a vector')
      end
    when 5
      #4 crisprs
      if crispr_count != 4
        mf.errors.add(:crispr_method, '= 5 requires 4 crisprs')
      end
    when 6
      #4 crisprs with vector
      if crispr_count != 4 or self.vector.blank?
        mf.errors.add(:crispr_method, '= 6 requires 4 crisprs and a vector')
      end
    end
  end


  def set_vector_from_vector_name
    if vector.nil? and !vector_name.blank?
      self.vector = TargRep::TargetingVector.find_by_name(self.vector_name)
    end
  end


  def vector_name
    if(self.vector)
      return self.vector.name
    else
      return @vector_name
    end
  end


  def vector_name=(arg)
    if(! self.vector)
      @vector_name = arg
    end
  end

  def self.get_cripr_method_names
    [1, 2, 3, 4, 5, 6]
  end

end






# == Schema Information
#
# Table name: mutagenesis_factors
#
#  id            :integer         not null, primary key
#  vector_id     :integer
#  crispr_method :string(255)     not null
#

