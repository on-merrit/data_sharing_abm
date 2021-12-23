beta0 <- 0
beta <- 1
x <- c(5, 2, 0, -2, 2*log(3))

# 1/(1 + exp(-beta0 - beta * x))
1/(1 + exp(-x))
1/(1 + exp(0))


1/(1 + exp(2/2))

1/(1 + exp(-1 + 1/(5 * 2)))


1/(1 + exp(0 - .5 + 1.5))


# modulo to determine which round we are in
library(tidyverse)

tibble(x = 1:10) %>% 
  mutate(mod2 = x %% 2,
         mod3 = x %% 3,
         mod7 = x %% 7)

         