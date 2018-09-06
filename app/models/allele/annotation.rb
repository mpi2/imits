class Allele::Annotation < ActiveRecord::Base

  acts_as_audited
  acts_as_reportable

  belongs_to :allele, :class_name => 'Allele'

  attr_accessible :allele_id, :mod_type, :chr, :start, :end, :ref_seq, :alt_seq, :exdels, :partial_exdels, :txc, :splice_donor, :splice_acceptor, :protein_coding_region, :intronic, :frameshift

  validates :allele, :presence => true
end

# == Schema Information
#
# Table name: allele_annotations
#
#  id                    :integer          not null, primary key
#  allele_id             :integer          not null
#  mod_type              :string(255)      not null
#  chr                   :string(255)      not null
#  start                 :integer          not null
#  end                   :integer          not null
#  ref_seq               :text
#  alt_seq               :text
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  exdels                :string(255)
#  partial_exdels        :string(255)
#  txc                   :string(255)
#  splice_donor          :boolean
#  splice_acceptor       :boolean
#  protein_coding_region :boolean
#  intronic              :boolean
#  frameshift            :boolean
#  linked_concequence    :text
#  downstream_of_stop    :boolean
#  stop_gained           :boolean
#  amino_acid            :text
#
