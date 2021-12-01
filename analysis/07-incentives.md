---
title: "Incentives"
author: "Thomas Klebel"
date: "01 Dezember, 2021"
output: 
  html_document:
    keep_md: true
---





```r
df_clean %>% 
  ggplot(aes(data_grant_share, data_sharing_perc, colour = pubs.vs.data)) +
  geom_point(size = 1.5) +
  scale_colour_viridis_c()
```

![](07-incentives_files/figure-html/unnamed-chunk-1-1.png)<!-- -->

```r
# why does the right side not go up higher? is this the base funding that 
# stays stronger for those with not many grants?

p <- df_clean %>% 
  mutate(stats = paste("pubs:", n_publications, "grants:", total_grants)) %>%
  ggplot(aes(data_grant_share, data_sharing_perc, colour = factor(pubs.vs.data),
             label = stats)) +
  geom_point(alpha = .5) +
  scale_colour_viridis_d() 
p
```

![](07-incentives_files/figure-html/unnamed-chunk-1-2.png)<!-- -->



```r
plotly::ggplotly(p)
```

```{=html}
<div id="htmlwidget-eca193526a21779bc164" style="width:840px;height:600px;" class="plotly html-widget"></div>
```



Rewarding based on datasets simply adds more randomness.

```r
df_clean %>% 
  ggplot(aes(data_grant_share, total_grants)) +
  geom_point()  +
  facet_wrap(vars(pubs.vs.data)) +
  labs(title = "Influence of incentive settings")
```

![](07-incentives_files/figure-html/incentives-on-grants-1.png)<!-- -->


# Modeling

```r
browser()
```

```
## Called from: eval(expr, envir, enclos)
```

```r
m1 <- lm(n_publications ~ total_grants + data_grant_share,
         data = df_clean)
summary(m1)
```

```
## 
## Call:
## lm(formula = n_publications ~ total_grants + data_grant_share, 
##     data = df_clean)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -263.678  -11.631    0.196   11.898  215.479 
## 
## Coefficients:
##                    Estimate Std. Error  t value Pr(>|t|)    
## (Intercept)      151.876133   0.742424  204.568   <2e-16 ***
## total_grants       5.863183   0.001378 4255.650   <2e-16 ***
## data_grant_share -12.989140   1.398584   -9.287   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 24.18 on 11997 degrees of freedom
## Multiple R-squared:  0.9993,	Adjusted R-squared:  0.9993 
## F-statistic: 9.055e+06 on 2 and 11997 DF,  p-value: < 2.2e-16
```

```r
m1 <- arm::standardize(m1)
summary(m1)
```

```
## 
## Call:
## lm(formula = n_publications ~ z.total_grants + z.data_grant_share, 
##     data = df_clean)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -263.678  -11.631    0.196   11.898  215.479 
## 
## Coefficients:
##                     Estimate Std. Error  t value Pr(>|t|)    
## (Intercept)         614.4292     0.2207 2784.154   <2e-16 ***
## z.total_grants     1878.4223     0.4414 4255.650   <2e-16 ***
## z.data_grant_share   -4.0994     0.4414   -9.287   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 24.18 on 11997 degrees of freedom
## Multiple R-squared:  0.9993,	Adjusted R-squared:  0.9993 
## F-statistic: 9.055e+06 on 2 and 11997 DF,  p-value: < 2.2e-16
```



```r
m2 <- lm(n_publications ~ total_grants + data_grant_share + 
           I(total_grants^2),
         data = df_clean)
summary(m2)
```

```
## 
## Call:
## lm(formula = n_publications ~ total_grants + data_grant_share + 
##     I(total_grants^2), data = df_clean)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -280.413  -11.818   -0.226   11.676  212.471 
## 
## Coefficients:
##                     Estimate Std. Error  t value Pr(>|t|)    
## (Intercept)        1.532e+02  7.473e-01  205.062   <2e-16 ***
## total_grants       5.819e+00  3.962e-03 1468.861   <2e-16 ***
## data_grant_share  -1.299e+01  1.391e+00   -9.342   <2e-16 ***
## I(total_grants^2)  6.652e-05  5.655e-06   11.764   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 24.04 on 11996 degrees of freedom
## Multiple R-squared:  0.9993,	Adjusted R-squared:  0.9993 
## F-statistic: 6.106e+06 on 3 and 11996 DF,  p-value: < 2.2e-16
```

```r
m2 <- arm::standardize(m2)
summary(m2)
```

```
## 
## Call:
## lm(formula = n_publications ~ z.total_grants + z.data_grant_share + 
##     I(z.total_grants^2), data = df_clean)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -280.413  -11.818   -0.226   11.676  212.471 
## 
## Coefficients:
##                      Estimate Std. Error  t value Pr(>|t|)    
## (Intercept)          612.7223     0.2631 2329.144   <2e-16 ***
## z.total_grants      1867.8216     1.0023 1863.498   <2e-16 ***
## z.data_grant_share    -4.1002     0.4389   -9.342   <2e-16 ***
## I(z.total_grants^2)    6.8281     0.5804   11.764   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 24.04 on 11996 degrees of freedom
## Multiple R-squared:  0.9993,	Adjusted R-squared:  0.9993 
## F-statistic: 6.106e+06 on 3 and 11996 DF,  p-value: < 2.2e-16
```



```r
# m2 fits better, but has too high VIF
car::vif(m2)
```

```
##      z.total_grants  z.data_grant_share I(z.total_grants^2) 
##            5.215605            1.000003            5.215601
```

```r
# so we stick with model 1

# however, there might be an interaction between the share of grants and the
# total number of grants
m3 <- lm(n_publications ~ total_grants*data_grant_share,
         data = df_clean)
m3 <- arm::standardize(m3)
summary(m3)
```

```
## 
## Call:
## lm(formula = n_publications ~ z.total_grants * z.data_grant_share, 
##     data = df_clean)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -256.593  -11.406    0.112   11.768  219.490 
## 
## Coefficients:
##                                    Estimate Std. Error t value Pr(>|t|)    
## (Intercept)                        614.3644     0.2175 2825.01   <2e-16 ***
## z.total_grants                    1877.9822     0.4355 4311.96   <2e-16 ***
## z.data_grant_share                 -36.2906     1.7486  -20.75   <2e-16 ***
## z.total_grants:z.data_grant_share -150.3289     7.9089  -19.01   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 23.82 on 11996 degrees of freedom
## Multiple R-squared:  0.9994,	Adjusted R-squared:  0.9994 
## F-statistic: 6.218e+06 on 3 and 11996 DF,  p-value: < 2.2e-16
```

```r
AIC(m3, m1)
```

```
##    df      AIC
## m3  5 110153.3
## m1  4 110507.3
```

```r
# m3 is clearly better
```



```r
df_nested <- df_clean %>% 
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
```

```
## # A tibble: 6 x 5
## # Groups:   pubs.vs.data [6]
##   pubs.vs.data data                 model  glance            tidy            
##          <dbl> <list>               <list> <list>            <list>          
## 1          0   <tibble [2,000 x 8]> <lm>   <tibble [1 x 12]> <tibble [4 x 7]>
## 2          0.4 <tibble [2,000 x 8]> <lm>   <tibble [1 x 12]> <tibble [4 x 7]>
## 3          0.2 <tibble [2,000 x 8]> <lm>   <tibble [1 x 12]> <tibble [4 x 7]>
## 4          1   <tibble [2,000 x 8]> <lm>   <tibble [1 x 12]> <tibble [4 x 7]>
## 5          0.8 <tibble [2,000 x 8]> <lm>   <tibble [1 x 12]> <tibble [4 x 7]>
## 6          0.6 <tibble [2,000 x 8]> <lm>   <tibble [1 x 12]> <tibble [4 x 7]>
```

```r
df_nested %>% 
  unnest(glance) 
```

```
## # A tibble: 6 x 16
## # Groups:   pubs.vs.data [6]
##   pubs.vs.data data             model r.squared adj.r.squared sigma statistic p.value    df logLik    AIC    BIC deviance
##          <dbl> <list>           <lis>     <dbl>         <dbl> <dbl>     <dbl>   <dbl> <dbl>  <dbl>  <dbl>  <dbl>    <dbl>
## 1          0   <tibble [2,000 ~ <lm>      0.999         0.999  23.9   598222.       0     3 -9187. 18384. 18412. 1143973.
## 2          0.4 <tibble [2,000 ~ <lm>      0.999         0.999  23.0  1146585.       0     3 -9109. 18228. 18256. 1058188.
## 3          0.2 <tibble [2,000 ~ <lm>      0.999         0.999  23.0   925979.       0     3 -9105. 18221. 18249. 1054267.
## 4          1   <tibble [2,000 ~ <lm>      0.999         0.999  24.4  1187276.       0     3 -9229. 18468. 18496. 1193081.
## 5          0.8 <tibble [2,000 ~ <lm>      0.999         0.999  23.0  1273910.       0     3 -9104. 18219. 18247. 1053287.
## 6          0.6 <tibble [2,000 ~ <lm>      0.999         0.999  24.6  1167053.       0     3 -9242. 18494. 18522. 1208455.
## # ... with 3 more variables: df.residual <int>, nobs <int>, tidy <list>
```

```r
# plot it
dummy_data <- tibble(
  total_grants = rep(1:50, 5),
  data_grant_share = rep(c(0, .25, .5, .75, 1), each = 50)
)

df_nested %>% 
  mutate(new_data = list(dummy_data)) %>% 
  mutate(prediction = map2(model, new_data, ~broom::augment(.x, newdata = .y))) %>% 
  unnest(prediction) %>% 
  ggplot(aes(total_grants, .fitted, colour = as.factor(data_grant_share))) +
  geom_line() +
  geom_point() +
  facet_wrap(vars(pubs.vs.data)) +
  labs(y = "Predicted number of publications",
       colour = "% of grants mandating data sharing",
       title = "Productivity depending on data sharing incentives") +
  theme(legend.position = "top")
```

![](07-incentives_files/figure-html/unnamed-chunk-6-1.png)<!-- -->

As you incentivise data sharing this way, those groups that actually solely 
get funded by funders mandating OD fare worse than others.

explanation for the lower inequality in the system: actors get disadvantaged
and therefore randomness takes a larger share of the system


important to note: early on there seems to be an advantage, but it quickly
goes away and turns into a disadvantage.

so the interesting thing could be to give agents strategies (always share data
if last n grants had data sharing, so to have a longer term effect, vs maybe 
also simply directly adhering), and then to see which share of funders mandating
data we need to see a change.

also, maybe having those that always share data, and seeing how they are 
affected 

