#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'

STDOUT.sync = true

class ScraperMmrrcRepository

    attr_accessor :gene_details
    attr_accessor :count_is_mice
    attr_accessor :count_is_recovery
    attr_accessor :count_is_germ_plasm
    attr_accessor :count_is_embryos
    attr_accessor :count_unique_alleles_found
    attr_accessor :count_unique_alleles_with_products

    # URLs for scraping MMRRC websites
    MMRRC_REPO = 'MMRRC'
    MMRRC_GENES_CATALOG_PAGE_URL = '?'
    MMRRC_GENE_PAGE_URL_STUB     = '?'
    MMRRC_GENE_SEARCH_STUB       = '?'

    def initialize
        # instance variables
         @gene_details                       = {}
         @count_is_mice                      = 0
         @count_is_recovery                  = 0
         @count_is_germ_plasm                = 0
         @count_is_embryos                   = 0
         @count_unique_alleles_found         = 0
         @count_unique_alleles_with_products = 0
    end

    def fetch_allele_details( marker_symbol, geneid )

    end
end

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  ScraperMmrrcRepository.new
end