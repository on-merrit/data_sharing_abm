library(tidyverse)

df <- read_csv("../outputs/data_sharing baseline-table.csv", skip = 6,
               col_types = cols(
                 `[run number]` = col_double(),
                 `history-length` = col_double(),
                 `n-available-grants` = col_double(),
                 `n-groups` = col_double(),
                 `importance-of-chance` = col_double(),
                 `share-data?` = col_logical(),
                 `[step]` = col_double(),
                 `mean-grants groups` = col_double(),
                 `mean-publications groups` = col_double(),
                 `grants-gini` = col_double(),
                 `publications-gini` = col_double()
               )) %>% 
  tibble(.name_repair = "universal")

extrafont::loadfonts(device = "win")
theme_set(hrbrthemes::theme_ipsum_rc(base_family = "Hind"))


# baseline stuff ----
grants_pubs <- df %>% 
  select(run_number = .run.number., chance_imp = importance.of.chance, 
         step = .step., mean_grants = mean.grants.groups, 
         mean_publications = mean.publications.groups)

grants_pubs %>% 
  # filter(run_number <= 10) %>% 
  ggplot(aes(step, mean_grants, colour = factor(chance_imp))) +
  geom_line(aes(group = run_number)) +
  labs(y = "mean number of grants")
# number of grants is fixed


grants_pubs %>% 
  ggplot(aes(step, mean_publications, colour = factor(chance_imp))) +
  # geom_line(aes(group = run_number), alpha = .2) +
  geom_smooth() +
  labs(y = "mean number of publications")
ggsave("plots/publications_by_grant_chance.png")
# number of publications is the same, no matter the granting mechanism
# presumably, because the total number of grants (=additional resources) is
# always the same. 
# But there would be a difference in the gini coefficient


df %>% 
  select(run_number = .run.number., chance_imp = importance.of.chance, 
         step = .step., contains("gini")) %>% 
  pivot_longer(contains("gini")) %>% 
  mutate(chance_imp = factor(chance_imp, labels = chance_imp %>% unique() %>%
                               as.numeric() %>% scales::percent())) %>% 
  ggplot(aes(step, value, colour = factor(chance_imp))) +
  geom_smooth() +
  facet_wrap(vars(name)) +
  labs(x = "Years", y = "gini", 
       colour = "importance of chance",
       caption = "n = 100 agents") +
  theme(legend.position = "top") +
  guides(colour = guide_legend(nrow = 1))
ggsave("plots/ginis.png")
