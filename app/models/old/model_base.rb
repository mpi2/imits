class Old::ModelBase < ActiveRecord::Base
  def readonly?
    return true
  end
end
