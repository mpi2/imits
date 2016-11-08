class Centre < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  PRIVATE_ATTRIBUTES = %w{
  }

  FULL_ACCESS_ATTRIBUTES = %w{
    name
    contact_name
    contact_email
  }

  READABLE_ATTRIBUTES = %w{
    id
    code
    superscript
  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)

  validates :name, :presence => true, :uniqueness => true



  def has_children?
    ! (mi_plans.empty? && mi_attempt_distribution_centres.empty? && phenotype_attempt_distribution_centres.empty?)
  end

  def destroy
    return false if has_children?
    super
  end

  def self.readable_name
    return 'centre'
  end

end

# == Schema Information
#
# Table name: centres
#
#  id            :integer          not null, primary key
#  name          :string(100)      not null
#  created_at    :datetime
#  updated_at    :datetime
#  contact_name  :string(100)
#  contact_email :string(100)
#  code          :string(255)
#  superscript   :string(255)
#
# Indexes
#
#  index_centres_on_name  (name) UNIQUE
#
