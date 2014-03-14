class TargRep::Crispr < ActiveRecord::Base
  acts_as_audited

  attr_accessible :mutagensis_factor_id, :sequence, :chr, :start, :end

  belongs_to :genes
  belongs_to :mutagenesis_factor

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

