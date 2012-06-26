#!/usr/bin/env ruby

#Task #8495

#The following 800 - ish genes have to be added to the MGP consortium as MI Plans,

#Production Centre = WTSI
#Status - Assigned - we could go through the Interest / Reconcile thing again, but why bother ...
#Priority - Low
#Subproject - MGP Interest

DRY_RUN = false

exclude_mgi_id = %w(
MGI:2686516
MGI:3045311
MGI:1913385
MGI:1925500
MGI:2384819
MGI:1859635
MGI:1890404
MGI:1915104
MGI:1917729
MGI:1926231
MGI:2442968
MGI:1920994
MGI:1928368
)

mgi_id = %w(
MGI:107942
MGI:2682939
MGI:1914775
MGI:1917820
MGI:1333114
MGI:1915548
MGI:2147092
MGI:3650445
MGI:96231
MGI:1919541
MGI:3651161
MGI:3651680
MGI:97757
MGI:2445107
MGI:3583942
MGI:1914476
MGI:1338001
MGI:1914870
MGI:1914149
MGI:1343133
MGI:2653629
MGI:1924769
MGI:2451333
MGI:103254
MGI:1914561
MGI:2443129
MGI:1913872
MGI:1914082
MGI:2179809
MGI:1858964
MGI:1914831
MGI:1917867
MGI:1919315
MGI:2181962
MGI:1337063
MGI:3712084
MGI:1922072
MGI:1921490
MGI:96763
MGI:2140623
MGI:3045360
MGI:2182303
MGI:1921601
MGI:1916577
MGI:2684864
MGI:104884
MGI:1921570
MGI:1923605
MGI:2443541
MGI:1917294
MGI:2443082
MGI:1330239
MGI:1277956
MGI:1913128
MGI:1921575
MGI:1298393
MGI:1925152
MGI:2446120
MGI:1917967
MGI:1861452
MGI:1934858
MGI:2147598
MGI:1919391
MGI:1919039
MGI:1920832
MGI:1913937
MGI:1916315
MGI:1918970
MGI:95314
MGI:1924709
MGI:2685948
MGI:2673998
MGI:3641955
MGI:1923027
MGI:1277216
MGI:1926027
MGI:3612240
MGI:3531417
MGI:2444022
MGI:1352508
MGI:1931744
MGI:1913634
MGI:2142121
MGI:1914683
MGI:1920921
MGI:1914871
MGI:1921372
MGI:3040701
MGI:99186
MGI:1914198
MGI:1261845
MGI:2183448
MGI:99476
MGI:1920586
MGI:2384939
MGI:1919904
MGI:1917635
MGI:1916947
MGI:3047714
MGI:3037815
MGI:2141135
MGI:1921824
MGI:2387367
MGI:1913761
MGI:1921664
MGI:1098533
MGI:1859635
MGI:2685446
MGI:1930128
MGI:1913586
MGI:1920713
MGI:1913443
MGI:1926233
MGI:1923821
MGI:1918066
MGI:1915293
MGI:3036238
MGI:1916509
MGI:1916230
MGI:2449973
MGI:1920595
MGI:1926283
MGI:3647788
MGI:2678023
MGI:1919824
MGI:1354385
MGI:1917866
MGI:3647699
MGI:99462
MGI:1914086
MGI:1346030
MGI:1913879
MGI:103238
MGI:104912
MGI:2442185
MGI:106019
MGI:99526
MGI:1349661
MGI:2388733
MGI:1923035
MGI:1918677
MGI:102956
MGI:1922459
MGI:2389490
MGI:3617846
MGI:1925155
MGI:1922783
MGI:3711222
MGI:2442492
MGI:109572
MGI:1344363
MGI:2670969
MGI:2139207
MGI:1916969
MGI:2384819
MGI:1931050
MGI:1329041
MGI:102756
MGI:2672878
MGI:1915759
MGI:1919704
MGI:2179197
MGI:1915894
MGI:1891654
MGI:2685819
MGI:2684931
MGI:1913836
MGI:1917631
MGI:1919077
MGI:2141485
MGI:2180560
MGI:1920994
MGI:1929668
MGI:1858179
MGI:2138853
MGI:1098233
MGI:1341430
MGI:894687
MGI:2157899
MGI:3651514
MGI:1925401
MGI:2142008
MGI:1915079
MGI:2684313
MGI:2384718
MGI:1920094
MGI:1914725
MGI:1918965
MGI:2180557
MGI:1914769
MGI:102935
MGI:1918983
MGI:1926231
MGI:2682937
MGI:1921302
MGI:3528744
MGI:1917729
MGI:3046173
MGI:2384567
MGI:1914264
MGI:1923100
MGI:1261428
MGI:1922974
MGI:1918103
MGI:1916115
MGI:1201681
MGI:1339710
MGI:1919051
MGI:106626
MGI:1913616
MGI:1916910
MGI:3039614
MGI:1351867
MGI:1913903
MGI:1920462
MGI:2444763
MGI:1289265
MGI:1913572
MGI:1914386
MGI:3649852
MGI:2138153
MGI:1921272
MGI:1917178
MGI:1929280
MGI:2153839
MGI:2385277
MGI:3027003
MGI:1920853
MGI:2443817
MGI:1925082
MGI:88436
MGI:1922337
MGI:3641861
MGI:104678
MGI:1917377
MGI:1914184
MGI:1915476
MGI:3648524
MGI:1930075
MGI:2145373
MGI:108424
MGI:3583946
MGI:1922428
MGI:2676970
MGI:102785
MGI:1914745
MGI:1913751
MGI:1918629
MGI:1924282
MGI:2147434
MGI:1924034
MGI:1918234
MGI:99201
MGI:1920986
MGI:1920248
MGI:109531
MGI:2681523
MGI:1913466
MGI:2442496
MGI:2387201
MGI:1859026
MGI:97516
MGI:1916026
MGI:1913835
MGI:1855690
MGI:2683854
MGI:2143702
MGI:2664539
MGI:1919148
MGI:1918253
MGI:2444085
MGI:2385287
MGI:1914759
MGI:1919588
MGI:1917086
MGI:1921729
MGI:1913628
MGI:2670997
MGI:1919135
MGI:1890404
MGI:3690448
MGI:2137225
MGI:1916867
MGI:2136459
MGI:1921771
MGI:3041210
MGI:1922873
MGI:108038
MGI:2139258
MGI:2444835
MGI:2685354
MGI:1277180
MGI:1277238
MGI:106264
MGI:3650541
MGI:2682313
MGI:1922813
MGI:1913529
MGI:2446208
MGI:2444680
MGI:1916145
MGI:1919787
MGI:1347060
MGI:1891207
MGI:3642353
MGI:1924308
MGI:3040708
MGI:1922368
MGI:104976
MGI:1915434
MGI:1915566
MGI:2138865
MGI:2443699
MGI:1277176
MGI:96012
MGI:2138939
MGI:1916824
MGI:1914816
MGI:95742
MGI:90168
MGI:1921294
MGI:2183442
MGI:1919205
MGI:1917188
MGI:1915722
MGI:1916279
MGI:2443079
MGI:1922791
MGI:2655107
MGI:2684948
MGI:1196234
MGI:1921556
MGI:1916401
MGI:1914830
MGI:1343054
MGI:2445062
MGI:3616079
MGI:3642748
MGI:1916400
MGI:109327
MGI:2144501
MGI:1925771
MGI:1915472
MGI:1859821
MGI:1923236
MGI:2443135
MGI:2155700
MGI:1916719
MGI:3612242
MGI:3037816
MGI:1924039
MGI:96881
MGI:2144765
MGI:1921895
MGI:2442558
MGI:1927479
MGI:1918044
MGI:1924234
MGI:1921747
MGI:1914968
MGI:1915571
MGI:1859251
MGI:3612701
MGI:2183559
MGI:1924360
MGI:2146565
MGI:1916176
MGI:1923507
MGI:2156159
MGI:1919519
MGI:2443133
MGI:1922542
MGI:1915560
MGI:2683557
MGI:1913453
MGI:3039580
MGI:1316740
MGI:1913895
MGI:1345192
MGI:1916678
MGI:1918000
MGI:2152835
MGI:1916489
MGI:99199
MGI:3647347
MGI:1197514
MGI:1859609
MGI:1917689
MGI:1919906
MGI:1351629
MGI:1914134
MGI:1096575
MGI:1914538
MGI:1914531
MGI:1915770
MGI:1353460
MGI:2388651
MGI:2684968
MGI:1349389
MGI:1277150
MGI:3616088
MGI:1930190
MGI:1915541
MGI:3646213
MGI:99160
MGI:1923078
MGI:1914887
MGI:3618861
MGI:2385847
MGI:2442211
MGI:1921899
MGI:2443858
MGI:2139793
MGI:1918952
MGI:2443755
MGI:1914727
MGI:2684967
MGI:1916117
MGI:1197518
MGI:1919060
MGI:1933107
MGI:1915986
MGI:2442637
MGI:1915243
MGI:2445183
MGI:2652816
MGI:3643284
MGI:3648915
MGI:2682303
MGI:1914570
MGI:1923684
MGI:2153089
MGI:1345669
MGI:1917817
MGI:94852
MGI:1926788
MGI:1890394
MGI:1100878
MGI:1923686
MGI:2686516
MGI:2447532
MGI:1913867
MGI:1919830
MGI:1918772
MGI:3616086
MGI:1919455
MGI:2442643
MGI:1914679
MGI:1915159
MGI:1351635
MGI:2384576
MGI:1919412
MGI:3039622
MGI:1917405
MGI:2384910
MGI:1861747
MGI:1923813
MGI:3652048
MGI:1270148
MGI:2448523
MGI:1916441
MGI:2444477
MGI:2686212
MGI:1914843
MGI:1917802
MGI:2684051
MGI:1926029
MGI:1919399
MGI:3647736
MGI:1922666
MGI:3046463
MGI:1916463
MGI:2442910
MGI:2443049
MGI:1922869
MGI:2442358
MGI:1918946
MGI:108450
MGI:1924116
MGI:1916944
MGI:2144566
MGI:2144822
MGI:2135882
MGI:3654828
MGI:2443584
MGI:2385030
MGI:2442265
MGI:1344373
MGI:2685201
MGI:1920920
MGI:1914203
MGI:2685751
MGI:2672853
MGI:2444426
MGI:2444576
MGI:2443290
MGI:2446273
MGI:2444921
MGI:3645902
MGI:1917160
MGI:1345142
MGI:1917347
MGI:1354735
MGI:2384873
MGI:1922715
MGI:1915848
MGI:1861622
MGI:1918224
MGI:2685474
MGI:2443048
MGI:1889619
MGI:99257
MGI:2685031
MGI:106248
MGI:3651470
MGI:1889817
MGI:2667176
MGI:97317
MGI:1917338
MGI:1922349
MGI:1933831
MGI:1921945
MGI:1913385
MGI:107780
MGI:2442934
MGI:2142077
MGI:2182465
MGI:1916242
MGI:3629968
MGI:3040697
MGI:2665790
MGI:1928393
MGI:102703
MGI:1920402
MGI:1920136
MGI:1933407
MGI:3045311
MGI:1925500
MGI:2667783
MGI:107539
MGI:1097709
MGI:1915349
MGI:1921766
MGI:2385851
MGI:1891640
MGI:2684972
MGI:1913651
MGI:1919159
MGI:1928368
MGI:1916786
MGI:1919637
MGI:2684035
MGI:1919141
MGI:2140368
MGI:1915240
MGI:1918867
MGI:1097706
MGI:2685917
MGI:2142454
MGI:1914967
MGI:1890478
MGI:3651439
MGI:1913663
MGI:2682940
MGI:3510405
MGI:1923330
MGI:2443431
MGI:2685058
MGI:1341200
MGI:1918110
MGI:1923736
MGI:2676395
MGI:1097696
MGI:2137218
MGI:1929785
MGI:2138890
MGI:1917516
MGI:2140435
MGI:98542
MGI:109182
MGI:1095406
MGI:2442630
MGI:104859
MGI:107893
MGI:2442892
MGI:104885
MGI:2446235
MGI:1919064
MGI:1917459
MGI:1929914
MGI:1278328
MGI:1913819
MGI:1918269
MGI:3036264
MGI:1913475
MGI:2146285
MGI:2384725
MGI:1915139
MGI:3588212
MGI:1919579
MGI:1919074
MGI:3044626
MGI:1919681
MGI:1919409
MGI:2444114
MGI:2144891
MGI:2143103
MGI:1277120
MGI:2445092
MGI:2679256
MGI:2684929
MGI:1919979
MGI:2141635
MGI:1923497
MGI:1914097
MGI:1921282
MGI:3606576
MGI:1196373
MGI:1314633
MGI:1921682
MGI:1920407
MGI:104841
MGI:1917585
MGI:1918638
MGI:1917821
MGI:1916746
MGI:1933289
MGI:1913316
MGI:1930265
MGI:1915106
MGI:2675306
MGI:2158650
MGI:1306812
MGI:1929099
MGI:2447164
MGI:1913877
MGI:1352755
MGI:2444661
MGI:3647874
MGI:1916962
MGI:1891017
MGI:2384837
MGI:1924012
MGI:2444629
MGI:1913699
MGI:1918667
MGI:106587
MGI:2143535
MGI:1917706
MGI:2444814
MGI:3041170
MGI:1923760
MGI:2443154
MGI:1923173
MGI:1913764
MGI:2446144
MGI:1919018
MGI:1916107
MGI:2445121
MGI:1931787
MGI:1914473
MGI:1921806
MGI:2443469
MGI:1932610
MGI:2446239
MGI:2686594
MGI:2442368
MGI:1914815
MGI:1913808
MGI:1916368
MGI:3710243
MGI:2141440
MGI:1920196
MGI:2442397
MGI:3649972
MGI:3712328
MGI:2442621
MGI:1277202
MGI:2385131
MGI:2448491
MGI:1336997
MGI:1202305
MGI:101813
MGI:2444736
MGI:2677270
MGI:1916707
MGI:1328354
MGI:2672976
MGI:2685280
MGI:2140313
MGI:2660674
MGI:1916356
MGI:1916186
MGI:2685422
MGI:1913844
MGI:1860490
MGI:1919618
MGI:1917609
MGI:3607791
MGI:1922764
MGI:3646296
MGI:2679732
MGI:1916942
MGI:1920632
MGI:2443478
MGI:2445102
MGI:107948
MGI:3651375
MGI:2444178
MGI:1919347
MGI:1921425
MGI:1889574
MGI:1916189
MGI:1914061
MGI:102784
MGI:1344347
MGI:105983
MGI:1916913
MGI:2446108
MGI:2685416
MGI:2444386
MGI:3650286
MGI:3702974
MGI:2446129
MGI:1917064
MGI:700010
MGI:2444387
MGI:1916963
MGI:1924748
MGI:1917677
MGI:2682318
MGI:107445
MGI:1916556
MGI:1921793
MGI:893586
MGI:1934677
MGI:1099786
MGI:1316706
MGI:1349406
MGI:1891698
MGI:3521861
MGI:3045368
MGI:96618
MGI:3639495
MGI:1333857
MGI:1918345
MGI:1925752
MGI:2682948
MGI:1095401
MGI:1914207
MGI:1925288
MGI:2443162
MGI:3646231
MGI:1929278
MGI:3618859
MGI:95678
MGI:106388
MGI:95886
MGI:1914558
MGI:1916997
MGI:1277971
MGI:2135951
MGI:3588200
MGI:2444782
MGI:3618339
MGI:1914116
MGI:3605543
MGI:2684943
MGI:2444263
MGI:2384803
MGI:3712553
MGI:1922827
MGI:1913807
MGI:2385054
MGI:2384581
MGI:1890618
MGI:2685214
MGI:1927617
MGI:2443333
MGI:1920930
MGI:1339709
MGI:1915057
MGI:1924315
MGI:1915446
MGI:3045315
MGI:2385853
MGI:1918309
MGI:2442372
MGI:94907
MGI:2155278
MGI:1915104
MGI:95624
MGI:3643170
MGI:2445126
MGI:1919722
MGI:2136282
MGI:1919119
MGI:1918876
MGI:106402
MGI:3606480
MGI:1919799
MGI:2140197
MGI:1919891
MGI:2442968
MGI:1920979
MGI:2684047
MGI:1922941
)

ID_COUNT = 807
EXCLUDE_ID_COUNT = 13

raise "Found #{mgi_id.count} ids - expecting #{ID_COUNT}" if mgi_id.count != ID_COUNT
raise "Found #{exclude_mgi_id.count} (exclude) ids - expecting #{EXCLUDE_ID_COUNT}" if exclude_mgi_id.count != EXCLUDE_ID_COUNT

after_count_expected = MiPlan.count + ID_COUNT - EXCLUDE_ID_COUNT

Rails.logger.info  "create_new_mgp_plans.rb: START"

ApplicationModel.audited_transaction do

  consortium 		= Consortium.find_by_name!('MGP')
  production_centre 	= Centre.find_by_name!('WTSI')
  status 		= MiPlan::Status.find_by_name!('Assigned')
  priority          	= MiPlan::Priority.find_by_name!('Low')
  sub_project           = MiPlan::SubProject.find_by_name!('MGPinterest')

  mgi_id.each do |id|
    next if exclude_mgi_id.include? id

    gene = Gene.find_by_mgi_accession_id id
    raise "Cannot find #{id}!" if ! gene

    mi_plan = MiPlan.create!(
      :gene 		  => gene,
      :consortium 	  => consortium,
      :production_centre  => production_centre,
      :status 		  => status,
      :priority           => priority,
      :sub_project        => sub_project
    )

    Rails.logger.info  "create_new_mgp_plans.rb: New plan: #{mi_plan.inspect}"
  end

  after_count = MiPlan.count

  raise "expected to find #{after_count_expected} - actually found #{after_count}" if after_count != after_count_expected

  raise "don't save!" if DRY_RUN
end

Rails.logger.info  "create_new_mgp_plans.rb: END"

puts "done!"
