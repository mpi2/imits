class MutagenesisFactor < ActiveRecord::Base
  acts_as_audited

  attr_accessible :vector_name, :crisprs_attributes

  has_one :mi_attempt
  has_many :crisprs, :class_name => 'TargRep::Crispr'
  belongs_to :vector, :class_name => 'TargRep::TargetingVector'

  accepts_nested_attributes_for :crisprs

  before_validation :set_vector_from_vector_name


  def set_vector_from_vector_name
    if self.vector.nil? or self.vector.name != vector_name
      self.vector = TargRep::TargetingVector.find_by_name(self.vector_name)
    end
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
#  id        :integer         not null, primary key
#  vector_id :integer
#

