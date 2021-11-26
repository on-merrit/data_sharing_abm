path <- "../outputs/grant-balance-on-publications-only-end"

df <- read_csv(path, skip = 6) %>% 
  tibble(.name_repair = "universal")

df <- df %>% 
  select(run = .run.number., step = .step., stuff)

df_extracted <- df %>% 
  mutate(stuff = str_remove_all(stuff, "(^\\[\\[)|(\\]\\]$)")) %>% 
  separate(stuff, paste0("group", 1:100), sep = "\\] \\[") %>% 
  pivot_longer(starts_with("group"), names_to = "group", values_to = "vals") %>% 
  separate(vals, c("who", "data_grant_share", "n_publications", "total_grants"),
           sep = "\\s")
  


df_extracted <- df_extracted %>% 
  mutate(across(c("who", "data_grant_share", "n_publications", "total_grants"),
                as.numeric))


df_extracted %>% 
  ggplot(aes(n_publications, data_grant_share)) +
  geom_point()

df_extracted %>% 
  ggplot(aes(total_grants, data_grant_share)) +
  geom_point()

m1 <- lm(n_publications ~ total_grants + data_grant_share,
         data = df_extracted)
summary(m1)


m2 <- lm(n_publications ~ total_grants + data_grant_share + 
           I(data_grant_share^2),
         data = df_extracted)
summary(m2)
