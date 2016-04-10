library(readxl)
library(purrr)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(scales)
library(grid)
library(ggalt)
library(ggrepel)


# grab the HUD homeless data
URL <- "https://www.hudexchange.info/resources/documents/2007-2015-PIT-Counts-by-CoC.xlsx"
fil <- basename(URL)
if (!file.exists(fil)) download.file(URL, fil, mode="wb")

# turn the excel tabs into a long data.frame
yrs <- 2015:2007
names(yrs) <- 1:9
homeless <- map_df(names(yrs), function(i) {
  df <- suppressWarnings(read_excel(fil, as.numeric(i)))
  df[,3:ncol(df)] <- suppressWarnings(lapply(df[,3:ncol(df)], as.numeric))
  new_names <- tolower(make.names(colnames(df)))
  new_names <- str_replace_all(new_names, "\\.+", "_")
  df <- setNames(df, str_replace_all(new_names, "_[[:digit:]]+$", ""))
  bind_cols(df, data_frame(year=rep(yrs[i], nrow(df))))
})

# clean it up a bit
homeless <- mutate(homeless,
                   state=str_match(coc_number, "^([[:alpha:]]{2})")[,2],
                   coc_name=str_replace(coc_name, " CoC$", ""))
homeless <- select(homeless, year, state, everything())
homeless <- filter(homeless, !is.na(state))

# read in the us population data
uspop <- read.csv("uspop.csv", stringsAsFactors=FALSE)
uspop_long <- gather(uspop, year, population, -name, -iso_3166_2)
uspop_long$year <- sub("X", "", uspop_long$year)


# Process the rest of the data with less detail and bind the above back in
states <- homeless %>%
  group_by(year, state) %>%
  summarise_each(funs(sum(., na.rm = TRUE)), total_homeless, sheltered_homeless, unsheltered_homeless, homeless_veterans) %>%
  left_join(albersusa::usa_composite()@data[,3:4], by=c("state"="iso_3166_2")) %>%
  ungroup %>%
  filter(!is.na(name)) %>%
  mutate(year = as.character(year)) %>%
  left_join(uspop_long) %>%
  mutate(total_homeless_per_100k = (total_homeless/population)*100000,
         sheltered_homeless_per_100k = (sheltered_homeless/population)*100000,
         unsheltered_homeless_per_100k = (unsheltered_homeless/population)*100000,
         homeless_veterans_per_100k = (unsheltered_homeless/population)*100000)


#Load in COC funding data
coc_funding <- read_excel(list.files(".", full.names = TRUE, pattern = "CPD-Awards")) %>%
  set_names(tolower(names(.)))

state_funding <- coc_funding %>%
  mutate(year = as.character(year)) %>%
  group_by(year, state) %>%
  summarize(total_funding = sum(`award amount`)) %>%
  filter(year >= 2007)

states <- left_join(states,state_funding) %>%
  mutate(funding = (total_funding/population)*100000) %>%
  filter(year != "2015") %>%
  group_by(state, year) %>%
  arrange

nudges <- data_frame(nudge_x = c(0, 0, 0, 100000, 0, 100000, -100000, 100000), nudge_y = c(-25, -25, -25, 25, -50, 25, -25, -25))

plot_data <- states %>%
  group_by(year) %>%
  summarize_each(
    funs(sum(., na.rm = TRUE)),
    funding,
    total_homeless_per_100k,
    sheltered_homeless_per_100k,
    unsheltered_homeless_per_100k
  ) %>%
  bind_cols(nudges)


# Epoca temporal scatterplot
gg <- ggplot(plot_data, aes(x = funding, y = total_homeless_per_100k))
gg <- gg + ggalt:::geom_xspline2(aes(s_open = TRUE, s_shape = 0.6, size = 8))
gg <- gg + geom_point(aes(group = year), size = 3, pch = 21, fill = "black", color = "white")
gg <- gg + geom_text(aes(label = year, y = total_homeless_per_100k + nudge_y, x = funding + nudge_x), family = "Oswald Light", vjust = "inward")
gg <- gg + scale_x_continuous(labels = scales::dollar, limits = c(21000000,28000000))
gg <- gg + scale_y_continuous(labels = scales::comma, limits = c(9000, 10500))
#gg <- gg + facet_wrap(~name, scales="free", ncol=6)
gg <- gg + labs(x = NULL, y = NULL,
                title="Temporal Scatterplot of US Department of Housing & Urban Development (HUD) Unsheltered (Estimated) Homeless Population contrasted with HUD Continuum of Care Program (CoC) Funding",
                subtitle="Year aggregates calculated from HUD Communities of Care Regional Surveys and CPD Allocations and Awards (both normalized per 100K population)",
                caption="\nHomeless population data from: https://www.hudexchange.info/resource/4832/2015-ahar-part-1-pit-estimates-of-homelessness/\nCoC program Funding data from: https://www.hudexchange.info/grantees/cpd-allocations-awards/")

gg <- gg + theme(text = element_text(family = "Oswald Light", size = 12, color = "grey20"))
gg <- gg + theme(panel.grid.major.y = element_line(colour = "grey80", size = 0.1))
gg <- gg + theme(panel.grid.major.x = element_line(colour = "grey80", size = 0.1))
gg <- gg + theme(legend.position = "none")
gg <- gg + theme(legend.key = element_blank())
gg <- gg + theme(legend.background = element_rect(fill = NA))
gg <- gg + theme(strip.text.y = element_text(angle = 180))
gg <- gg + theme(axis.text.x = element_text(angle = 0, hjust = 0.5, vjust = 0.5))
gg <- gg + theme(axis.ticks.y = element_blank())
gg <- gg + theme(axis.ticks.x = element_blank())
gg <- gg + theme(panel.margin.y = unit(1, "lines"))
gg <- gg + theme(axis.line = element_line())
gg <- gg + theme(panel.border = element_blank())
gg <- gg + theme(panel.background = element_blank())
gg <- gg + theme(strip.background = element_blank())
gg <- gg + theme(plot.background = element_blank())
gg <- gg + theme(plot.subtitle = element_text(hjust = 0))
gg <- gg + theme(plot.caption = element_text(hjust = 1, size = 8, vjust = 1))

gg


