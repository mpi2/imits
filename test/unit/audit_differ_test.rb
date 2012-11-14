require 'test_helper'

class AuditDifferTest < ActiveSupport::TestCase
  def audit_differ; @audit_differ ||= AuditDiffer.new; end

  context 'AuditDiffer' do

    context 'when comparing 2 hashes' do
      should 'show everything in the 2nd hash that has changed or was not present in the first hash' do
        h1 = {
          'first_name' => 'Fred',
          'surname' => 'Bloggs',
          'married?' => false,
          'income' => 20000
        }

        h2 = {
          'first_name' => 'Fred',
          'surname' => 'Bloggs',
          'married?' => true,
          'income' => 30000,
          'kids' => 2
        }

        diff = audit_differ.diff(h1, h2)

        assert_equal({'married?' => true, 'kids' => 2, 'income' => 30000}, diff)
      end

      [
        'status_id',
        'production_centre_id',
        'consortium_id',
        'sub_project_id',
        'priority_id'
      ].each do |field|
        should "look up readable value for #{field} in result"
      end
    end

  end
end
