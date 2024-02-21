source("setup.R")
data(mtDNAterms)

#' The primary script runner
#'
#' @param cfg list the configuration list
#' @param key char, the entrez key
main = function(cfg = refdbtools::read_configuration("input/egrey0.000.yaml"),
                entrez_key = refdbtools::get_entrez_key()){
  
  rentrez::set_entrez_key(entrez_key)
  
  mtDNAterms = append_mtDNAterms(x = mt_DNAterms(), 
    y = dplyr::as_tibble(cfg$mtDNAterms))
  
  is_mtgene = cfg$locus %in% cfg$mtgene_loci
  
  target_locus_synonyms = mtDNAterms |>
    dplyr::filter(Locus %in% cfg$locus)
  
  search_terms = mt_search_terms(target_locus_synonyms, 
    modifier = cfg$entrez$search$search_modifier)
    
  species_list = readr::read_csv(cfg$species_list$filename, col_types= "c") |>
    rlang::set_names(cfg$species_list$colname)
    
  order_list = readr::read_csv(cfg$order_list$filename, col_types = "ccccccc")
  
  species_list_dedup <- unique(species_list$search_name)
  
  # this runs once per user unless the user specifies \code{overwrite: yes} in the config
  db_tax_NCBI = taxizedb::db_download_ncbi(verbose = FALSE, 
    overwrite = cfg$tax_db$ncbi$overwrite) 
  
  # this uses the downloaded db by default and mines a list
  # here we convert it to a data frame whihc we can operate upon by group (species in this case)
  # I'm saving a copy here, in anticipation of needing restarts later (maybe just for development)
  taxonomies_cls_filename = file.path(cfg$output_folder, sprintf("%s-taxonomies_cls.csv.gz", cfg$version))
  taxonomies_cls <- if (file.exists(taxonomies_cls_filename)){
    readr::read_csv(taxonomies_cls_filename, col_types = "cccc")
    } else {
      taxizedb::classification(species_list_dedup, db="ncbi") |>
        reform_classification() |>
        dplyr::mutate(name = gsub(".", "", .data$name, fixed = TRUE)) |>
        readr::write_csv(taxonomies_cls_filename)
    } 
  
  taxa_df = taxonomies_cls |>
    dplyr::mutate(species = factor(.data$species, levels = species_list_dedup)) |>
    tabulate_classification()
    
    
    
} # end of main

args = commandArgs(trailingOnly = TRUE)
cfgfile = if (length(args) <= 0)  "input/egrey0.000.yaml" else args[1]
keyfile = if (length(args) <= 1) "~/.entrez_key" else args[2]
cfg = refdbtools::read_configuration(cfgfile)
entrez_key = refdbtools::get_entrez_key(keyfile)

status = main(cfg, entrez_ey = entrez_key)

if (!interactive()) quit(status = status, save = "no")
