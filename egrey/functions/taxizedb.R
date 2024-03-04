#' Reformat a \code{taxizedb::classification()} output into a tibble.
#'
#' For each request \code{taxizedb::classification()} it returns a list element
#' what has either three variable data frame (name, rank and id) or NA (instead of
#' a friendlier empty data frame or NULL)
#'
#' @param x named list as output by \code{taxizedb::classification()}
#' @return a tibble with a prepended \code{species} variable for each element of \code{x}
reform_classification = function(x){
  dummy = dplyr::tibble(name = NA_character_, rank = NA_character_, id = NA_character_)
  lapply(names(x),
    function(sp){
      v = if (is.na(x[sp])){
          dummy
        } else {
          dplyr::as_tibble(x[[sp]])
        } 
      dplyr::mutate(v, species = sp, .before = 1)
    }) |>
  dplyr::bind_rows()
}

#' Tally species in the output of \code{reform_taxized}
#'
#' @param x data frame (tibble), the output of \code{reform_taxized}
#' @param ranks the order ranks to tally
#' @param sep char, the character separator used to bind \code{name} and \code{id}
#' @return data frame (tibble) of ranks by species
tabulate_classification = function(x, 
  ranks = c("superkingdom", "kingdom", "phylum", "class", 
            "order", "family", "genus", "species"),
            sep = "_"){
              
   dummy = dplyr::tibble(
     tax_query = NA_character_,
     superkingdom = NA_character_,
     kingdom = NA_character_,
     phylum = NA_character_,
     class = NA_character_,
     order = NA_character_,
     family = NA_character_,
     genus = NA_character_,
     species = NA_character_,
     )  
              
   tally_one = function(tbl, key, dummy = NULL){
     
     first = function(x){
       x[1]
     }
     
     if (tbl$value[1] == "NA_NA"){
       v = dummy |>
         dplyr::mutate(tax_query = tbl$tax_query)
     } else {
     
        v = dplyr::filter(tbl, rank %in% ranks) |>
          tidyr::pivot_wider(id_cols = tax_query, 
                             names_from = rank, 
                             values_from = value,
                             values_fn = first,
                             names_repair = "minimal")
      }
      v
   } # tally_one
   
   
   
   x |>
    dplyr::mutate(value = paste(.data$name, .data$id, sep = sep)) |>
    dplyr::rename(tax_query = "species") |>
    dplyr::group_by(tax_query) |>
    dplyr::group_map(tally_one, .keep = TRUE, dummy = dummy) |>
    dplyr::bind_rows()
    
              
}