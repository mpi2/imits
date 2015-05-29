require "#{Rails.root}/script/check_unreconciled_komp_with_mmrrc.rb"

namespace :check_unreconciled_komp_with_mmrrc do
  desc 'Check unreconciled Komp distribution centres against the MMRRC repository'
  # optionally pass in the filepaths for where the csv results will be output
  task 'run', [:mi_attempt_csv_filepath, :phenotype_attempt_csv_filepath] => [:environment] do |t, args|
    # defaults for filepaths
    args.with_defaults(
      :mi_attempt_csv_filepath        => '/nfs/team87/reconcile_output/unreconciled_komp_mi_dc_data.csv',
      :phenotype_attempt_csv_filepath => '/nfs/team87/reconcile_output/unreconciled_komp_pa_dc_data.csv'
    )
    # create instance of reconcile class and run it
    CheckUnreconciledKompWithMmrrc.new(args[:mi_attempt_csv_filepath], args[:phenotype_attempt_csv_filepath]).check_komp_distribution_centres
  end
end