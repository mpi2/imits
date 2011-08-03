module Arel

  module Visitors
    class ToSql

      def visit_Arel_Nodes_CaseInsensitiveEquality(o)
        right = o.right

        if right.nil?
          "#{visit o.left} IS NULL"
        else
          "UPPER(#{visit o.left}) = UPPER(#{visit right})"
        end
      end

    end
  end

  module Nodes
    class CaseInsensitiveEquality < Arel::Nodes::Equality
    end
  end

  module Predications
    def ci_eq(other)
      Nodes::CaseInsensitiveEquality.new self, other
    end
  end

end
