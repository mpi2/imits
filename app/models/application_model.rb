class ApplicationModel < ActiveRecord::Base
  def audit_on_save
    self.edit_date = Time.now
    self.edited_by = 'jb27'
  end
  protected :audit_on_save
end
