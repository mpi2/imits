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

  def self.public_tests

    context '#consortium_name and #production_centre_name' do
      should 'both be assigned or neither' do
        subject.consortium_name = 'BaSH'
        subject.production_centre_name = ''
        subject.valid?
        assert_match /both or neither.+must be assigned/i, subject.errors[:base].first

        subject.consortium_name = ''
        subject.production_centre_name = 'WTSI'
        subject.valid?
        assert_match /both or neither.+must be assigned/i, subject.errors[:base].first
      end

      should 'not be passed in if #mi_plan_id is passed in' do
        plan = Factory.create :mi_plan
        subject.mi_plan_id = plan.id
        assert_equal true, subject.changes.has_key?(:mi_plan_id)
        subject.consortium_name = 'BaSH'
        subject.production_centre_name = 'WTSI'
        subject.valid?
        assert_equal true, subject.changes.has_key?(:mi_plan_id)

        assert_match /mi_plan_id.+consortium_name.+production_centre_name/, subject.errors[:base].first
      end

      should 'be writable with any value which should be returned on a read when no MiPlan is set' do
        if @factory == :public_mi_attempt
          common_attrs = {:mi_plan => nil, :es_cell_name => nil}
        elsif @factory == :public_phenotype_attempt
          common_attrs = {:mi_plan => nil, :mi_attempt_colony_name => nil}
        end

        object = Factory.build @factory, common_attrs.merge(:consortium_name => 'Foo')
        assert_equal 'Foo', object.consortium_name

        object = Factory.build @factory, common_attrs.merge(:production_centre_name => 'Foo')
        assert_equal 'Foo', object.production_centre_name
      end

      should 'be equal to the associated mi_plan values if they have not yet been set' do
        plan = TestDummy.mi_plan 'BaSH', 'WTSI'
        object = Factory.build @factory,
                :mi_plan => plan,
                :consortium_name => nil,
                :production_centre_name => nil
        assert_equal 'BaSH', object.consortium_name
        assert_equal 'WTSI', object.production_centre_name
      end

      should ',on update, NOT fail validation' do
        object = Factory.create @factory
        object.consortium_name = 'MARC'
        object.production_centre_name = 'MARC'
        assert object.valid?, object.errors.inspect
      end

      should 'fail validation when set to nonexistent values' do
        subject.consortium_name = 'Nonexistent Consortium'
        subject.production_centre_name = 'Nonexistent Production Centre'
        subject.valid?
        assert_equal ['does not exist', 'does not exist'],
                subject.errors['consortium_name'] + subject.errors['production_centre_name']

        subject.valid?
        assert_equal ['does not exist'], subject.errors['consortium_name']
      end

      should 'use #consortium_name and #prduction_centre_name to look up a plan if they are supplied' do
        assert cbx1
        plan = TestDummy.mi_plan('BaSH', 'WTSI', 'Cbx1')
        common_attrs = {
          :mi_plan => nil,
          :consortium_name => 'BaSH',
          :production_centre_name => 'WTSI'
        }
        if @factory == :public_mi_attempt
          es_cell = Factory.create(:es_cell, :gene => cbx1)
          common_attrs[:es_cell_name] = es_cell.name
        elsif @factory == :public_phenotype_attempt
          mi = Factory.create :mi_attempt2_status_gtc, :mi_plan => plan
          common_attrs[:mi_attempt_colony_name] = mi.colony_name
        end

        object = Factory.create @factory, common_attrs
        assert_equal plan, object.mi_plan
      end

      should 'use #consortium_name and #prduction_centre_name to create a new plan if they are supplied and a plan is not found' do
        assert cbx1
        common_attrs = {
          :mi_plan => nil,
          :consortium_name => 'BaSH',
          :production_centre_name => 'WTSI'
        }
        if @factory == :public_mi_attempt
          es_cell = Factory.create(:es_cell, :gene => cbx1)
          common_attrs[:es_cell_name] = es_cell.name
        elsif @factory == :public_phenotype_attempt
          mi = Factory.create :mi_attempt2_status_gtc, :mi_plan => TestDummy.mi_plan('ICS', 'Cbx1')
          common_attrs[:mi_attempt_colony_name] = mi.colony_name
        end

        object = Factory.create @factory, common_attrs

        p = object.mi_plan
        assert_equal ['BaSH', 'WTSI', 'Cbx1', 'Assigned', 'High'],
                [p.consortium.name, p.production_centre.name, p.gene.marker_symbol, p.status.name, p.priority.name]
      end

    end # context '#consortium_name and #production_centre_name'

    should 'return the same mi_plan if it has the same production centre and consortium that are passed in' do
      assert cbx1
      plan1 = TestDummy.mi_plan('BaSH', 'WTSI', 'Cbx1', :force_assignment => true)
      plan2 = TestDummy.mi_plan('BaSH', 'WTSI', 'Cbx1', 'MGPinterest', :force_assignment => true)
      es_cell = Factory.create(:es_cell, :gene => cbx1)

      if @factory == :public_mi_attempt
        object = Factory.create @factory,
                :mi_plan_id => plan2.id,
                :es_cell_name => es_cell.name
      elsif @factory == :public_phenotype_attempt
        mi = Factory.create :mi_attempt2_status_gtc,
                :mi_plan => plan2,
                :es_cell => es_cell
        object = Factory.create @factory,
                :mi_plan_id => plan2.id,
                :mi_attempt_colony_name => mi.colony_name
      end

      object.consortium_name = 'BaSH'
      object.production_centre_name = 'WTSI'
      object.save!
      assert_equal plan2, object.mi_plan
    end

  end # def self.public_tests

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

        assert_raise(ApplicationModel::BelongsToMiPlan::MissingMiPlanError) do
          object.save
        end
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
        mi = Factory.create(:mi_attempt2_status_gtc, :mi_plan => plan)
        pt = Factory.build :phenotype_attempt, :mi_plan => nil, :mi_attempt => mi
        pt.save!
        assert_equal plan, pt.mi_plan
      end
    end

    context 'for Public::MiAttempt' do
      subject { Public::MiAttempt.new }
      setup do
        @factory = :public_mi_attempt
      end
      public_tests

      context '#mi_plan and #mi_plan_id test:' do
        should 'force #mi_plan to be assigned and active if children are active' do
          unused_plan = Factory.create :mi_plan_with_production_centre, :gene => cbx1

          es_cell = Factory.create :es_cell, :gene => cbx1
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

        should 'allow #mi_plan to be inactive if children are inactive' do
          es_cell = Factory.create :es_cell, :gene => cbx1
          inactive_plan = Factory.create :mi_plan_with_production_centre, :gene => cbx1, :is_active => false
          assert_equal 'ina', inactive_plan.status.code

          Factory.create :public_mi_attempt, :es_cell_name => es_cell.name, :mi_plan_id => inactive_plan.id, :is_active => false
          assert_true inactive_plan.has_status? :asg
          assert_true inactive_plan.has_status? :ina
        end
      end

      context 'when creating with #consortium_name and #production_centre_name' do
        should 'find an MiPlan without a production centre if one with production centre could not be found and upgrade it' do
          plan = TestDummy.mi_plan 'BaSH', :gene => cbx1
          assert plan.production_centre.blank?

          mi = Factory.create :public_mi_attempt,
                  :mi_plan => nil,
                  :es_cell_name => Factory.create(:es_cell, :gene => cbx1).name,
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI'

          plan.reload
          assert_equal plan, mi.mi_plan
          assert_equal 'WTSI', plan.production_centre.name
        end
      end
    end # context 'for Public::MiAttempt'

    context 'for Public::PhenotypeAttempt' do
      subject { Public::PhenotypeAttempt.new }
      setup do
        @factory = :public_phenotype_attempt
      end
      public_tests
    end

  end
end
