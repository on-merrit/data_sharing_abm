library(arm)
library(tidyverse)


# now look at the two settings (funding based on history or not)
df_rewards <- read_nested_experiment(
  "../outputs/data_sharing benefit-of-awarding-data-sharing-table.csv"
)

df_rewards <- df_rewards %>% 
  select(run, pubs.vs.data, step, who:total_grants) %>% 
  mutate(data_sharing_perc = n_pubs_with_data_shared / n_publications)
df_rewards

df_rewards %>% 
  ggplot(aes(data_grant_share, n_publications)) +
  geom_point() +
  facet_wrap(vars(pubs.vs.data))

df_rewards %>% 
  ggplot(aes(data_grant_share, total_grants)) +
  geom_point()  +
  facet_wrap(vars(pubs.vs.data))

# maybe also look at the rate of data publications of individual groups?
df_rewards %>% 
  ggplot(aes(data_grant_share, total_grants, colour = data_sharing_perc)) +
  geom_point()  +
  facet_wrap(vars(pubs.vs.data)) +
  scale_color_viridis_c()

# plot data sharing percent directly
df_rewards %>% 
  ggplot(aes(data_sharing_perc)) +
  geom_density()

df_rewards %>% 
  ggplot(aes(data_grant_share, data_sharing_perc, colour = pubs.vs.data)) +
  geom_point(size = 1.5) +
  scale_colour_viridis_c()
# why does the right side not go up higher? is this the base funding that 
# stays stronger for those with not many grants?

p <- df_rewards %>% 
  mutate(stats = paste("pubs:", n_publications, "grants:", total_grants)) %>%
  ggplot(aes(data_grant_share, data_sharing_perc, colour = factor(pubs.vs.data),
             label = stats)) +
  geom_point(alpha = .5) +
  scale_colour_viridis_d() 
p

plotly::ggplotly(p)

df_rewards %>% 
  ggplot(aes(data_sharing_perc, n_publications)) +
  geom_point()

df_rewards %>% 
  ggplot(aes(n_publications, data_sharing_perc)) +
  geom_point()  

df_rewards %>% 
  ggplot(aes(n_publications, data_sharing_perc)) +
  geom_point() +
  facet_wrap(vars(pubs.vs.data))



m1 <- lm(n_publications ~ total_grants + data_grant_share,
         data = df_rewards)
summary(m1)
m1 <- standardize(m1)
summary(m1)


m2 <- lm(n_publications ~ total_grants + data_grant_share + 
           I(total_grants^2),
         data = df_rewards)
summary(m2)
m2 <- standardize(m2)
summary(m2)


# m2 fits better, but has too high VIF
car::vif(m2)
# so we stick with model 1

# however, there might be an interaction between the share of grants and the
# total number of grants
m3 <- lm(n_publications ~ total_grants*data_grant_share,
         data = df_rewards)
m3 <- arm::standardize(m3)
summary(m3)
AIC(m3, m1)
# m3 is clearly better


# now do this across values of pubs.vs.data
df_nested <- df_rewards %>% 
  group_by(pubs.vs.data) %>% 
  nest()

modeling_fun <- function(df) {
  m <- lm(n_publications ~ total_grants*data_grant_share,
     data = df)
  m
}

df_nested <- df_nested %>% 
  mutate(model = map(data, modeling_fun),
         glance = map(model, broom::glance),
         tidy = map(model, broom::tidy, conf.int = TRUE))
df_nested  

df_nested %>% 
  unnest(glance)

df_nested %>% 
  select(pubs.vs.data, tidy) %>% 
  unnest(tidy) %>% 
  filter(str_detect(term, ":")) %>% 
  ggplot(aes(factor(pubs.vs.data), estimate)) +
  # geom_point()
  geom_pointrange(aes(ymin = conf.low, ymax = conf.high))

# what does this mean again?
# it means that as we "incentivise" data sharing by considering it in the 
# funding process, those that have a high share of grants mandating data sharing
# are at a disadvantage
# the above was true without interaction
# 
# how to interpret the interaction?

# plot it
dummy_data <- tibble(
  total_grants = rep(1:50, 5),
  data_grant_share = rep(c(0, .25, .5, .75, 1), each = 50)
)

df_nested %>% 
  mutate(new_data = list(dummy_data)) %>% 
  mutate(prediction = map2(model, new_data, ~broom::augment(.x, .y)))

df_nested %>% 
  filter(pubs.vs.data == .2) %>% 
  pull(model) %>% 
  .[[1]] %>% 
  broom::augment(newdata = dummy_data) %>% 
  ggplot(aes(total_grants, .fitted, colour = as.factor(data_grant_share))) +
  geom_line() +
  geom_point()
# do the same as above for all values of pubs vs data, and explain it
# important to mention: early on there seems to be an advantage, but it quickly
# goes away and turns into a disadvantage
# so the interesting thing could be to give agents strategies (always share data
# if last n grants had data sharing, so to have a longer term effect, vs maybe 
# also simply directly adhering), and then to see which share of funders mandating
# data we need to see a change.
# also, maybe having those that always share data, and seeing how they are 
# affected 
# # explanation for the lower inequality in the system: actors get disadvantaged
# and therefore randomness takes a larger share of the system


df_nested %>% 
  filter(pubs.vs.data == 0) %>% 
  pull(model) %>% 
  .[[1]] %>% 
  summary()

df_nested %>% 
  filter(pubs.vs.data == 1) %>% 
  pull(model) %>% 
  .[[1]] %>% 
  summary()
  


summarise(model = lm(n_publications ~ total_grants + data_grant_share + 
                       I(total_grants^2)), data = .)

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


