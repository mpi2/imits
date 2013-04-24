require 'test_helper'

class ApplicationModel::BelongsToMiPlanTest < ActiveSupport::TestCase

  def self.tests

    context '#mi_plan' do
      should 'be in DB' do
        assert_should have_db_column(:mi_plan_id).of_type(:integer).with_options(:null => false)
      end

      should 'exist' do
        assert_should belong_to :mi_plan
      end

    end # context '#mi_plan'

  end # def self.tests

  context 'ApplicationModel::BelongsToMiPlan' do

    context 'for MiAttempt' do
      subject { MiAttempt.new }
      setup do
        @factory = :mi_attempt
      end
      tests

      should 'report error if trying to save with an mi_plan that is not assigned or is inactive' do
        plan = Factory.create :mi_plan_with_production_centre, :gene => cbx1, :is_active => false
        assert_equal 'ina', plan.status.code
        object = Factory.build :mi_attempt2, :mi_plan => plan
        assert_raise(ApplicationModel::BelongsToMiPlan::UnsuitableMiPlanError) do
          object.save
        end

        plan.destroy
        unused_plan = Factory.create :mi_plan, :gene => cbx1
        plan = Factory.create :mi_plan_with_production_centre, :gene => cbx1
        assert_equal 'ins-con', plan.status.code
        object = Factory.build :mi_attempt2, :mi_plan => plan
        assert_raise(ApplicationModel::BelongsToMiPlan::UnsuitableMiPlanError) do
          object.save
        end
      end

      should 'raise if mi_plan does not exist' do
        object = Factory.build :mi_attempt2
        object.mi_plan = nil

        object.valid?
        assert_match(/An mi_plan MUST be assigned via mi_plan_id/i, object.errors[:base].join('; '))
      end
    end # context 'for MiAttempt'

    context 'for PhenotypeAttempt' do
      subject { PhenotypeAttempt.new }
      setup do
        @factory = :public_phenotype_attempt
      end
      tests

      should 'default to mi_attempt.mi_plan' do
        plan = Factory.create :mi_plan_with_production_centre
        mi = Factory.create(:mi_attempt2_status_gtc, :mi_plan_id => plan.id)
        pt = Factory.build :phenotype_attempt, :mi_plan_id => nil, :mi_attempt => mi
        pt.save!
        assert_equal plan, pt.mi_plan
      end
    end

    context 'for Public::MiAttempt' do
      subject { Public::MiAttempt.new }
      setup do
        @factory = :public_mi_attempt
      end

      context '#mi_plan and #mi_plan_id test:' do
        should 'force #mi_plan to be assigned and active if children are active' do
          unused_plan = Factory.create :mi_plan_with_production_centre, :gene => cbx1

          es_cell = Factory.create :es_cell, :allele => Factory.create(:allele, :gene => cbx1)
          inactive_plan = Factory.create :mi_plan_with_production_centre, :gene => cbx1, :is_active => false
          conflict_plan = Factory.create :mi_plan_with_production_centre, :gene => cbx1
          assert_equal 'ins-con', conflict_plan.status.code
          assert_equal 'ina', inactive_plan.status.code

          Factory.create :public_mi_attempt, :es_cell_name => es_cell.name, :mi_plan_id => inactive_plan.id
          Factory.create :public_mi_attempt, :es_cell_name => es_cell.name, :mi_plan_id => conflict_plan.id

          inactive_plan.reload
          conflict_plan.reload

          assert_true inactive_plan.has_status? :asg
          assert_false inactive_plan.has_status? :ina
          assert_true conflict_plan.has_status? :asg
          assert_false conflict_plan.has_status? 'ins-con'
        end

        should 'set target mi_plan to assigned when moving it to that one' do
          old_plan = Factory.create :mi_plan_with_production_centre, :gene => cbx1
          mi = Factory.create(:mi_attempt2, :mi_plan => old_plan).to_public

          es_cell = Factory.create :es_cell, :allele => Factory.create(:allele, :gene => cbx1)
          new_plan = Factory.create :mi_plan_with_production_centre, :gene => cbx1
          assert_equal 'ins-mip', new_plan.status.code

          mi = Public::MiAttempt.find(mi.id)
          assert_equal old_plan.id, mi.mi_plan.id # DO NOT REMOVE THIS LINE
          mi.attributes = {'mi_plan_id' => new_plan.id}
          assert mi.save
          new_plan.reload
          assert_equal 'asg', new_plan.status.code
        end

        should 'allow #mi_plan to be inactive if children are inactive' do
          es_cell = Factory.create :es_cell, :allele => Factory.create(:allele, :gene => cbx1)
          inactive_plan = Factory.create :mi_plan_with_production_centre, :gene => cbx1, :is_active => false
          assert_equal 'ina', inactive_plan.status.code

          Factory.create :public_mi_attempt, :es_cell_name => es_cell.name, :mi_plan_id => inactive_plan.id, :is_active => false
          assert_true inactive_plan.has_status? :asg
          assert_true inactive_plan.has_status? :ina
        end
      end
    end # context 'for Public::MiAttempt'

    context 'for Public::PhenotypeAttempt' do
      subject { Public::PhenotypeAttempt.new }
      setup do
        @factory = :public_phenotype_attempt
      end
    end

  end
end
