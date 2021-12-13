# explorations based on detailed experiment from 07-incentives.rmd

pdata <- df_time_clean %>% 
  # run 3 = pubsvsdata=1; run 1 = pubsvsdata=0
  filter(pubs.vs.data == 1, run == 3, data_sharing_perc >= 0) 

pdata %>% 
  ggplot(aes(step, data_grant_share, colour = n_publications)) +
  geom_point(alpha = .5)
  facet_wrap(vars(pubs.vs.data))
  
  

pdata %>% 
  ggplot(aes(step, n_publications)) +
  geom_point(alpha = .2)

pdata %>% 
  ggplot(aes(step, n_publications)) +
  geom_line(aes(group = who), alpha = .5)

# inspect groups that accrue more than 500 publications
performers <- pdata %>% 
  filter(n_publications > 500, step == 500) %>% 
  select(who) %>% 
  left_join(pdata)

performers %>% 
  ggplot(aes(step, n_publications)) +
  geom_line(aes(group = who), alpha = .5)


performers %>% 
  slice_sample(n = 2000) %>% 
  ggplot(aes(step, total_grants)) +
  geom_line(aes(group = who, colour = data_grant_share), alpha = .5,
            size = 1.2) +
  scale_colour_viridis_c(option = "C")
  


