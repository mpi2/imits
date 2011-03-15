class ApplicationModel < ActiveRecord::Base
  def audit_on_save
    self.edit_date = Time.now
  end
  protected :audit_on_save
end
