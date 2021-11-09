library(tidyverse)

df <- read_csv("../outputs/data_sharing experiment-table.csv", skip = 6)

theme_set(theme_bw())


# baseline stuff ----
baseline_grants <- df %>% 
  filter(!`share-data?`) %>% 
  select(run_number = `[run number]`, mechanism, step = `[step]`, 
         contains("grants")) %>% 
  pivot_longer(contains("grants")) %>% 
  filter(step < 1000)


baseline_grants %>% 
  ggplot(aes(step, value, colour = mechanism)) +
  geom_line(aes(group = run_number), alpha = .2) +
  geom_smooth() +
  labs(y = "mean number of grants")
ggsave("plots/baseline_grants.png")


baseline_publications <- df %>% 
  filter(!`share-data?`) %>% 
  select(run_number = `[run number]`, mechanism, step = `[step]`, 
         contains("publications")) %>% 
  pivot_longer(contains("publications")) %>% 
  filter(step < 1000)


baseline_publications %>% 
  ggplot(aes(step, value, colour = mechanism)) +
  geom_line(aes(group = run_number), alpha = .2) +
  geom_smooth() +
  labs(y = "mean number of publications")
ggsave("plots/baseline_publications.png")


# data sharing ----
sharing_grants <- df %>% 
  filter(`share-data?`, mechanism == "grant-history") %>% 
  select(run_number = `[run number]`, step = `[step]`, 
         contains("grants")) %>% 
  pivot_longer(contains("grants")) %>% 
  mutate(sharing_data = !str_detect(name, "not")) %>% 
  # filter(step < 1000) %>% 
  select(-name)

sharing_grants %>% 
  ggplot(aes(step, value, colour = sharing_data)) +
  # geom_line(aes(group = run_number), alpha = .2)
  geom_smooth() +
  labs(y = "Avg. of Mean number of grants",
       colour = "Agents have data sharing policy?") +
  theme(legend.position = "top")
ggsave("plots/data_sharing_grants.png")

sharing_publications <- df %>% 
  filter(`share-data?`, mechanism == "grant-history") %>% 
  select(run_number = `[run number]`, step = `[step]`, 
         contains("publications")) %>% 
  pivot_longer(contains("publications")) %>% 
  mutate(sharing_data = !str_detect(name, "not")) %>% 
  # filter(step < 1000) %>% 
  select(-name)

sharing_publications %>% 
  ggplot(aes(step, value, colour = sharing_data)) +
  geom_smooth() +
  labs(y = "Avg. of Mean number of publications",
       colour = "Agents have data sharing policy?") +
  theme(legend.position = "top")
ggsave("plots/data_sharing_publications.png")
