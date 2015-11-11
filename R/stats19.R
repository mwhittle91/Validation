# devtools::install_github("robinlovelace/stplanr")
library(stplanr)

ac <- read_stats19_ac()
ve <- read_stats19_ve()
ca <- read_stats19_ca()


# save all stat19 data in one large table
all_stats19 <- dplyr::inner_join(ve, ca)
all_stats19 <- dplyr::inner_join(all_stats19, ac)


