library(tidyverse)

extrafont::loadfonts(device = "win")
theme_set(hrbrthemes::theme_ipsum_rc(base_family = "Hind"))

df_funder_sharing <- read_csv(
  "../outputs/data_sharing sharing-funders-table.csv", 
  skip = 6,
  lazy = FALSE
) %>% 
  tibble(.name_repair = "universal") %>% 
  mutate(across(contains("gini"), as.numeric))


# baseline
pdata <- df_funder_sharing %>% 
  filter(!fund.on.data.history., !share.data.) %>% 
  select(.run.number., .step., 
         mean.grants.groups:sum..total.primary.publications..of.groups) %>% 
  pivot_longer(-c(.run.number., .step.)) %>% 
  drop_na()

pdata %>% 
  ggplot(aes(.step., value)) +
  geom_smooth() +
  # geom_point() +
  facet_wrap(vars(name), scales = "free_y")

p <- pdata %>% 
  filter(str_detect(name, "gini")) %>% 
  ggplot(aes(.step., value, colour = name, group = .run.number.)) +
  geom_line()
p
plotly::ggplotly(p)

pdata %>% 
  filter(str_detect(name, "gini")) %>% 
  ggplot(aes(.step., value, colour = name)) +
  geom_smooth()


# data sharing
pdata_sharing <- df_funder_sharing %>% 
  filter(!fund.on.data.history.) %>% 
  select(.run.number., .step., share.data.,
         mean.grants.groups:sum..total.primary.publications..of.groups) %>% 
  pivot_longer(-c(.run.number., .step., share.data.)) %>% 
  drop_na()

pdata_sharing %>% 
  filter(str_detect(name, "gini")) %>% 
  ggplot(aes(.step., value, colour = share.data.)) +
  geom_smooth() +
  facet_wrap(vars(name))
# inequality is higher when sharing data

p <- pdata_sharing %>% 
  filter(str_detect(name, "gini")) %>% 
  ggplot(aes(.step., value, colour = share.data., group = .run.number.)) +
  geom_line() +
  facet_wrap(vars(name), nrow = 2)
plotly::ggplotly(p)


# data sharing with funding reward
data_funding <- df_funder_sharing %>% 
  filter(share.data.) %>% 
  select(.run.number., .step., fund.on.data.history.,
         mean.grants.groups:sum..total.primary.publications..of.groups) %>% 
  pivot_longer(-c(.run.number., .step., fund.on.data.history.)) %>% 
  drop_na()
data_funding

data_funding %>% 
  filter(str_detect(name, "gini")) %>% 
  ggplot(aes(.step., value, colour = fund.on.data.history.)) +
  geom_smooth() +
  facet_wrap(vars(name))
# inequality is higher when sharing data

p <- data_funding %>% 
  filter(str_detect(name, "gini")) %>% 
  ggplot(aes(.step., value, colour = fund.on.data.history., group = .run.number.)) +
  geom_line() +
  facet_wrap(vars(name), nrow = 2)
plotly::ggplotly(p)

# compare three
comparison <- df_funder_sharing %>% 
  select(.run.number., .step., fund.on.data.history., share.data.,
         mean.grants.groups:sum..total.datasets..of.groups) %>% 
  pivot_longer(-c(.run.number., .step., fund.on.data.history., share.data.)) %>% 
  drop_na()

comparison %>% 
  mutate(experiment = case_when(
    !share.data. & !fund.on.data.history. ~ "no sharing",
    share.data. & !fund.on.data.history. ~ "only sharing",
    share.data. & fund.on.data.history. ~ "share and reward",
    TRUE ~ NA_character_
  )) %>% 
  select(-share.data., -fund.on.data.history.) %>% 
  drop_na() -> comparison

comparison %>% 
  filter(str_detect(name, "gini")) %>% 
  ggplot(aes(.step., value, colour = experiment)) +
  geom_smooth() +
  facet_wrap(vars(name))
# inequality is lowest in system with data sharing and rewarding based on it?
# why?


# datasets
comparison %>% 
  filter(str_detect(name, "count"),
         experiment != "no sharing") %>% 
  ggplot(aes(.step., value, colour = experiment)) +
  geom_point(size = .2) +
  guides(colour = guide_legend(override.aes = list(size = 2)))


p <- comparison %>% 
  filter(str_detect(name, "count"),
         experiment != "no sharing") %>% 
  ggplot(aes(.step., value, colour = experiment, group = .run.number.)) +
  geom_line()
p
plotly::ggplotly(p)

# look at relation between datasets and publications
p <- comparison %>% 
  filter(str_detect(name, "sum\\."),
         experiment != "no sharing") %>% 
  ggplot(aes(.step., value, colour = name, group = .run.number.)) +
  geom_line() +
  facet_wrap(vars(experiment))
plotly::ggplotly(p)


comparison %>% 
  filter(str_detect(name, "sum\\."),
         experiment != "no sharing",
         .step. == 500) %>% 
  pivot_wider() %>% 
  ggplot(aes(sum..total.datasets..of.groups,
             sum..total.primary.publications..of.groups,
             colour = experiment)) +
  geom_point() +
  geom_smooth(span = 1.2)
# positive relationships: more publications also have more datasets
# logical since datsets are derived from publications
# the hit in resources does not seem to counteract this trend



# Q on experiments
# does funding based on history lead to higher concentration? i.e., groups that
# got grants with data sharing tend to get more grants of the same sort?