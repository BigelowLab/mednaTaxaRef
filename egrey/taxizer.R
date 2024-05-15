#' Pretty simple... given a vector of species (binomial) do all one can to 
#' generate a table of species, ncbi-id, superkingdom, kingdom, phylum, class, order, family, genus, species
#'
#' Calling sequence:
#' $Rscript /path/to/taxizer.R /path/to/config.yaml


main = function(cfg){
  charlier::info("starting version %s", cfg$version)
  x = readr::read_csv(cfg$input$filename, show_col_types = FALSE)
  
  if (cfg$input$sentence_case){
    charlier::info("making sentence case")
    x[[cfg$input$name]] <- stringr::str_to_sentence(x[[cfg$input$name]])
  }
  
  if (cfg$input$deduplicate){
    n = nrow(x)
    x <- dplyr::filter(x, duplicated(x[[cfg$input$name]]))
    charlier::info("deduplication removed %i records", nx = nrow(x))
  }
  
  if (!is.null(cfg$input$subsample)) {
    charlier::info("subsampling to just %i records", cfg$input$subsample)
    set.seed(cfg$input$subsample)
    x = dplyr::slice_sample(x, n = cfg$input$subsample)
  }

  charlier::info("searching taxonomy")
  
  # here we break into the specified chunk size
  steps = ceiling(nrow(x)/cfg$tax_db$chunk)
  index = rep(seq_len(steps), each = cfg$tax_db$chunk, length = nrow(x))
  
  r <- x[[cfg$input$name]] |>
    dplyr::mutate(index_ = index) |>
    dplyr::group_by(index_) |>
    dplyr::group_map(
      function(tbl, key){
        Sys.sleep(cfg$tax_db$sleep)
        taxizedb::classification(tbl, db=cfg$tax_db$db) |>
              reform_classification() |>
              tabulate_classification()
      }) |>
    dplyr::bind_rows()|>  
      readr::write_csv(file.path(cfg$output$path, sprintf("%s-taxa.csv.gz", cfg$input$name)))
  
  
  #r = taxizedb::classification(x[[cfg$input$name]], db=cfg$tax_db$db) |>
  #    reform_classification() |>
  #    tabulate_classification() |>  
  #    readr::write_csv(file.path(cfg$output$path, sprintf("%s-taxa.csv.gz")))
  
  return(0)
}


source("setup.R")
args = commandArgs(trailingOnly = TRUE)
cfgfile = if (length(args) <= 0)  "input/taxizer.000.yaml" else args[1]
stopifnot(file.exists(cfgfile))
cfg = yaml::read_yaml(cfgfile)
if (!dir.exists(cfg$output$path)) ok = dir.create(cfg$output$path, recursive = TRUE)
charlier::start_logger(filename = file.path(cfg$output, sprintf("log-%s", cfg$version)))

charlier::info("downloading or reading NCBI taxa database")
db_tax_NCBI = taxizedb::db_download_ncbi(verbose = cfg$verbose, 
  overwrite = cfg$tax_db$overwrite) 

if (!interactive()){
  ok = main(cfg)
  quit(save = "no", status = ok)
}
