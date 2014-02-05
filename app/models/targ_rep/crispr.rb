class TargRep::Crispr < ActiveRecord::Base
  acts_as_audited

  attr_accessible :name, :gene_id

  belongs_to :genes
  belongs_to :mutagenesis_factor

  validates :name, :presence => true, :uniqueness => true
  validates :gene_id, :presence => true

end




# == Schema Information
#
# Table name: targ_rep_crisprs
#
#  id                   :integer         not null, primary key
#  mutagensis_factor_id :integer         not null
#  sequence             :string(255)     not null
#  start                :integer
#  end                  :integer
#  gene_id              :integer         not null
#  created_at           :datetime
#

