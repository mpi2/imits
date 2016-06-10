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
      phenotype_goal_automatically_set
  )

  attr_accessible *READABLE_ATTRIBUTES

  belongs_to :grant

## Callbacks
  after_save :autofill_unset_goals_for_grant

## Validations
  validates :grant, :presence => true
  validates :year, :presence => true
  validates :month, :presence => true


  def crispr_mi_goal=(arg)
    self.cum_crispr_mi_goal = arg
    self.crispr_mi_goal_automatically_set = (arg.blank? ? true : false)
  end

  def crispr_gc_goal=(arg)
    self.cum_crispr_gc_goal = arg
    self.crispr_gc_goal_automatically_set = (arg.blank? ? true : false)
  end

  def es_cell_mi_goal=(arg)
    self.cum_es_cell_mi_goal = arg
    self.es_cell_mi_goal_automatically_set = (arg.blank? ? true : false)
  end

  def es_cell_gc_goal=(arg)
    self.cum_es_cell_gc_goal = arg
    self.es_cell_gc_goal_automatically_set = (arg.blank? ? true : false)
  end

  def excision_goal=(arg)
    self.cum_excision_goal = arg
    self.excision_goal_automatically_set = (arg.blank? ? true : false)
  end

  def phenotype_goal=(arg)
    self.cum_phenotype_goal = arg
    self.phenotype_goal_automatically_set = (arg.blank? ? true : false)
  end

  def autofill_unset_goals_for_grant
    required_a_change_in = ['cum_crispr_mi_goal',
                            'cum_crispr_gc_goal',
                            'cum_es_cell_mi_goal',
                            'cum_es_cell_gc_goal',
                            'cum_excision_goal',
                            'cum_phenotype_goal']

    # only continue if a goal was changed.
    return if (required_a_change_in - self.changes.keys).length == required_a_change_in.length

    # find which goals changed.
    (required_a_change_in & self.changes.keys).each do |goal_type|
      next if self.send("#{goal_type[4, goal_type.length]}_automatically_set")

      lower_goals = []
      lower_limit_goal = 0
      upper_goals = []
      upper_limit_goal = 0

      [*0..(goal_index - 1)].reverse.each do |ind|
        g = all_associated_goals[ind]
        if g.send("#{goal_type[4, goal_type.length]}_automatically_set")
          lower_goals << g
        else
          lower_limit_goal = g.send("#{goal_type}")
          break
        end
      end

      [*(goal_index + 1)..(all_associated_goals.length - 1)].each do |ind|
        g = all_associated_goals[ind]
        if g.send("#{goal_type[4, goal_type.length]}_automatically_set")
          upper_goals << g
          upper_limit_goal = g.send("#{goal_type}")
        else
          upper_limit_goal = g.send("#{goal_type}")
          break
        end
      end

      unless lower_goals.blank?
        interval_size = (self.send("#{goal_type}") - lower_limit_goal) / lower_goals.length
        adjustment = lower_goals.length / ((self.send("#{goal_type}") - lower_limit_goal) % lower_goals.length)
        cum_goal = lower_limit_goal
  
        [*0..(lower_goals.length - 1)].each do |i|
          g = lower_goals[i]
          if adjustment != 0 && (i % adjustment) == 0
            new_goal = interval_size + 1
          else
            new_goal = interval_size
          end
          cum_goal += new_goal
          g.send("#{goal_type}=", cum_goal)
          g.save
        end
      end

      unless upper_goals.blank?
        interval_size = (upper_limit_goal - self.send("#{goal_type}")) / (upper_goals.length + 1)
        positive_adjustment = (upper_goals.length + 1) / ((upper_limit_goal - self.send("#{goal_type}")) % (upper_goals.length + 1))
        negative_adjustment = (upper_goals.length + 1) / (upper_goals.length - ((upper_limit_goal - self.send("#{goal_type}")) % (upper_goals.length + 1)))
        cum_goal = self.send("#{goal_type}")
  
        [*0..(upper_goals.length - 1)].each do |i|
          g = upper_goals[i]
          if positive_adjustment < 1 && negative_adjustment != 0 && (i % negative_adjustment) != 0
            new_goal = interval_size + 1
          elsif positive_adjustment != 0 && (i % positive_adjustment) == 0
            new_goal = interval_size + 1
          else
            new_goal = interval_size
          end
          cum_goal += new_goal
          g.send("#{goal_type}=", cum_goal)
          g.save
        end
      end

    end
  end

  def self.readable_name
    return 'grant_goal'
  end


## Private Instance Methods
  def all_associated_goals
    @grant_goals ||= GrantGoal.where("grant_id = #{self.grant_id}").order(:year, :month)
  end
  private :all_associated_goals

  def goal_index
    return all_associated_goals.map{|gg| gg.id}.find_index(self.id)
  end
  private :goal_index

end

# == Schema Information
#
# Table name: grant_goals
#
#  id                                :integer          not null, primary key
#  grant_id                          :integer          not null
#  year                              :integer          not null
#  month                             :integer          not null
#  cum_crispr_mi_goal                :integer
#  cum_crispr_gc_goal                :integer
#  cum_es_cell_mi_goal               :integer
#  cum_es_cell_gc_goal               :integer
#  cum_total_mi_goal                 :integer
#  cum_total_gc_goal                 :integer
#  cum_excision_goal                 :integer
#  cum_phenotype_goal                :integer
#  crispr_mi_goal_automatically_set  :boolean          default(FALSE), not null
#  crispr_gc_goal_automatically_set  :boolean          default(FALSE), not null
#  es_cell_mi_goal_automatically_set :boolean          default(FALSE), not null
#  es_cell_gc_goal_automatically_set :boolean          default(FALSE), not null
#  excision_goal_automatically_set   :boolean          default(FALSE), not null
#  phenotype_goal_automatically_set  :boolean          default(FALSE), not null
#
