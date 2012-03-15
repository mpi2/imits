class Notification < ActiveRecord::Base
  attr_accessible :last_email_sent, :welcome_email_sent
  
  belongs_to :contact
  belongs_to :gene
  
end

# == Schema Information
#
# Table name: notifications
#
#  id                 :integer         not null, primary key
#  welcome_email_sent :date
#  last_email_sent    :date
#  gene_id            :integer
#  contact_id         :integer
#  created_at         :datetime
#  updated_at         :datetime
#

