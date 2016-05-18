class GrantGoal < ActiveRecord::Base

  ## Gems/Plugins
  acts_as_audited
  extend AccessAssociationByAttribute
  include ::Public::Serializable

  READABLE_ATTRIBUTES = %w(
      grant_id
      year
      month
      crispr_mi_goal
      crispr_gc_goal
      es_cell_mi_goal
      es_cell_gc_goal
      total_mi_goal
      total_gc_goal
      excision_goal
      phenotype_goal
      crispr_mi_goal_automatically_set
      crispr_gc_goal_automatically_set
      es_cell_mi_goal_automatically_set
      es_cell_gc_goal_automatically_set
      excision_goal_automatically_set
      phenotyping_goal_automatically_set
  )

  attr_accessible *READABLE_ATTRIBUTES

  belongs_to :grant

  ## Validations
  validates :grant, :presence => true
  validates :year, :presence => true
  validates :month, :presence => true
  validates :total_gc_goal, :presence => true


  def self.readable_name
    return 'grant_goal'
  end

end

# == Schema Information
#
# Table name: grant_goals
#
#  id                                 :integer          not null, primary key
#  grant_id                           :integer          not null
#  year                               :integer          not null
#  month                              :integer          not null
#  crispr_mi_goal                     :integer
#  crispr_gc_goal                     :integer
#  es_cell_mi_goal                    :integer
#  es_cell_gc_goal                    :integer
#  total_mi_goal                      :integer
#  total_gc_goal                      :integer
#  excision_goal                      :integer
#  phenotype_goal                     :integer
#  crispr_mi_goal_automatically_set   :boolean          default(FALSE), not null
#  crispr_gc_goal_automatically_set   :boolean          default(FALSE), not null
#  es_cell_mi_goal_automatically_set  :boolean          default(FALSE), not null
#  es_cell_gc_goal_automatically_set  :boolean          default(FALSE), not null
#  excision_goal_automatically_set    :boolean          default(FALSE), not null
#  phenotyping_goal_automatically_set :boolean          default(FALSE), not null
#
