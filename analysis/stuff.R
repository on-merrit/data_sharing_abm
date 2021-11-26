path <- "../outputs/grant-balance-on-publications-only-end"

df_extracted <- read_nested_experiment(path)


df_extracted <- df_extracted %>% 
  select(run, step, who:total_grants)

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


# also simply look at publication distributions
df_extracted %>% 
  ggplot(aes(n_publications, group = run)) +
  geom_density()

df_extracted %>% 
  group_by(run) %>% 
  summarise(ginis = ineq::Gini(n_publications)) %>% 
  ggplot(aes(ginis)) +
  geom_density()
# distribution of ginis


# now look at the two settings (funding based on history or not)
df_rewards <- read_nested_experiment(
  "../outputs/data_sharing benefit-of-awarding-data-sharing-table.csv"
)

df_rewards <- df_rewards %>% 
  select(run, pubs.vs.data, step, who:total_grants)
df_rewards

df_rewards %>% 
  ggplot(aes(n_publications, group = run, fill = pubs.vs.data)) +
  geom_density(alpha = .2)

df_rewards %>% 
  ggplot(aes(n_publications, group = pubs.vs.data, colour = pubs.vs.data)) +
  geom_density(alpha = .5)

df_rewards %>% 
  ggplot(aes(data_grant_share, group = run, colour = pubs.vs.data)) +
  geom_density(alpha = .5)

df_rewards %>% 
  ggplot(aes(data_grant_share, colour = factor(pubs.vs.data), 
             group = pubs.vs.data)) +
  geom_density(alpha = .2, adjust = 1.5)
# it seems the distribution is fatter for more weight on data sharing
# this effect might be stronger if we had more funders. maybe we would then have
# a separation? hard to say, because simulation would likely be very slow
# would need to profile
