require 'test_helper'

class AuditRevisionFormatterTest < ActiveSupport::TestCase
  def default_audit_revision_formatter; @audit_revision_formatter ||= AuditRevisionFormatter.new(:model => MiPlan); end

  context 'AuditRevisionFormatter' do

    should 'get formatted hash from audit revision' do
      h = {
        'consortium_id' => [Consortium.find_by_name!('EUCOMM-EUMODIC').id, Consortium.find_by_name!('BaSH').id],
        'production_centre_id' => Centre.find_by_name!('WTSI').id,
        'status_id' => [MiPlan::Status[:con].id, MiPlan::Status[:asg].id],
        'total_male_chimeras' => [4, nil]
      }

      got = default_audit_revision_formatter.get_formatted_changes(h)

      expected = {
        'consortium' => ['EUCOMM-EUMODIC', 'BaSH'],
        'production_centre' => [nil, 'WTSI'],
        'status' => ['Conflict', 'Assigned'],
        'total_male_chimeras' => [4, nil]
      }

      assert_equal expected, got
    end

    should 'translate old fkey names into new ones' do
      expected = {
        'status' => [nil, 'Assigned'],
        'priority' => [nil, 'High']
      }

      audit = {
        'mi_plan_status_id' => MiPlan::Status[:asg].id,
        'mi_plan_priority_id' => MiPlan::Priority.find_by_name!('High').id
      }

      assert_equal expected,
              default_audit_revision_formatter.get_formatted_changes(audit)
    end

    should 'not include essentially blank changes' do
      expected = {
        'total_male_chimeras' => [4, nil]
      }

      audit = {
        'comments' => '',
        'total_male_chimeras' => [4, nil]
      }

      assert_equal expected,
              default_audit_revision_formatter.get_formatted_changes(audit)
    end

  end
end
