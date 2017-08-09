class User < ActiveRecord::Base
  ADMIN_USERS = [
    'as28@sanger.ac.uk',
    'vvi@sanger.ac.uk',
    're4@sanger.ac.uk',
    'pen1adm@sanger.ac.uk',
    'pen2adm@sanger.ac.uk',
    'jr18@sanger.ac.uk'
  ]

  REMOTE_ACCESS_USERS = [
    'as28@sanger.ac.uk',
    'vvi@sanger.ac.uk',
    're4@sanger.ac.uk',
    'a.blake@har.mrc.ac.uk'
  ]

  devise :database_authenticatable, :rememberable, :validatable, :recoverable

  attr_accessible :email, :password, :password_confirmation, :remember_me,
          :production_centre, :filter_by_centre_name, :production_centre_id, :filter_by_centre_id, :name, :is_contactable

  validates :production_centre_id, :presence => true

  belongs_to :production_centre, :class_name => 'Centre'
  belongs_to :filter_by_centre, :class_name => 'Centre'

  belongs_to :es_cell_distribution_centre, :class_name => "TargRep::EsCellDistributionCentre"

  after_initialize do
    self.remember_me = true
  end

  def remote_access?
    return REMOTE_ACCESS_USERS.include?(email)
  end

  def can_see_sub_project?
    return ['WTSI','JAX'].include?(production_centre.name)
  end

  def production_centre_name
    return nil if production_centre.blank?
    production_centre.name
  end

  def filter_by_centre_name
    return nil if filter_by_centre.blank?
    filter_by_centre.name
  end
end

# == Schema Information
#
# Table name: users
#
#  id                             :integer          not null, primary key
#  email                          :string(255)      default(""), not null
#  encrypted_password             :string(128)      default(""), not null
#  remember_created_at            :datetime
#  production_centre_id           :integer          not null
#  created_at                     :datetime
#  updated_at                     :datetime
#  name                           :string(255)
#  is_contactable                 :boolean          default(FALSE)
#  reset_password_token           :string(255)
#  reset_password_sent_at         :datetime
#  es_cell_distribution_centre_id :integer
#  legacy_id                      :integer
#  admin                          :boolean          default(FALSE)
#  active                         :boolean          default(TRUE)
#  filter_by_centre_id            :string(255)
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
