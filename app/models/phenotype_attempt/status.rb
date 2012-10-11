# encoding: utf-8

class PhenotypeAttempt::Status < ActiveRecord::Base
  include StatusInterface
end

# == Schema Information
#
# Table name: phenotype_attempt_statuses
#
#  id         :integer         not null, primary key
#  name       :string(50)      not null
#  created_at :datetime
#  updated_at :datetime
#  order_by   :integer
#  code       :string(10)      not null
#

