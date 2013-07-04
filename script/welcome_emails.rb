#!/usr/bin/env ruby

require 'pp'

raise "#### Not for use in Production!" if Rails.env.production?

set_1 = %W{
  Gm10088
  Gm14680
  Nat3
  4930529M08Rik
  4932438H23Rik
  Adprhl2
  Akap14
  Arhgap22
  Atp1a3
  Atxn7l2
  Bai2
  Ccar1
  Ccdc47
  Ccdc89
  Cdyl2
  Chd4
  Clcn4-2
  Coq2
  D430042O09Rik
  Dars
  Dyrk1a
  Efcab5
  Fat2
  Frmpd4
  Gars
  Gemin4
  Gemin5
  Gprin1
  Hk1
  Hk3
  Hn1
  Hnrnpk
  Kcna1
  Kctd19
  Kif4
  Lama2
  Lamc2
  Lmod3
  Myh11
  Myh13
  Myh8
  Nat2
  Nid2
  Nkx2-5
  Notch2
  Obscn
  Pik3cd
  Prune
  Ptpn14
  Rbmxl2
  Rhobtb2
  Rnaseh2b
  Scnm1
  Slc13a5
  Smc3
  Sms
  Snap29
  Srpk3
  Stim1
  Susd4
  Syne1
  Ttr
  Ube2v2
  Wasf2
  Wscd1
  Xrn1
  Zfhx3
  Zfp286
  Zfp810
}

set_2 = %W{
  Atad2
  Baz1b
  Baz2a
  Baz2b
  Brd1
  Brd2
  Brd3
  Brd7
  Brd9
  Brdt
  Brpf3
  Cecr2
  Crebbp
  Ezh2
  Kat2b
  Kdm2a
  Kdm3a
  Kdm4a
  Kdm4b
  Kdm4c
  Kdm4d
  Kdm5a
  Kdm5c
  Kdm6b
  L3mbtl1
  L3mbtl2
  L3mbtl3
  L3mbtl4
  Mbtd1
  Mecom
  Mll1
  Mll2
  Mll3
  Mll5
  Pbrm1
  Phip
  Prdm10
  Prdm11
  Prdm12
  Prdm13
  Prdm14
  Prdm15
  Prdm16
  Prdm4
  Prdm5
  Prdm6
  Prdm8
  Prdm9
  Prmt1
  Prmt3
  Prmt5
  Scmh1
  Scml2
  Setd2
  Setd7
  Setd8
  Setdb1
  Sfmbt1
  Sfmbt2
  Smarca4
  Smyd2
  Smyd3
  Spin1
  Suv39h1
  Suv39h2
  Suv420h1
  Suv420h2
  Trim24
  Uhrf1
  Wdr5
  Whsc1
  2410016O06Rik
  Aire
  Arid4a
  Ash1l
  Atad2b
  Baz1a
  Bptf
  Brd4
  Brpf1
  Brwd1
  Brwd3
  Cbx1
  Cbx2
  Cbx3
  Cbx4
  Cbx5
  Cbx6
  Cbx7
  Cbx8
  Ccdc101
  Cdyl2
  Chd1
  Chd2
  Chd3
  Chd4
  Chd5
  Chd6
  Chd7
  Chd9
  Cxxc1
  Dido1
  Dnmt3a
  Dnmt3b
  Dot1l
  Dpf2
  Dpf3
  Ehmt1
  Ehmt2
  Ep300
  Fxr1
  Fxr2
  Hat1
  Hdgfl1
  Hdgfrp2
  Jhdm1d
  Kat2a
  Kat2a
  Kat5
  Kat6a
  Kat6b
  Kat7
  Kat8
  Kdm3b
  Kdm5b
  Kdm5d
  Kdm6a
  Kdm8
  Mina
  Mphosph8
  Msh6
  Msl3
  Mtf2
  Mum1
  Nsd1
  Phf1
  Phf12
  Phf13
  Phf17
  Phf19
  Phf20
  Phf20l1
  Phf21b
  Phf6
  Phf8
  Prdm1
  Prmt6
  Prmt8
  Psip1
  Pygo2
  Rag2
  Rnf17
  Rsf1
  Setd3
  Setd6
  Setdb2
  Smarca2
  Smarcc1
  Smarcc2
  Smn1
  Smndc1
  Smyd1
  Smyd5
  Snd1
  Sp100
  Sp140
  Stk31
  Taf1
  Tdrd1
  Tdrd3
  Tdrd7
  Tdrd9
  Tdrkh
  Trim28
  Trim66
  Trp53bp1
  Uhrf2
  Whsc1l1
  Zcwpw1
  Zgpat
  Akap1
  Asxl1
  Asxl2
  Asxl3
  Dpf1
  Ezh1
  Fmr1
  G2e3
  Glyr1
  Hdgf
  Hdgfrp3
  Ing1
  Ing2
  Ing3
  Ing4
  Ing5
  Ints12
  Jarid2
  Jmjd1c
  Kdm1a
  Kdm1b
  Kdm2b
  Lbr
  Mbd5
  Mettl21d
  Mllt10
  Mllt6
  Phf10
  Phf11c
  Phf14
  Phf15
  Phf16
  Phf2
  Phf21a
  Phf23
  Phf3
  Phf5a
  Phf7
  Phrf1
  Pias1
  Pias2
  Polr1b
  Prmt2
  Prmt7
  Pwwp2b
  Pygo1
  Rai1
  Rph3a
  Setd1a
  Setd1b
  Setd4
  Setd5
  Shprh
  Smyd4
  Taf3
  Tcf19
  Tcf20
  Tdrd12
  Tdrd5
  Tdrd6
  Ubr7
  Uty
  Zar1
  Zcwpw2
  Zfp451
  1110018G07Rik
  Cyld
  Gm15800
  Hace1
  Hectd1
  Hectd2
  Hectd3
  Hecw1
  Hecw2
  Herc1
  Herc2
  Herc3
  Herc4
  Herc6
  Huwe1
  Itch
  Nedd4
  Nedd4l
  Pan2
  Smurf1
  Smurf2
  Trip12
  Ube3a
  Ube3b
  Ube3c
  Ubr5
  Usp1
  Usp10
  Usp11
  Usp12
  Usp13
  Usp14
  Usp15
  Usp16
  Usp17lc
  Usp18
  Usp19
  Usp2
  Usp20
  Usp21
  Usp22
  Usp24
  Usp25
  Usp26
  Usp27x
  Usp28
  Usp29
  Usp3
  Usp30
  Usp31
  Usp32
  Usp33
  Usp34
  Usp35
  Usp36
  Usp37
  Usp38
  Usp39
  Usp4
  Usp40
  Usp42
  Usp43
  Usp44
  Usp45
  Usp46
  Usp47
  Usp48
  Usp49
  Usp5
  Usp50
  Usp51
  Usp53
  Usp54
  Usp7
  Usp8
  Usp9x
  Usp9y
  Uspl1
  Wwp1
  Wwp2
}

puts "#### set_1 counts #{set_1.size}/#{set_1.sort.uniq.size}"
puts "#### set_2 counts #{set_2.size}/#{set_2.sort.uniq.size}"

sets = set_1 + set_2

def build_welcome_email(contact_email, genes)
  ApplicationModel.transaction do

    genes.sort.uniq.each do |g|
      gene = Gene.find_by_marker_symbol g
      next if ! gene

      contact = Contact.find(:first, :conditions => [ "lower(email) = ?", contact_email.downcase ])
      gene = Gene.find(:first, :conditions => [ "lower(mgi_accession_id) = ?", gene.mgi_accession_id.downcase ] )

      nots = nil
      nots = Notification.where("contact_id = #{contact.id} and gene_id = #{gene.id}") if contact && gene
      puts "#### already registered email: #{contact.email} - gene: #{gene.mgi_accession_id}" if nots && nots.size > 0
      next if nots && nots.size > 0

      notification = Notification.new(:contact_email => contact_email, :gene_mgi_accession_id => gene.mgi_accession_id)
      notification.save!
    end

  end
end

def notifications_counts(contact_email)
  contact = Contact.find(:first, :conditions => [ "lower(email) = ?", contact_email.downcase ])
  nots = Notification.where("contact_id = #{contact.id}") if contact
  count = nots && nots.size > 0 ? nots.size : 0
  puts "#### #{contact_email} has #{count} notifications"
end

def delete_notifications(contact_email)
  puts "#### attempting to delete notifications for '#{contact_email}'"

  contact = Contact.find_by_email contact_email

  if ! contact
    puts "#### delete: cannot find email '#{contact_email}'"
    return
  end

  notifications = Notification.where("contact_id = #{contact.id}")

  Notification.where("contact_id = #{contact.id}").destroy_all if notifications && notifications.size > 0
end

contacts_list = [
  {
    :contact_email => 're4@sanger.ac.uk',
    :sets => [set_1, set_2],
    :delete => true,
    :active => false
  },
  {
    :contact_email => 'vvi@sanger.ac.uk',
    :sets => [set_1, set_2],
    :delete => true,
    :active => false
  },
  {
    :contact_email => 'A.Mallon@har.mrc.ac.uk',
    :sets => [set_1, set_2],
    :delete => false,
    :active => false
  },
  {
    :contact_email => 'A.Blake@har.mrc.ac.uk',
    :sets => [set_1, set_2],
    :delete => true,
    :active => false
  },
  {
    :contact_email => 'tmeehan@ebi.ac.uk',
    :sets => [set_1, set_2],
    :delete => true,
    :active => false
  },
  {
    :contact_email => 'Lauryl.Nutter@phenogenomics.ca',
    :sets => [set_2],
    :delete => true,
    :active => false
  }
]

contacts_list.each do |contact|
  if ! contact[:active]
    puts "#### ignore '#{contact[:contact_email]}'"
    next
  end

  contact[:sets].each do |set|
    delete_notifications(contact[:contact_email]) if contact[:delete]
    build_welcome_email(contact[:contact_email], set)
    NotificationMailer.send_welcome_email_bulk
  end
end