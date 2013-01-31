Ransack.configure do |config|
  config.add_predicate 'ci_in',
   :arel_predicate => 'bob',
   :wants_array => true
end
