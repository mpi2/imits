# encoding: utf-8

module Seeds
  def self.load(model_class, data)
    data.each do |data|
      data_id = data.delete(:id)
      thing = model_class.find_by_id(data_id)
      if thing
        thing.attributes = data
      else
        thing = model_class.new(data)
        thing.id = data_id
      end

      thing.save! if thing.changed?
    end
    update_db_sequence(model_class)
  end

  def self.update_db_sequence(model_class)
    model_class.connection.execute(<<-"SQL")
      select setval( '#{model_class.table_name}_id_seq',
                     (select id from #{model_class.table_name}
                                order by id desc
                                limit 1
                     )
                   );
    SQL
  end
end

Seeds.load Strain, [
  {:id=>1, :name=>"BALB/c", :mgi_strain_accession_id=>"MGI:2161072", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>2, :name=>"BALB/cAm", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>3, :name=>"BALB/cAnNCrl", :mgi_strain_accession_id=>"MGI:2683685", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>4, :name=>"BALB/cJ", :mgi_strain_accession_id=>"MGI:2159737", :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>5, :name=>"BALB/cN", :mgi_strain_accession_id=>"MGI:2161229", :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>6, :name=>"BALB/cWtsi;C57BL/6J-Tyr<c-Brd>", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>7, :name=>"C3HxBALB/c", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>8, :name=>"C57BL/6J", :mgi_strain_accession_id=>"MGI:3028467", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>9, :name=>"C57BL/6J Albino", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>10, :name=>"C57BL/6J-A<W-J>/J", :mgi_strain_accession_id=>"MGI:2160087", :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>11, :name=>"C57BL/6J-Tyr<c-2J>", :mgi_strain_accession_id=>"MGI:2164877", :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>12, :name=>"C57BL/6J-Tyr<c-2J>/J", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>13, :name=>"C57BL/6J-Tyr<c-Brd>", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>14, :name=>"C57BL/6J-Tyr<c-Brd>;C57BL/6JIco", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>15, :name=>"C57BL/6J-Tyr<c-Brd>;C57BL/6N", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>16, :name=>"C57BL/6J-Tyr<c-Brd>;Stock", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>17, :name=>"C57BL/6JcBrd/cBrd", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>18, :name=>"C57BL/6N", :mgi_strain_accession_id=>"MGI:2159965", :mgi_strain_name=>"", :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>19, :name=>"C57BL/6NCrl", :mgi_strain_accession_id=>"MGI:2683688", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>20, :name=>"C57BL6/NCrl", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>21, :name=>"C57Bl/6J Albino", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>22, :name=>"CD1", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>23, :name=>"FVB", :mgi_strain_accession_id=>"MGI:3609372", :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>24, :name=>"Stock", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>25, :name=>"Swiss Webster", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>false},
  {:id=>26, :name=>"b", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>27, :name=>"129P2", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>false},
  {:id=>28, :name=>"129P2/OlaHsd", :mgi_strain_accession_id=>"MGI:2164147", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>false},
  {:id=>29, :name=>"129S5/SvEvBrd/Wtsi", :mgi_strain_accession_id=>"MGI:5446372", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>false},
  {:id=>30, :name=>"129S5/SvEvBrd/Wtsi or C57BL/6J-Tyr<c-Brd>", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>31, :name=>"C57BL/6J-Tyr<c-Brd> or C57BL/6NTac/Den", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>32, :name=>"C57BL/6J-Tyr<c-Brd> or C57BL/6NTac/Den or CBA/Wtsi", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>33, :name=>"C57BL/6J-Tyr<c-Brd> or C57BL/6NTac/USA", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>34, :name=>"C57BL/6JIco", :mgi_strain_accession_id=>"MGI:2164221", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>35, :name=>"C57BL/6NTac", :mgi_strain_accession_id=>"MGI:2164831", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>36, :name=>"C57BL/6NTac/Den", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>false},
  {:id=>37, :name=>"C57BL/6NTac/Den or C57BL/6NTac/USA", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>38, :name=>"C57BL/6NTac/USA", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>39, :name=>"C57BL/6JIco;C57BL/6J-Tyr<c-Brd>", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>40, :name=>"Delete once confirmed its use", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>41, :name=>"c", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>42, :name=>"B6D2F1 x B6", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>43, :name=>"ICR/Jcl", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>44, :name=>"C57BL/6Dnk", :mgi_strain_accession_id=>"MGI:4830588", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>false},
  {:id=>45, :name=>"C57BL/6Brd-Tyr<c-Brd>;Stock", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>46, :name=>"C57BL/6Brd-Tyr<c-Brd>;C57BL/6JIco", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>47, :name=>"C57BL/6Dnk or C57BL/6NTac", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>48, :name=>"C57BL/6Brd-Tyr<c-Brd> or C57BL/6NTac", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>49, :name=>"C57BL/6Brd-Tyr<c-Brd>", :mgi_strain_accession_id=>"MGI:3692927", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>50, :name=>"C57BL/6Brd-Tyr<c-Brd> or C57BL/6Dnk or CBA/Wtsi", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>51, :name=>"C57BL/6Brd-Tyr<c-Brd> or C57BL/6Dnk", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>52, :name=>"129S5/SvEvBrd/Wtsi or C57BL/6Brd-Tyr<c-Brd>", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>53, :name=>"C57BL/6Brd-Tyr<c-Brd>;C57BL/6N", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>54, :name=>"BALB/cWtsi;C57BL/6Brd-Tyr<c-Brd>", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>55, :name=>"C57BL/6Dnk or C57BL/6JIco or C57BL/6NTac", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>56, :name=>"C57BL/6N;C57BL/6NTac", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>57, :name=>"B6N-Tyrc/BrdCrCrl", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>58, :name=>"B6N-Albino N9", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>59, :name=>"ICR (CD-1)", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>60, :name=>"C57BL6/6NHsd", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>61, :name=>"C57BL/6NJ", :mgi_strain_accession_id=>"MGI:3056279", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>63, :name=>"(B6;129-Gt(ROSA)26Sor<tm1(DTA)Mrc>/J x B6.FVB-Tg(Ddx4-cre)1Dcas>/J)F1/MvwJ", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>65, :name=>"B6Brd;B6Dnk;B6N-Tyr<c-Brd>", :mgi_strain_accession_id=>"MGI:5446362", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>66, :name=>"C57BL/6Brd-Tyr<c-Brd>;C57BL/6N;C57BL/6NTac", :mgi_strain_accession_id=>"", :mgi_strain_name=>"", :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>68, :name=>"C57BL/6N;129S5/SvEvBrdWtsi", :mgi_strain_accession_id=>"", :mgi_strain_name=>"C57BL/6N;129S5/SvEvBrdWtsi", :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>69, :name=>"C57BL/6JOlaHsd", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},
  {:id=>70, :name=>"C57BL/6JIco;C57BL/6Brd-Tyr<c-Brd>", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>false},
  {:id=>71, :name=>"BALB/cOlaHsdWtsi;C57BL/6Brd-Tyr<c-Brd>", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>72, :name=>"Tg(CAG-EGFP)B5Nagy", :mgi_strain_accession_id=>"", :mgi_strain_name=>"", :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>73, :name=>"Tg(CAG-EGFP)B5Nagy or CD1", :mgi_strain_accession_id=>"", :mgi_strain_name=>"", :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>74, :name=>"Tg(CAG-EGFP)B5Nagy or C57Bl/6J", :mgi_strain_accession_id=>"", :mgi_strain_name=>"", :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>75, :name=>"Tg(CAG-EGFP)B5Nagy or C57BL/6J Albino", :mgi_strain_accession_id=>"", :mgi_strain_name=>"", :background_strain=>false, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>76, :name=>"129S5/SvEvBrd/Wtsi;129S7/SvEvBrd/Wtsi", :mgi_strain_accession_id=>"", :mgi_strain_name=>"", :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>77, :name=>"C57BL/6N;C57BL/6Dnk", :mgi_strain_accession_id=>"", :mgi_strain_name=>"", :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>78, :name=>"C57BL/6N;C57BL/6Dnk;C57BL/6NTac", :mgi_strain_accession_id=>"", :mgi_strain_name=>"", :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>79, :name=>"129P2/OlaHsd;CBA/Ca", :mgi_strain_accession_id=>"", :mgi_strain_name=>"", :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>80, :name=>"C57BL/6JTyr;C57BL/6N", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>81, :name=>"C57BL/6", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>82, :name=>"C57BL/6JTyr;C57BL/6JIco", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>84, :name=>"129S8/SvEv-Gpi1<c>/NimrH", :mgi_strain_accession_id=>"MGI:4831136", :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>85, :name=>"Mettl3", :mgi_strain_accession_id=>"", :mgi_strain_name=>"", :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>86, :name=>"(C57BL/6J x CBA/Ca)F1", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>87, :name=>"C57BL/6NJcl", :mgi_strain_accession_id=>"MGI:2160139", :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>false, :blast_strain=>true},
  {:id=>88, :name=>"STOCK Grxcr1<tde>", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>90, :name=>"129S9/SvEvH", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>91, :name=>"C3HeB/FeJ", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>92, :name=>"129/Sv_C57BL/6", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>93, :name=>"129SV", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>94, :name=>"129/SvPas", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>95, :name=>"C3H/NHG", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>96, :name=>"C57BL/6NTacDen", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>97, :name=>"BALB/cByJ", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>98, :name=>"C3H/HeH", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>99, :name=>"FVB/NJ", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>100, :name=>"B6J.129S2", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>101, :name=>"B6J.129S2.B6N", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>102, :name=>"B6N.B6J.129S2", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>103, :name=>"B6N.129S2.B6J", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>104, :name=>"Balb/c.129S2", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>105, :name=>"B6J.B6N", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>106, :name=>"129/SvEv", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>107, :name=>"CBA/Ca;129P2", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>108, :name=>"C57BL/6JTyr;129S5", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>109, :name=>"C57BL/6JIco;C57BL/6JTyr;129S5", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>110, :name=>"STOCK Tmc1<dn>", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>111, :name=>"C57BL/6JIco;C57BL/10", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>112, :name=>"C57BL/6JTyr;C57BL/6;129S5", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>113, :name=>"129S5;129P2", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>114, :name=>"STOCK Cdh23<v>", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>115, :name=>"STOCK Hmx3<hx>", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false},
  {:id=>116, :name=>"lmna", :mgi_strain_accession_id=>"", :mgi_strain_name=>nil, :background_strain=>false, :test_cross_strain=>false, :blast_strain=>false}
]

Seeds.load MiPlan::Status, [
  {:code => 'asg-esp',  :order_by => 110,  :id => 8,  :name => 'Assigned - ES Cell QC In Progress', :description => 'Assigned - The ES cells are currently being QCed by the production centre'},
  {:code => 'asg-esc',  :order_by => 100,  :id => 9,  :name => 'Assigned - ES Cell QC Complete', :description => 'Assigned - ES cells have passed the QC phase and are ready for micro-injection'},
  {:code => 'abt-esf',  :order_by => 90,   :id => 10, :name => 'Aborted - ES Cell QC Failed', :description => 'Aborted - ES cells have failed the QC phase, and micro-injection cannot proceed'},
  {:code => 'asg',      :order_by => 80,   :id => 1,  :name => 'Assigned', :description => 'Assigned - A single consortium has expressed an interest in injecting this gene'},
  {:code => 'ins-gtc',  :order_by => 70,   :id => 4,  :name => 'Inspect - GLT Mouse', :description => 'Inspect - A GLT mouse is already recorded in iMits'},
  {:code => 'ins-mip',  :order_by => 60,   :id => 5,  :name => 'Inspect - MI Attempt', :description => 'Inspect - An active micro-injection attempt is already in progress'},
  {:code => 'ins-con',  :order_by => 50,   :id => 6,  :name => 'Inspect - Conflict', :description => 'Inspect - This gene is already assigned in another planned micro-injection'},
  {:code => 'con',      :order_by => 40,   :id => 3,  :name => 'Conflict', :description => 'Conflict - More than one consortium has expressed an interest in micro-injecting this gene'},
  {:code => 'int',      :order_by => 30,   :id => 2,  :name => 'Interest', :description => 'Interest - A consortium has expressed an interest to micro-inject this gene'},
  {:code => 'ina',      :order_by => 20,   :id => 7,  :name => 'Inactive', :description => 'Inactive - A consortium/production centre has failed micro-injections on this gene dated over 6 months ago - they have given up'},
  {:code => 'wit',      :order_by => 10,   :id => 11, :name => 'Withdrawn', :description => 'Withdrawn - Interest in micro-injecting this gene was withdrawn by the parties involved'},
  {:code => 'asg-phen', :order_by => 9,    :id => 12, :name => 'Assigned for phenotyping', :description => 'Assigned - A consortium/Centre has indicated their intention to only phenotype this gene'},
  {:code => 'ins-phen', :order_by => 8,    :id => 13, :name => 'Inspect - Phenotype Conflict', :description => 'Inspect - A phenotype attempt has already been recorded in iMITS'},
  {:code => 'asg-es',   :order_by => 7,    :id => 14, :name => 'Assigned for ES Cell QC', :description => 'Assigned - A consortium/Centre has indicated their intention to only QC ES Cells'}
]

Seeds.load MiAttempt::Status, [
  {:id=>1, :name=>"Micro-injection in progress", :order_by=>220, :code=>"mip"},
  {:id=>2, :name=>"Genotype confirmed", :order_by=>240, :code=>"gtc"},
  {:id=>3, :name=>"Micro-injection aborted", :order_by=>210, :code=>"abt"},
  {:id=>4, :name=>"Chimeras obtained", :order_by=>230, :code=>"chr"},
  {:id=>5, :name=>"Founder obtained", :order_by=>231, :code=>"fod"},
  {:id=>6, :name=>"Chimeras/Founder obtained", :order_by=>229, :code=>"cof"}
]


Seeds.load MouseAlleleMod::Status, [
  {:id=>1, :name=>"Phenotype Attempt Registered", :order_by=>420, :code=>"par"},
  {:id=>2, :name=>"Mouse Allele Modification Registered", :order_by=>410, :code=>"mpr"},
  {:id=>3, :name=>"Rederivation Started", :order_by=>430, :code=>"res"},
  {:id=>4, :name=>"Rederivation Complete", :order_by=>440, :code=>"rec"},
  {:id=>5, :name=>"Cre Excision Started", :order_by=>450, :code=>"ces"},
  {:id=>6, :name=>"Cre Excision Complete", :order_by=>460, :code=>"cec"},
  {:id=>7, :name=>"Mouse Allele Modification Aborted", :order_by=>211, :code=>"abt"}
]


Seeds.load PhenotypingProduction::Status, [
  {:id=>1, :name=>"Phenotype Attempt Registered", :order_by=>420, :code=>"mpr"},
  {:id=>2, :name=>"Phenotyping Production Registered", :order_by=>411, :code=>"ppr"},
  {:id=>3, :name=>"Phenotyping Started", :order_by=>530, :code=>"pds"},
  {:id=>4, :name=>"Phenotyping Complete", :order_by=>540, :code=>"pdc"},
  {:id=>5, :name=>"Phenotype Production Aborted", :order_by=>212, :code=>"abt"},
  {:id=>6, :name=>"Rederivation Started", :order_by=>430, :code=>"res"},
  {:id=>7, :name=>"Rederivation Complete", :order_by=>440, :code=>"rec"}
]


Seeds.load PhenotypingProduction::LateAdultStatus, [
  {:id=>1, :name=>"Not Registered For Late Adult Phenotyping", :order_by=>"200", :code=>nil},
  {:id=>2, :name=>"Registered for Late Adult Phenotyping Production", :order_by=>"610", :code=>nil},
  {:id=>3, :name=>"Late Adult Phenotyping Started", :order_by=>"630", :code=>"pdlas"},
  {:id=>4, :name=>"Late Adult Phenotyping Complete", :order_by=>"640", :code=>"pdlac"},
  {:id=>5, :name=>"Late Adult Phenotype Production Aborted", :order_by=>"213", :code=>nil}
]


Seeds.load DepositedMaterial, [
  {:id => 1, :name => 'Frozen embryos'},
  {:id => 2, :name => 'Live mice'},
  {:id => 3, :name => 'Frozen sperm'}
]


Seeds.load ReagentName, [
  {:id=>1, :name=>"Ligase IV", :description=>"NHEJ Inhibitor"}
  {:id=>2, :name=>"Xrcc5", :description=>"NHEJ Inhibitor"}
]



Seeds.load Consortium, [
  {:id=>1, :name=>"EUCOMM-EUMODIC", :funding=>"EUCOMM / EUMODIC", :participants=>nil, :contact=>nil},
  {:id=>2, :name=>"UCD-KOMP", :funding=>"KOMP", :participants=>"Davis", :contact=>nil},
  {:id=>3, :name=>"MGP-KOMP", :funding=>"KOMP / Wellcome Trust", :participants=>"Mouse Genetics Project, WTSI", :contact=>nil},
  {:id=>4, :name=>"BaSH", :funding=>"KOMP2", :participants=>"Baylor, Sanger, Harwell", :contact=>nil},
  {:id=>5, :name=>"DTCC", :funding=>"KOMP2", :participants=>"Davis-Toronto-Charles River-CHORI", :contact=>nil},
  {:id=>6, :name=>"Helmholtz GMC", :funding=>"Infrafrontier/BMBF", :participants=>"Helmholtz Muenchen", :contact=>nil},
  {:id=>7, :name=>"JAX", :funding=>"KOMP2", :participants=>"The Jackson Laboratory", :contact=>nil},
  {:id=>8, :name=>"MARC", :funding=>"China", :participants=>"Model Animal Research Centre, Nanjing University", :contact=>nil},
  {:id=>9, :name=>"MGP", :funding=>"Wellcome Trust", :participants=>"Mouse Genetics Project, WTSI", :contact=>nil},
  {:id=>10, :name=>"Monterotondo", :funding=>"European Union", :participants=>"Monterotondo Institute for Cell Biology (CNR)", :contact=>nil},
  {:id=>11, :name=>"MRC", :funding=>"MRC", :participants=>"MRC - Harwell", :contact=>nil},
  {:id=>12, :name=>"NorCOMM2", :funding=>"Genome Canada", :participants=>"NorCOMM2", :contact=>nil},
  {:id=>13, :name=>"Phenomin", :funding=>"Phenomin", :participants=>"ICS", :contact=>nil},
  {:id=>14, :name=>"RIKEN BRC", :funding=>"Japanese government", :participants=>"RIKEN BRC", :contact=>nil},
  {:id=>15, :name=>"DTCC-Legacy", :funding=>"KOMP312/KOMP", :participants=>"Davis-CHORI", :contact=>nil},
  {:id=>16, :name=>"MGP Legacy", :funding=>"Wellcome Trust", :participants=>"Mouse Genetics Project, WTSI", :contact=>nil},
  {:id=>17, :name=>"EUCOMMToolsCre", :funding=>"EU", :participants=>nil, :contact=>nil},
  {:id=>18, :name=>"Monterotondo R&D", :funding=>"European Union", :participants=>"Monterotondo Institute for Cell Biology (CNR)", :contact=>nil},
  {:id=>19, :name=>"Infrafrontier-I3", :funding=>"EU", :participants=>nil, :contact=>nil},
  {:id=>20, :name=>"KMPC", :funding=>"Korean Government", :participants=>"KMPC", :contact=>nil},
  {:id=>21, :name=>"NarLabs", :funding=>nil, :participants=>nil, :contact=>"Genie Chin"},
  {:id=>22, :name=>"CAM-SU GRC", :funding=>"China", :participants=>nil, :contact=>nil},
  {:id=>23, :name=>"CCP", :funding=>"Czech Centre for Phenogenomics", :participants=>nil, :contact=>nil},
  {:id=>24, :name=>"NorCOMM", :funding=>"Genome Canada", :participants=>"TCP", :contact=>nil},
  {:id=>25, :name=>"GENCODYS", :funding=>"GENCODYS", :participants=>nil, :contact=>nil}
]

Seeds.load Centre, [
  {:id=>8, :name=>"APN", :code=>"Apb", :superscript=>nil},
  {:id=>9, :name=>"BCM", :code=>"Bay", :superscript=>nil},
  {:id=>38, :name=>"CAM-SU GRC", :code=>nil, :superscript=>nil},
  {:id=>37, :name=>"CDTA", :code=>nil, :superscript=>nil},
  {:id=>24, :name=>"CIPHE", :code=>"Ciphe", :superscript=>nil},
  {:id=>7, :name=>"CNB", :code=>"Cnbc", :superscript=>nil},
  {:id=>18, :name=>"CNRS", :code=>"Cthe", :superscript=>nil},
  {:id=>39, :name=>"CRL", :code=>"Crl", :superscript=>nil},
  {:id=>41, :name=>"EBI - Informatics Support", :code=>nil, :superscript=>nil},
  {:id=>23, :name=>"EMBL-Rome", :code=>"Embrp", :superscript=>nil},
  {:id=>26, :name=>"Fleming", :code=>"Flmg", :superscript=>nil},
  {:id=>3, :name=>"Harwell", :code=>"H", :superscript=>nil},
  {:id=>6, :name=>"HMGU", :code=>"Hmgu", :superscript=>nil},
  {:id=>2, :name=>"ICS", :code=>"Ics", :superscript=>nil},
  {:id=>17, :name=>"IMG", :code=>"Img", :superscript=>nil},
  {:id=>14, :name=>"JAX", :code=>"J", :superscript=>nil},
  {:id=>33, :name=>"KMPC", :code=>"KMPC", :superscript=>nil},
  {:id=>35, :name=>"KOMP Repo", :code=>"KOMP Repo", :superscript=>nil},
  {:id=>19, :name=>"KRIBB", :code=>"Krb", :superscript=>nil},
  {:id=>15, :name=>"MARC", :code=>"Nju", :superscript=>nil},
  {:id=>34, :name=>"Monash", :code=>"Marp", :superscript=>nil},
  {:id=>4, :name=>"Monterotondo", :code=>"Cnrm", :superscript=>nil},
  {:id=>25, :name=>"Monterotondo R&D", :code=>"Cnrm", :superscript=>nil},
  {:id=>36, :name=>"NARLabs", :code=>"Narl", :superscript=>nil},
  {:id=>40, :name=>"NIH", :code=>nil, :superscript=>nil},
  {:id=>10, :name=>"Oulu", :code=>"Oulu", :superscript=>nil},
  {:id=>12, :name=>"RIKEN BRC", :code=>"Rbrc", :superscript=>nil},
  {:id=>32, :name=>"SEAT", :code=>"SEAT", :superscript=>nil},
  {:id=>11, :name=>"TCP", :code=>"Tcp", :superscript=>nil},
  {:id=>5, :name=>"UCD", :code=>"Mbp", :superscript=>nil},
  {:id=>22, :name=>"UCL", :code=>"Ucl", :superscript=>nil},
  {:id=>20, :name=>"UniMiss", :code=>"UniMiss", :superscript=>nil},
  {:id=>21, :name=>"UNorCar", :code=>"UNorCar", :superscript=>nil},
  {:id=>16, :name=>"VETMEDUNI", :code=>"VETMEDUNI", :superscript=>nil},
  {:id=>1, :name=>"WTSI", :code=>"Wtsi", :superscript=>nil}
]



Seeds.load MiPlan::Priority, [
  {:id => 1, :name => 'High', :description => 'Estimated injection in the next 0-4 months'},
  {:id => 2, :name => 'Medium', :description => 'Estimated injection in the next 5-8 months'},
  {:id => 3, :name => 'Low', :description => 'Estimated injection in the next 9-12 months'}
]


Seeds.load DeleterStrain, [
  {:id=>1, :name=>"MGI:2176052: Tg(Zp3-cre)3Mrt", :excision_type=>nil},
  {:id=>2, :name=>"MGI:3046308: Hprt<tm1(CMV-cre)Brd>", :excision_type=>nil},
  {:id=>3, :name=>"B6N.Cg-Tg(Sox2-cre)1Amc/J", :excision_type=>nil},
  {:id=>4, :name=>"Gt(ROSA)26Sor<tm16(cre)Arte>", :excision_type=>nil},
  {:id=>5, :name=>"C57BL/6NTac-Tg(ACTB-cre)3Mrt/H", :excision_type=>nil},
  {:id=>6, :name=>"Gt(ROSA)26Sortm1(ACTB-cre,-EGFP)Ics (MGI:5285392)", :excision_type=>nil},
  {:id=>7, :name=>"C57BL/6N-Gt(ROSA)26Sor<tm1(FLP1)Dym>", :excision_type=>nil},
  {:id=>8, :name=>"MGI:4453967: Tg(CAG-Flpo)1Afst", :excision_type=>nil},
  {:id=>9, :name=>"MGI:2448985: B6.Cg-Tg(ACTFLPe)9205Dym/H", :excision_type=>nil},
  {:id=>10, :name=>"Hprt<tm1(CMV-cre)Brd> and C57Bl/6N-Gt(ROSA)26Sor<tm1(FLP1)Dym>", :excision_type=>nil},
  {:id=>11, :name=>"Gt(Rosa)26Sor(CAG-Flpo,-EYFP)Ics", :excision_type=>"flp"},
  {:id=>12, :name=>"C57BL/6NTac-Gt(ROSA)26Sortm1(DRE)Wtsi/Wtsi", :excision_type=>"dre"}
]

Seeds.load MiPlan::EsQcComment, [
  {:id => 1, :name => 'No assay available'},
  {:id => 2, :name => 'All valid available clones failed'},
  {:id => 3, :name => 'Enough clones failed'}
]


Seeds.load TargRep::CentrePipeline, [
  {:id=>1, :name=>"KOMP", :centres=>["KOMP-CSD", "KOMP-Regeneron"]},
  {:id=>2, :name=>"EUMMCR", :centres=>["EUCOMM", "EUCOMMTools", "EUCOMMToolsCre"]},
  {:id=>3, :name=>"NorCOMM2LS", :centres=>["NorCOMM"]},
  {:id=>4, :name=>"WTSI", :centres=>["WTSI"]},
  {:id=>5, :name=>"CMMR", :centres=>["NorCOMM"]}
]


Seeds.load TargRep::MutationMethod, [
  {:id=>1, :name=>"Targeted Mutation", :code=>"tgm", :allele_prefix=>"tm"},
  {:id=>2, :name=>"Recombination Mediated Cassette Exchange", :code=>"rmce", :allele_prefix=>"tm"},
  {:id=>3, :name=>"Gene Trap", :code=>"gt", :allele_prefix=>"gt"}
]


Seeds.load TargRep::MutationSubtype, [
  {:id=>1, :name=>"Domain Disruption", :code=>"dmd"},
  {:id=>2, :name=>"Frameshift", :code=>"fms"},
  {:id=>3, :name=>"Artificial Intron", :code=>"afi"},
  {:id=>4, :name=>"Hprt", :code=>"hpt"},
  {:id=>5, :name=>"Rosa26", :code=>"rsa"},
  {:id=>6, :name=>"Point Mutation", :code=>"pnt"}
]


Seeds.load TargRep::MutationType, [
  {:id=>1, :name=>"Conditional Ready", :code=>"crd", :allele_code=>"a"},
  {:id=>2, :name=>"Deletion", :code=>"del", :allele_code=>"''"},
  {:id=>3, :name=>"Targeted Non Conditional", :code=>"tnc", :allele_code=>"e"},
  {:id=>4, :name=>"Cre Knock In", :code=>"cki", :allele_code=>"''"},
  {:id=>5, :name=>"Cre BAC", :code=>"cbc", :allele_code=>nil},
  {:id=>6, :name=>"Insertion", :code=>"ins", :allele_code=>nil},
  {:id=>7, :name=>"Gene Trap", :code=>"gt", :allele_code=>nil},
  {:id=>8, :name=>"Point Mutation", :code=>"pnt", :allele_code=>nil}
]


Seeds.load TargRep::Pipeline, [
  {:id=>1, :name=>"KOMP-CSD", :description=>nil, :legacy_id=>6, :report_to_public=>true, :gene_trap=>false},
  {:id=>2, :name=>"KOMP-Regeneron", :description=>nil, :legacy_id=>7, :report_to_public=>true, :gene_trap=>false},
  {:id=>3, :name=>"NorCOMM", :description=>nil, :legacy_id=>9, :report_to_public=>true, :gene_trap=>false},
  {:id=>4, :name=>"EUCOMM", :description=>"EUCOMM consortia", :legacy_id=>1, :report_to_public=>true, :gene_trap=>false},
  {:id=>5, :name=>"mirKO", :description=>"WTSI MircroRNA Knockouts", :legacy_id=>4, :report_to_public=>true, :gene_trap=>false},
  {:id=>6, :name=>"Sanger MGP", :description=>nil, :legacy_id=>8, :report_to_public=>true, :gene_trap=>false},
  {:id=>7, :name=>"EUCOMMTools", :description=>nil, :legacy_id=>10, :report_to_public=>true, :gene_trap=>false},
  {:id=>8, :name=>"EUCOMMToolsCre", :description=>nil, :legacy_id=>11, :report_to_public=>true, :gene_trap=>false},
  {:id=>9, :name=>"EUCOMM GT", :description=>nil, :legacy_id=>nil, :report_to_public=>false, :gene_trap=>true},
  {:id=>10, :name=>"SANGER_FACULTY", :description=>"Faculty lines internal to WTSI", :legacy_id=>3, :report_to_public=>true, :gene_trap=>false},
  {:id=>11, :name=>"TIGM", :description=>"TIGM Gene trap resource", :legacy_id=>5, :report_to_public=>false, :gene_trap=>true},
  {:id=>12, :name=>"NARLabs", :description=>"National Applied Research Laboratories", :legacy_id=>nil, :report_to_public=>true, :gene_trap=>false},
  {:id=>13, :name=>"GENCODYS", :description=>nil, :legacy_id=>nil, :report_to_public=>true, :gene_trap=>false}
]
