Ransack.configure do |config|
  config.add_predicate 'ci_in',
                       :arel_predicate => 'ci_in',
                       :wants_array => true
end
