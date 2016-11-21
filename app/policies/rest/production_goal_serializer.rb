# encoding: utf-8

class Rest::ProductionGoalSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    year
    month
    mi_goal
    gc_goal
    crispr_mi_goal
    crispr_gc_goal
    total_mi_goal
    total_gc_goal
    consortium_name
    consortium_id
  }


  def initialize(goal)
    @goal = goal
  end

  def as_json
    json_hash = super(@goal)
    return json_hash
  end
end
