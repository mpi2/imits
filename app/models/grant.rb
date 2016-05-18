class Grant < ActiveRecord::Base

  ## Gems/Plugins
  acts_as_audited
  extend AccessAssociationByAttribute
  include ::Public::Serializable

  READABLE_ATTRIBUTES = %w(
      name
      funding
      consortium_name
      production_centre_name
      commence
      end
      grant_goal
  )

  attr_accessible *READABLE_ATTRIBUTES

  belongs_to :consortium
  belongs_to :production_centre, :class_name => 'Centre'

  has_many :grant_goals
  has_many :ordered_grant_goals, :class_name => 'GrantGoal', :order => 'grant_goals.year, grant_goals.month'

  access_association_by_attribute :consortium, :name
  access_association_by_attribute :production_centre, :name

  before_save :auto_generate_blank_goals

  ## Validations
  validates :name, :presence => true, :uniqueness => true
  validates :consortium_id, :presence => true
  validates :production_centre_id, :presence => true
  validates :commence, :presence => true
  validates :end, :presence => true

  def auto_generate_blank_goals 

    
  end

  def grant_goal #number of mouse lines to be produced and phenotyped
    return @grant_goal unless @grant_goal.blank?
    return final_goal.total_gc_goal unless final_goal.blank?
    return nil
  end

  def grant_goal=(arg)
    return nil unless arg.class == Fixnum
    @grant_goal = arg
  end

  def final_goal
    gg = grant_goals.order('year desc, month desc')
    return gg.first unless gg.blank?
    return nil
  end

  def self.readable_name
    return 'grant'
  end

end

# == Schema Information
#
# Table name: grants
#
#  id                   :integer          not null, primary key
#  name                 :string(255)      not null
#  funding              :string(255)      not null
#  consortium_id        :integer          not null
#  production_centre_id :integer          not null
#  commence             :date             not null
#  end                  :date             not null
#
