library(dplyr)
library(ggplot2)
library(extrafont)
library(readr)
library(readxl)
library(stringr)
library(grid)
library(gridExtra)

# get homelessness data from HUD
homeless <- read_excel("2007-2015-PIT-Counts-by-CoC.xlsx", sheet = 1)

# select CoC number, total homeless, youth homeless
homeless <- tbl_df(homeless) %>% select(1, 3, 24)
names(homeless) <- c("number", "total", "youth")

# get substring with just 2-letter state abbreviation
homeless <- homeless %>% mutate(state = str_sub(number, 1, 2))

# aggregate by state
states <- homeless %>%
  group_by(state) %>%
  summarize(total_sum = sum(total),
            youth_sum = sum(youth))

# get state populations
state_pops <- read_csv("uspop.csv")
state_pops <- state_pops %>% select(1, 2, 18)
names(state_pops) <- c("name", "abbr", "pop")

# get youth populations
youth_pops <- read_csv("PEP_2014_PEPAGESEX_with_ann.csv", skip = 1)
youth_pops <- youth_pops %>% select(3, 43, 64, 85, 106, 127)
names(youth_pops) <- c("name", "under_5", "a5_9", "a10_14", "a15_19", "a20_24")
youth_pops <- tbl_df(youth_pops) %>%
  group_by(name) %>%
  mutate(youth_pop = sum(under_5, a5_9, a10_14, a15_19, a20_24))

# join states, state_pops, and youth_pops
rates <- left_join(state_pops, states, by = c("abbr" = "state"))
rates <- left_join(rates, select(youth_pops, name, youth_pop), by = "name")

# calculate rates per 100k
rates <- rates %>% mutate(total_rate = total_sum / pop * 100000,
                 youth_rate = youth_sum / youth_pop * 100000)

# make copy, extract name, rates to prep for graphing
rate2 <- rates
rate2 <- transform(rate2, name = reorder(name, total_rate))
rate2 <- rate2 %>% select(name, total_rate, youth_rate)

# melt for ggplot
rate_melt <- gather(rate2, key = name, value = val)
# clearly don't know how to use gather properly
names(rate_melt)[2] <- "measure"

# get custom fonts
font_import()

# base plot
hplot <- ggplot(rate_melt, aes(x = name, y = val, color = measure)) + 
  geom_point() + 
  labs(y = "Homelessness rate per 100,000 residents", 
       x = NULL,
       caption = "Source: US Department of Housing & Urban Development") + 
  ggtitle("Point-in-time rates of overall and youth homelessness, 2015") +
  scale_color_manual(guide = guide_legend(title = NULL), 
                     labels = c("All residents", "Youth under 25"),
                     values = c("#444444", "#6885cf")) + 
  coord_flip() + 
  expand_limits(y = 1200) +
  scale_y_continuous(breaks = seq(0, 1200, 200))

# get pretty
hplot <- hplot + theme(text = element_text(family = "Gill Sans"), 
              panel.background = element_rect(fill = "#f6f6f6"), 
              legend.position = "bottom",
              panel.grid.major = element_line(color = "#a9a9a9"),
              panel.grid.major.x = element_line(linetype = "dotted"),
              panel.grid.minor = element_blank())
# hplot

# make a caption for source using gridExtra
caption <- textGrob("Source: US Department of Housing & Urban Development", 
                    gp = gpar(fontsize = 8, fontfamily = "Gill Sans"), 
                    hjust = 0)
final <- grid.arrange(hplot, bottom = caption)
