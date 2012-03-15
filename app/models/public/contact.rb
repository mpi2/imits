class Public::Contact < ::Contact
  extend AccessAssociationByAttribute
  include Public::Serializable

  FULL_ACCESS_ATTRIBUTES = [
  'email',
  'first_name',
  'last_name',
  'institution',
  'organisation' 
  ]

  READABLE_ATTRIBUTES = [
    'id'
  ] + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*FULL_ACCESS_ATTRIBUTES)
  
end

# == Schema Information
#
# Table name: contacts
#
#  id           :integer         not null, primary key
#  email        :string(255)     not null
#  first_name   :string(255)
#  last_name    :string(255)
#  institution  :string(255)
#  organisation :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_contacts_on_email  (email) UNIQUE
#

