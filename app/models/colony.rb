class Colony < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  validates :name, :presence => true, :uniqueness => true

  #has_attached_file :tfile, :storage => :database, :path => ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension"
  has_attached_file :tfile, :storage => :database   #, :path => ":rails_root/public/trace_files/#{Rails.env}/attachments/:id/:style/:basename.:extension"

  do_not_validate_attachment_file_type :tfile

  belongs_to :mi_attempt

  def self.readable_name
    return 'colony'
  end
end

# == Schema Information
#
# Table name: colonies
#
#  id                 :integer          not null, primary key
#  name               :string(20)       not null
#  mi_attempt_id      :integer
#  tfile_file_name    :string(255)
#  tfile_content_type :string(255)
#  tfile_file_size    :integer
#  tfile_updated_at   :datetime
#
# Indexes
#
#  colony_name_index  (name) UNIQUE
#
