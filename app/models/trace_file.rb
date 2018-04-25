class TraceFile < ActiveRecord::Base
  include ::Public::Serializable
  
  acts_as_audited
  acts_as_reportable

  FULL_ACCESS_ATTRIBUTES = %w{
    is_het
    trace_file_file_name
  }

  READABLE_ATTRIBUTES = %w{
    id
  } + FULL_ACCESS_ATTRIBUTES


  belongs_to :colony

  has_attached_file :trace, :storage => :database
  validates_attachment_file_name :trace, :matches => [/scf\Z/i, /abi\Z/i, /ab1\Z/i]

  attr_accessible :trace

end

# == Schema Information
#
# Table name: trace_files
#
#  id                 :integer          not null, primary key
#  colony_id          :integer          not null
#  is_het             :boolean          default(FALSE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  trace_file_name    :string(255)
#  trace_content_type :string(255)
#  trace_file_size    :integer
#  trace_updated_at   :datetime
#
