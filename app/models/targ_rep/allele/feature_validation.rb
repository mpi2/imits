module TargRep::Allele::FeatureValidation
  extend ActiveSupport::Concern
  included do
    validates :homology_arm_start, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}
    validates :homology_arm_end, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}
    validates :loxp_start, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}
    validates :loxp_end, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}

    validates_format_of :floxed_start_exon,
      :with       => /^ENSMUSE\d+$/,
      :message    => "is not a valid Ensembl Exon ID",
      :allow_nil  => true

    validates_format_of :floxed_end_exon,
      :with       => /^ENSMUSE\d+$/,
      :message    => "is not a valid Ensembl Exon ID",
      :allow_nil  => true

    validate :has_right_features, :unless => :missing_fields?

  end

  protected

  def has_right_features
    return unless self.errors.empty?

    error_msg = "cannot be greater than %s position on this strand (#{strand})"

    case strand
      when '+'
        if homology_arm_start and cassette_start and cassette_end and homology_arm_end
          if homology_arm_start > cassette_start
            errors.add( :homology_arm_start, error_msg % "cassette start" )
          end

          if cassette_start > cassette_end
            errors.add( :cassette_start, error_msg % "cassette end" )
          end

        # With LoxP site
          if loxp_start and loxp_end
            if cassette_end > loxp_start
              errors.add( :cassette_end, error_msg % "loxp start" )
            end

            if loxp_start > loxp_end
              errors.add( :loxp_start, error_msg % "loxp end" )
            end

            if loxp_end > homology_arm_end
              errors.add( :loxp_end, error_msg % "homology arm end" )
            end

            # Without LoxP site
          else
            if cassette_end > homology_arm_end
              errors.add( :cassette_end, error_msg % "homology arm end" )
            end
          end
        end

      when '-'
        if homology_arm_start and cassette_start and cassette_end and homology_arm_end
          if homology_arm_start < cassette_start
            errors.add( :cassette_start, error_msg % "homology arm start" )
          end

          if cassette_start < cassette_end
            errors.add( :cassette_end, error_msg % "cassette start" )
          end

          # With LoxP site
          if loxp_start and loxp_end
            if cassette_end < loxp_start
              errors.add( :loxp_start, error_msg % "cassette end" )
            end

            if loxp_start < loxp_end
              errors.add( :loxp_end, error_msg % "loxp start" )
            end

            if loxp_end < homology_arm_end
              errors.add( :homology_arm_end, error_msg % "loxp end" )
            end

          # Without LoxP site
          else
            if cassette_end < homology_arm_end
              errors.add( :homology_arm_end, error_msg % "cassette end" )
            end
          end
        end
    end

    if mutation_type && mutation_type.no_loxp_site?
      unless loxp_start.nil? and loxp_end.nil?
        errors.add(:loxp_start, "has to be blank for this mutation method")
        errors.add(:loxp_end,   "has to be blank for this mutation method")
      end
    end
  end
end