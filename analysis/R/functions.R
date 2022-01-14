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
  if (any(str_detect(names(df), "gini.*datasets"))) {
    dplyr::rename(
      df,
      gini_grants = gini..n.grants..of.groups, 
      gini_publications = gini..n.publications..of.groups,
      gini_datasets = gini..total.datasets..of.groups
    )
  } else {
    dplyr::rename(
      df,
      gini_grants = gini..n.grants..of.groups, 
      gini_publications = gini..n.publications..of.groups
    )
  }

}


clean_pub_weight <- function(df) {
  levels <- c(.5, .85, 1)
  mutate(df, `Publication weight (vs. data)` = factor(
    pubs.vs.data, levels = levels, labels = scales::percent(levels))
  )
}
