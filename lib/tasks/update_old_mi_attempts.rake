require "#{Rails.root}/script/update_old_mi_attempts.rb"

namespace :update_old_mi_attempts do

  desc 'Update old Mi Attempts to inactive in Imits'
  task 'run' => [:environment] do
     UpdateOldMiAttempts.new.run
  end
end