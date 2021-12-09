---
title: "Calibration"
author: "Thomas Klebel"
date: "09 Dezember, 2021"
output: 
  html_document:
    keep_md: true
---





```r
leiden %>% 
  ggplot(aes(impact_P)) +
  geom_histogram() +
  facet_wrap(vars(Period))
```

```
## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.
```

![](01-calibration_files/figure-html/leiden-1.png)<!-- -->

```r
# fix x axis
# add gini per facet
# label axes
```

