class TraceCallVcfModification < ActiveRecord::Base

  acts_as_audited
  acts_as_reportable

  belongs_to :trace_call

  attr_accessible :alt_seq, :chr, :end, :ref_seq, :start, :trace_call_id, :mod_type

  validates :trace_call, :presence => true
end

# == Schema Information
#
# Table name: trace_call_vcf_modifications
#
#  id            :integer          not null, primary key
#  trace_call_id :integer          not null
#  mod_type      :string(255)      not null
#  chr           :string(255)      not null
#  start         :integer          not null
#  end           :integer          not null
#  ref_seq       :text             not null
#  alt_seq       :text             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
