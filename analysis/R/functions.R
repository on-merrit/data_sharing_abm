read_experiments <- function(path) {
  read_csv(path, skip = 6) %>% 
    tibble(.name_repair = "universal") %>% 
    mutate(across(contains("gini"), as.numeric))
}

read_nested_experiment <- function(path, 
                                   columns = c(
                                     "who", "data_grant_share", 
                                     "n_publications", "n_pubs_with_data_shared",
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

