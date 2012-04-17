class Notification < ActiveRecord::Base
  include Notification::StatusChecker
  attr_accessor :relevant_statuses
  attr_accessible :last_email_sent, :welcome_email_sent, :last_email_text, :welcome_email_text, :relevant_statuses

  belongs_to :contact
  belongs_to :gene

  validates :contact, :presence => true
  validates :gene, :presence => true

end

# == Schema Information
#
# Table name: notifications
#
#  id                 :integer         not null, primary key
#  welcome_email_sent :datetime
#  welcome_email_text :text
#  last_email_sent    :datetime
#  last_email_text    :text
#  gene_id            :integer
#  contact_id         :integer
#  created_at         :datetime
#  updated_at         :datetime
#

