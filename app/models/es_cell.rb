class EsCell < ActiveRecord::Base
  raise "You should not be using this." if Rails.env.development?
end
