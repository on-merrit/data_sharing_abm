library(tidyverse)
library(readxl)
library(ineq)

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


leiden_select %>% 
  summarise(gini = Gini(impact_P))


# visualise lotkas or zipfs law
# https://en.wikipedia.org/wiki/Zipf%27s_law
# https://en.wikipedia.org/wiki/Lotka%27s_law
leiden_select %>% 
  filter(Period == "2015–2018") %>% 
  mutate(uni_rank = rank(impact_P)) %>% 
  ggplot(aes(uni_rank, impact_P)) +
  geom_point()


leiden_select %>% 
  filter(Period == "2015–2018") %>% 
  mutate(uni_rank = rank(impact_P),
         uni_rank = max(uni_rank) - uni_rank + 1) %>% 
  ggplot(aes(uni_rank, impact_P)) +
  geom_point() +
  scale_y_log10() +
  scale_x_log10()

# this does not work
leiden_select %>% 
  filter(Period == "2015–2018") %>% 
  mutate(uni_rank = rank(impact_P),
         uni_rank = max(uni_rank) - uni_rank + 1) %>% 
  ggplot(aes(uni_rank, impact_P)) +
  geom_point() +
  geom_point(aes(y = 1/uni_rank), colour = "red") +
  scale_y_log10() +
  scale_x_log10()


# group sizes -----
df_groups <- read_delim("group_sizes.txt", delim = " ", skip = 2, 
                        col_names = c("id", "n_researchers", 
                                      "n_publications"),
                        col_types = "cii-")

df_groups %>% 
  ggplot(aes(n_publications)) +
  geom_histogram(bins = 20)
ggsave("plots/group_productivity.png")

df_groups %>% 
  ggplot(aes(n_publications)) +
  geom_density()

df_groups %>% 
  ggplot(aes(n_researchers, n_publications)) +
  geom_point() +
  geom_smooth(method = "lm") +
  annotate("text", x = 5, y = 450,
           label = paste0(
             "cor = ", round(cor(df_groups$n_publications, 
                                 df_groups$n_researchers), 2)
           ))
ggsave("plots/size_vs_productivity.png")

# gini
df_groups %>% 
  summarise(gini = Gini(n_publications))
  