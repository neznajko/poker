require("dplyr")
require("ggplot2")
require("ggthemes")
attach("time.df")

stat <-time %>%
    group_by(lang, gmez) %>%
    summarise(mean = mean(time), sdev = sd(time))

stat %>% ggplot(aes(gmez, mean, colour = lang)) +
    geom_point() +
    geom_errorbar(aes(ymin = mean - sdev, ymax = mean + sdev)) +
    labs(x = "number of games", y = "time [s]", colour = NULL) +
    theme_wsj() +
    theme(axis.title   = element_text(size  = 12),
          axis.title.x = element_text(hjust = 1))

time %>% filter(gmez == 1000) %>%
    ggplot(aes(time)) +
    geom_histogram(aes(fill = lang),
                   binwidth = .001,
                   colour = "black") +
    labs(x = "time [s]", fill = NULL) +
    theme_economist() +
    scale_colour_economist() +
    theme(axis.title.x = element_text(hjust = 1))
