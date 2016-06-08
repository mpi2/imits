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
      commence_date
      end_date
      grant_goal
  )

  attr_accessible *READABLE_ATTRIBUTES

  belongs_to :consortium
  belongs_to :production_centre, :class_name => 'Centre'

  has_many :grant_goals
  has_many :ordered_grant_goals, :class_name => 'GrantGoal', :order => 'grant_goals.year, grant_goals.month'

  access_association_by_attribute :consortium, :name
  access_association_by_attribute :production_centre, :name

  after_save :auto_generate_blank_goals
  after_save :set_final_goal

  ## Validations
  validates :name, :presence => true, :uniqueness => true
  validates :consortium_id, :presence => true
  validates :production_centre_id, :presence => true
  validates :commence_date, :presence => true
  validates :end_date, :presence => true

  def auto_generate_blank_goals
    raise if commence_date.blank? || end_date.blank? # should be caught by validation
    raise if commence_date.to_date > end_date.to_date

    cursor_date = commence_date.to_date.at_beginning_of_month

    while cursor_date <= end_date.to_date do
      
      if grant_goals.where("month = #{cursor_date.month} AND year = #{cursor_date.year}").blank?
        grant_goals.create({ year: cursor_date.year,
            month: cursor_date.month,
            crispr_mi_goal: 0,
            crispr_gc_goal: 0,
            es_cell_mi_goal: 0,
            es_cell_gc_goal: 0,
            total_mi_goal: 0,
            total_gc_goal: 0,
            excision_goal: 0,
            phenotype_goal: 0,
            crispr_mi_goal_automatically_set: true,
            crispr_gc_goal_automatically_set: true,
            es_cell_mi_goal_automatically_set: true,
            es_cell_gc_goal_automatically_set: true,
            excision_goal_automatically_set: true,
            phenotyping_goal_automatically_set: true
        })
      end

      cursor_date = cursor_date.next_month
    end
  end

  def set_final_goal
    fg = final_goal
    fg.total_gc_goal = grant_goal
    fg.save
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
#  commence_date        :date             not null
#  end_date             :date             not null
#
