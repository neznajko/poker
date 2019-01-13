require("dplyr")
require("ggplot2")

attach("time.df")

stat <-time %>%
    group_by(lang, gmez) %>%
    summarise(mean = mean(time), sdev = sd(time))

stat %>% ggplot(aes(gmez, mean, color = lang)) +
    geom_point() +
    geom_errorbar(aes(ymin = mean - sdev, ymax = mean + sdev))

time %>% filter(gmez == 1000) %>%
    ggplot(aes(time)) +
    geom_histogram(aes(fill = lang), binwidth = .001)
