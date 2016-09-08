class TraceFile < ActiveRecord::Base

  acts_as_audited
  acts_as_reportable

  belongs_to :colony
  belongs_to :mutagenesis_factor

  has_attached_file :trace, :storage => :database
  do_not_validate_attachment_file_type :trace
  attr_accessible :trace
  attr_accessible :is_het

  validate :colony, :presence => true
  validate :mutagenesis_factor, :presence => true
  validate :is_het, :presence => true
end

# == Schema Information
#
# Table name: trace_files
#
#  id                    :integer          not null, primary key
#  colony_id             :integer          not null
#  is_het                :boolean          default(FALSE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  trace_file_name       :string(255)
#  trace_content_type    :string(255)
#  trace_file_size       :integer
#  trace_updated_at      :datetime
#  mutagenesis_factor_id :integer
#
