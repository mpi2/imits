class Allele::Annotation < ActiveRecord::Base

  acts_as_audited
  acts_as_reportable

  belongs_to :allele

  attr_accessible :allele_id, :mod_type, :chr, :start, :end, :ref_seq, :alt_seq, :linked_concequence, :downstream_of_stop, :consequence, :dup_coords, :stop_gained

  validates :allele, :presence => true
end

# == Schema Information
#
# Table name: allele_annotations
#
#  id                 :integer          not null, primary key
#  allele_id          :integer          not null
#  mod_type           :string(255)      not null
#  chr                :string(255)      not null
#  start              :integer          not null
#  end                :integer          not null
#  ref_seq            :text
#  alt_seq            :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  dup_coords         :string(255)
#  linked_concequence :text
#  downstream_of_stop :boolean
#  stop_gained        :boolean
#  consequence        :json
#
