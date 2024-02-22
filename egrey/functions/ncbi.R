search_oder = function(x, cfg){
  
  search_order_one = function(tbl, key){
    
    species_ids_ls <- strsplit(tbl$spp_list, ";", fixed = TRUE)
    if (is.na(species_ids_list[1])) return(NULL)
    
    ss = lapply(species_ids_ls,
      function(id){
        search_name = paste0("txid", id, "[Organism]")
        term = paste(search_name, "AND mitochondrion[TITL] AND complete genome[TITL]")
        mitogenomes <- try(rentrez::entrez_search(db=cfg$entrez$order_search$datase, 
                                                  term = term, 
                                                  retmax=cfg$entrez$order_search$retmax1))
        if (inherits(mitogenomes, "try-error")){
          # fail?  try another way?
          targets <- try(rentrez::entrez_search(db="nucleotide", 
                                                term = paste(search_name, target_locus_searchterm, collapse=" "), retmax=999999))
        } else {
          
        } # try-error?
      })
    
    
  }
  
  y = dplyr::rowwise(x) |>
    dplyr::group_map(search_order_one, .keep = TRUE)
  
} # search_order