module Arel

  module Visitors
    class ToSql
      def visit_Arel_Nodes_CaseInsensitiveIn(o)
        "UPPER(#{visit o.left}) IN (#{visit o.right})"
      end

      def visit_Sequel_SQL_AliasedExpression(o)
        "#{o.expression} AS #{o.aliaz}"
      end
    end

    class DepthFirst
      alias :visit_Arel_Nodes_CaseInsensitiveIn                 :binary
    end
  end

  module Nodes
    class CaseInsensitiveIn < Arel::Nodes::In; end
  end

  module Predications
    def ci_in(other)
      if other.kind_of? Array
        upcased_other = other.map {|i| i.try(:upcase)}
        Nodes::CaseInsensitiveIn.new(self, upcased_other)
      else
        raise "Unsupported operand for ci_in (#{other.class.name})"
      end
    end
  end

end
