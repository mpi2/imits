class TargRep::Crispr < ActiveRecord::Base
  acts_as_audited

  attr_accessible :mutagensis_factor_id, :sequence, :chr, :start, :end

  belongs_to :genes
  belongs_to :mutagenesis_factor, :inverse_of => :crisprs

  before_validation :upper_case_sequence

  validates_presence_of :mutagenesis_factor

  validates_format_of :sequence,
      :with       => /^[ACGT]+$/i,
      :message    => "Crispr sequence must consist of a sequence of 'A', 'C', 'G' or 'T'"

  validates :start, :numericality => {:only_integer => true, :greater_than => 0}

  validates :end, :numericality => {:only_integer => true, :greater_than => 0}

  validate do |crispr|
    if crispr.sequence.length != 23
      crispr.errors.add :sequence, "must have a length of 23"
    end
  end


  def upper_case_sequence
    self.sequence = self.sequence.upcase
  end
  protected :upper_case_sequence
end






# == Schema Information
#
# Table name: targ_rep_crisprs
#
#  id                    :integer         not null, primary key
#  mutagenesis_factor_id :integer         not null
#  sequence              :string(255)     not null
#  chr                   :string(255)
#  start                 :integer
#  end                   :integer
#  created_at            :datetime
#

