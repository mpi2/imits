class Old::Centre < ActiveRecord::Base
  set_table_name 'per_centre'

  def readonly?
    return true
  end
end
