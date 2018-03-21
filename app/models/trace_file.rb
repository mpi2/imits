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
