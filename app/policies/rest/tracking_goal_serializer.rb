# encoding: utf-8

class Rest::TrackingGoalSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    goal
    crispr_goal
    total_goal
    goal_type
    year
    month
    date
    production_centre_name
    consortium_name
  }


  def initialize(tracking_goal)
    @tracking_goal = tracking_goal
  end

  def as_json
    json_hash = super(@tracking_goal)
    return json_hash
  end
end

#  READABLE_ATTRIBUTES = %w(
#    id
#    goal
#    crispr_goal
#    total_goal
#    goal_type
#    year
#    month
#    date
#    production_centre_name
#    production_centre_id
#    consortium_name
#    consortium_id
#    consortium_id_not_null
#  )