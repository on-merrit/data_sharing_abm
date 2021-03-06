read_experiments <- function(path) {
  read_csv(path, skip = 6) %>% 
    tibble(.name_repair = "universal") %>% 
    mutate(across(contains("gini"), as.numeric))
}

read_nested_experiment <- function(path, 
                                   columns = c(
                                     "who", "n_publications",
                                     "n_pubs_with_data_shared",
                                     "total_grants")) {
  df <- read_csv(path, skip = 6) %>% 
    tibble(.name_repair = "universal") 
  
  df_extracted <- df %>% 
    mutate(stuff = str_remove_all(stuff, "(^\\[\\[)|(\\]\\]$)")) %>% 
    separate(stuff, paste0("group", 1:100), sep = "\\] \\[") %>% 
    pivot_longer(starts_with("group"), names_to = "group", values_to = "vals") %>% 
    separate(vals, columns, sep = "\\s") %>% 
    mutate(across(all_of(columns), as.numeric))
  
  df_extracted %>% 
    rename(run = .run.number., step = .step.)
}


read_leiden <- function(path) {
  leiden_df <- readxl::read_xlsx(path, sheet = "Results")
  
  leiden_df %>% 
    filter(Field == "All sciences", Frac_counting == 0) %>% 
    select(University, Period, impact_P)
}


rename_gini <- function(df) {
  dplyr::rename(
    df,
    gini_grants = starts_with("gini..n.grants"), 
    gini_publications = starts_with("gini..n.pubs"),
    gini_datasets = starts_with("gini..publications")
  )
}

rename_gini_baseline <- function(df) {
  dplyr::rename(
    df,
    gini_grants = starts_with("Gini..Total.grants"), 
    gini_publications = starts_with("Gini..N.publ")
  )
}


clean_pub_weight <- function(df) {
  levels <- c(.5, .85, 1)
  mutate(df, `Publication weight (vs. data)` = factor(
    pubs.vs.data, levels = levels, labels = scales::percent(levels))
  )
}
