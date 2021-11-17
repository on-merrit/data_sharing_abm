library(tidyverse)

df_reuse <- read_csv("../outputs/data_sharing data-reuse-table.csv", skip = 6) %>% 
  tibble(.name_repair = "universal") %>% 
  mutate(across(contains("gini"), as.numeric))
  
extrafont::loadfonts(device = "win")
theme_set(hrbrthemes::theme_ipsum_rc(base_family = "Hind"))

# data vs other publications
df_reuse %>% 
  select(.step., n.available.grants, mean.default.publications.groups, 
         mean.data.publications.groups) %>% 
  pivot_longer(contains("groups")) %>% 
  mutate(type = str_extract(name, "(?<=mean\\.).*?(?=\\.)"),
         type = recode(type, default = "Primary research publications",
                       data = "Data reuse publications"),
         .step. = .step. / 2) %>% 
  ggplot(aes(.step., value, colour = factor(n.available.grants))) +
  geom_smooth() +
  facet_wrap(vars(type)) +
  theme(legend.position = "top") +
  labs(x = "Years", y = "# of publications", 
       colour = "# of available grants per 6 months",
       title = "Extent of primary and reuse publications",
       caption = "n = 100 agents") +
  guides(colour = guide_legend(nrow = 1))
ggsave("plots/primary_vs_reuse_publications.png", width = 8, height = 5)
