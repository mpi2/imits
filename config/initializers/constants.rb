SITE_PATH = case Rails.env
when 'production' then
  'http://mousephenotype.org/imits'
when 'staging' then
  'http://htgt.internal.sanger.ac.uk:4008/kermits2'
else
  'http://example.com/imits'
end
