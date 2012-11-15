require 'test_helper'

class AuditDifferTest < ActiveSupport::TestCase
  def default_audit_differ; @audit_differ ||= AuditDiffer.new; end

  context 'AuditDiffer' do

    should 'translate keys that require no special processing' do
      assert_equal({'a_key' => 'a_value'},
        default_audit_differ.translate({'a_key' => 'a_value'}, :model => MiPlan))
    end

    [
      ['production_centre_id', Centre.find_by_name!('WTSI').id, 'production_centre', 'WTSI'],
      ['consortium_id', Consortium.find_by_name!('BaSH').id, 'consortium', 'BaSH']
    ].each do |fkey, fkey_id, translation, translated_value|
      should "translate common foreign key #{fkey} to readable value" do
        assert_equal({translation => translated_value},
          default_audit_differ.translate({fkey => fkey_id}, :model => MiPlan))
      end
    end

    should 'get formatted hash' do
      h = {
        'consortium_id' => Consortium.find_by_name!('BaSH').id,
        'production_centre_id' => Centre.find_by_name!('WTSI').id,
        'status_id' => MiPlan::Status[:asg].id,
        'total_male_chimeras' => 4
      }

      got = default_audit_differ.get_formatted_changes(h, :model => MiPlan)

      expected = {
        'consortium' => 'BaSH',
        'production_centre' => 'WTSI',
        'status' => 'Assigned',
        'total_male_chimeras' => 4
      }

      assert_equal expected, got
    end

    should 'Translate old fkey names into new ones' do
      expected = {
        'status' => 'Assigned',
        'priority' => 'High'
      }

      assert_equal expected, default_audit_differ.get_formatted_changes(
        {'mi_plan_status_id' => MiPlan::Status[:asg].id, 'mi_plan_priority_id' => MiPlan::Priority.find_by_name!('High').id},
        :model => MiPlan
      )
    end

  end
end
