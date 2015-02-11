require "#{Rails.root}/script/check_unreconciled_komp_with_mmrrc.rb"

namespace :check_unreconciled_komp_with_mmrrc do

    desc 'Check unreconciled Komp distribution centres against the MMRRC repository'

    task 'run' => [:environment] do |t, args|
        # create instance of reconcile class and run it
        CheckUnreconciledKompWithMmrrc.new( nil, nil ).check_komp_distribution_centres
    end
end