module TargRep::Allele::CassetteValidation
  extend ActiveSupport::Concern
  included do

    validates :cassette_start, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}
    validates :cassette_end, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}
    validates :cassette,           :presence => true
    validates :cassette_type,      :presence => true

    validates_inclusion_of :cassette_type,
      :in => ['Promotorless','Promotor Driven'],
      :message => "Cassette Type can only be 'Promotorless' or 'Promotor Driven'"

    validate :has_correct_cassette_type

  end

  protected

  def has_correct_cassette_type
    known_cassettes = {
        'L1L2_6XOspnEnh_Bact_P'                        => 'Promotor Driven',
        'L1L2_Bact_P'                                  => 'Promotor Driven',
        'L1L2_Del_BactPneo_FFL'                        => 'Promotor Driven',
        'L1L2_GOHANU'                                  => 'Promotor Driven',
        'L1L2_hubi_P'                                  => 'Promotor Driven',
        'L1L2_Pgk_P'                                   => 'Promotor Driven',
        'L1L2_Pgk_PM'                                  => 'Promotor Driven',
        'PGK_EM7_PuDtk_bGHpA'                          => 'Promotor Driven',
        'pL1L2_PAT_B0'                                 => 'Promotor Driven',
        'pL1L2_PAT_B1'                                 => 'Promotor Driven',
        'pL1L2_PAT_B2'                                 => 'Promotor Driven',
        'TM-ZEN-UB1'                                   => 'Promotor Driven',
        'ZEN-Ub1'                                      => 'Promotor Driven',
        'ZEN-UB1.GB'                                   => 'Promotor Driven',
        'pL1L2_GT0_bsd_frt15_neo_barcode'              => 'Promotor Driven',
        'pL1L2_GT1_bsd_frt15_neo_barcode'              => 'Promotor Driven',
        'pL1L2_GT2_bsd_frt15_neo_barcode'              => 'Promotor Driven',
        'L1L2_gt0'                                     => 'Promotorless',
        'L1L2_gt1'                                     => 'Promotorless',
        'L1L2_gt2'                                     => 'Promotorless',
        'L1L2_gtk'                                     => 'Promotorless',
        'L1L2_NTARU-0'                                 => 'Promotorless',
        'L1L2_NTARU-1'                                 => 'Promotorless',
        'L1L2_NTARU-2'                                 => 'Promotorless',
        'L1L2_NTARU-K'                                 => 'Promotorless',
        'L1L2_st0'                                     => 'Promotorless',
        'L1L2_st1'                                     => 'Promotorless',
        'L1L2_st2'                                     => 'Promotorless',
        'Ifitm2_intron_L1L2_GT0_LF2A_LacZ_BetactP_neo' => 'Promotor Driven',
        'Ifitm2_intron_L1L2_GT1_LF2A_LacZ_BetactP_neo' => 'Promotor Driven',
        'Ifitm2_intron_L1L2_GT2_LF2A_LacZ_BetactP_neo' => 'Promotor Driven',
        'Ifitm2_intron_L1L2_GTk_LacZ_BetactP_neo'      => 'Promotor Driven',
        'Ifitm2_intron_L1L2_Bact_P              '      => 'Promotor Driven',
        'pL1L2_GT0_T2A_H2BCherry_Puro_delRsrll_NO_DTA' => 'Promotor Driven',
        'pL1L2_GT1_T2A_H2BCherry_Puro_delRsrll_NO_DTA' => 'Promotor Driven',
        'pL1L2_GT2_T2A_H2BCherry_Puro_delRsrll_NO_DTA' => 'Promotor Driven',
        'pL1L2_GT0_LF2A_H2BCherry_Puro'                => 'Promotor Driven',
        'pL1L2_GT1_LF2A_H2BCherry_Puro'                => 'Promotor Driven',
        'pL1L2_GT2_LF2A_H2BCherry_Puro'                => 'Promotor Driven',
        'pL1L2_GT0_T2A_iCre_KI_Puro'                   => 'Promotor Driven',
        'pL1L2_GT1_T2A_iCre_KI_Puro'                   => 'Promotor Driven',
        'pL1L2_GT2_T2A_iCre_KI_Puro'                   => 'Promotor Driven',
        'pL1L2_GT0_LF2A_nEGFPO_T2A_CreERT_puro'        => 'Promotorless',
        'pL1L2_GT1_LF2A_nEGFPO_T2A_CreERT_puro'        => 'Promotorless',
        'pL1L2_GT2_LF2A_nEGFPO_T2A_CreERT_puro'        => 'Promotorless',
        'pL1L2_GTK_nEGFPO_T2A_CreERT_puro'             => 'Promotorless',
        'pL1L2_frt_BetactP_neo_frt_lox'                => 'Promotor Driven',
        'pL1L2_frt15_BetactinBSD_frt14_neo_Rox'        => 'Promotor Driven',
        'L1L2_GT0_LF2A_LacZ_BetactP_neo'               => 'Promotor Driven',
        'L1L2_GT1_LF2A_LacZ_BetactP_neo'               => 'Promotor Driven',
        'L1L2_GT2_LF2A_LacZ_BetactP_neo'               => 'Promotor Driven',
        'L1L2_gt0_Del_LacZ'                            => 'Promotorless',
        'L1L2_gt1_Del_LacZ'                            => 'Promotorless',
        'L1L2_gt2_Del_LacZ'                            => 'Promotorless',
        'V5_Flag_biotin'                               => 'Promotorless',
    }

    unless known_cassettes[cassette].nil?
      if known_cassettes[cassette] != cassette_type
        errors.add( :cassette_type, "The cassette #{cassette} is a known #{known_cassettes[cassette]} cassette - please correct this field." )
      end
    end
  end
end