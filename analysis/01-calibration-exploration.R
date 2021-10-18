library(tidyverse)
library(readxl)

leiden_df <- read_xlsx("../external_data/CWTS Leiden Ranking 2020.xlsx",
                       sheet = "Results")

leiden_select <- leiden_df %>% 
  filter(Field == "All sciences", Frac_counting == 0) %>% 
  select(University, Period, impact_P)

leiden_select %>% 
  # filter(Period == "2015–2018") %>% 
  ggplot(aes(impact_P)) +
  geom_histogram() +
  facet_wrap(vars(Period))

ggsave(filename = "plots/pub_dist_leiden.png")
