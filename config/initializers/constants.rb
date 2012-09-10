SITE_PATH = case Rails.env
when 'production' then
  'http://mousephenotype.org/imits'
when 'staging' then
  'http://htgt.internal.sanger.ac.uk:4008/kermits2'
else
  'http://example.com/imits'
end

ALLELE_OVERALL_PASS_PATH = case Rails.env
when 'test' then
  # 'http://www.sanger.ac.uk/htgt/report/allele_overall_pass?view=csvdl'
  'test/db/allele_overall_pass.csv'
else
  # 'test/db/allele_overall_pass.csv'
  #'test/db/full_allele_overall_pass_download.csv'
  'http://www.sanger.ac.uk/htgt/report/allele_overall_pass?view=csvdl'
end
