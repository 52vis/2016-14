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


# Load in COC funding data
coc_funding <- read_excel(list.files(".", full.names = TRUE, pattern = "CPD-Awards")) %>%
  set_names(tolower(names(.)))

state_funding <- coc_funding %>%
  mutate(year = as.character(year)) %>%
  group_by(year, state) %>%
  summarize(total_funding = sum(`award amount`)) %>%
  filter(year >= 2007)

states <- left_join(states,state_funding) %>%
  mutate(funding_per_100k = (total_funding/population)*100000) %>%
  filter(year != "2015") %>%
  group_by(state, year) %>%
  arrange

group_by(states, name) %>%
  summarise(mean=mean(funding_per_100k, na.rm=TRUE)) %>%
  arrange(desc(mean)) -> ordr




nudges <- data_frame(nudge_x = c(0, 0, 0, 100000, -10000000, 10000000, -10000000, 100000), nudge_y = c(-2500, -2500, -2500, 3500, 0, 0, -2500, -2500))

national <- states %>%
  group_by(year) %>%
  summarize_each(
    funs(sum(., na.rm = TRUE)),
    funding_per_100k,
    total_funding,
    total_homeless,
    total_homeless_per_100k,
    sheltered_homeless_per_100k,
    unsheltered_homeless_per_100k
  ) %>%
  bind_cols(nudges)

states$name <- factor(states$name, levels=ordr$name)



# Epoca temporal scatterplot
# All credit for this style of plot goes to Epoca Magzine & Alberto Cairo
# Cairo, Alberto. The Functional Art: An introduction to information graphics and visualization. New Riders, 2012.
# National Level
#+ national fig.retina=2, fig.width=12, fig.height=8
gg <- ggplot(national, aes(x = total_funding, y = total_homeless))
gg <- gg + ggalt:::geom_xspline2(aes(s_open = TRUE, s_shape = 0.6, size = 8))
gg <- gg + geom_point(aes(group = year), size = 3, pch = 21, fill = "black", color = "white")
gg <- gg + geom_text(aes(label = year, y = total_homeless + nudge_y, x = total_funding + nudge_x), family = "Oswald Light")
gg <- gg + scale_x_continuous(labels = scales::dollar, limits = c(1300000000,1790000000))
gg <- gg + scale_y_continuous(labels = scales::comma, limits = c(565000, 650000))
gg <- gg + labs(x = NULL, y = NULL,
                title="Temporal Scatterplot of US Department of Housing & Urban Development (HUD) Unsheltered (Estimated) Homeless Population\ncontrasted with HUD Continuum of Care Program (CoC) Funding",
                subtitle="Aggregates calculated from HUD Communities of Care Regional Surveys and CPD Allocations and Awards",
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
gg <- gg + theme(plot.margin=margin(10, 20, 10, 15))



# State level Small Multiple ----
#+ state fig.retina=2, fig.width=12, fig.height=20
sm <- ggplot(states, aes(x = funding_per_100k, y = total_homeless_per_100k))
sm <- sm + ggalt:::geom_xspline2(aes(s_open = TRUE, s_shape = 0.6, size = 8))
sm <- sm + geom_point(aes(group = year), pch = 21, fill = "black", color = "white")
sm <- sm + geom_label(aes(label = year, y = total_homeless_per_100k, x = funding_per_100k), color = "black", fill = "white", size = 2, family = "Oswald Light", label.size = 0, label.padding = unit(0.1, "lines"), data = filter(states, year %in% c("2007","2014")))
sm <- sm + scale_x_continuous(labels = scales::dollar, breaks = scales::pretty_breaks(n = 3))
sm <- sm + scale_y_continuous(labels = scales::comma, breaks = scales::pretty_breaks(n = 5))
sm <- sm + facet_wrap(~name, scales="free", ncol=4)
sm <- sm + labs(x = NULL, y = NULL,
                title="Temporal Scatterplots of US Department of Housing & Urban Development (HUD) Unsheltered (Estimated) Homeless Population\ncontrasted with HUD Continuum of Care Program (CoC) Funding",
                subtitle="Aggregates calculated from HUD Communities of Care Regional Surveys and CPD Allocations and Awards (normalized per 100k population)",
                caption="\nHomeless population data from: https://www.hudexchange.info/resource/4832/2015-ahar-part-1-pit-estimates-of-homelessness/\nCoC program Funding data from: https://www.hudexchange.info/grantees/cpd-allocations-awards/")

sm <- sm + theme(text = element_text(family = "Oswald Light", size = 8, color = "grey20"))
sm <- sm + theme(panel.grid.major.y = element_line(colour = "grey80", size = 0.1))
sm <- sm + theme(panel.grid.major.x = element_line(colour = "grey80", size = 0.1))
sm <- sm + theme(legend.position = "none")
sm <- sm + theme(legend.key = element_blank())
sm <- sm + theme(legend.background = element_rect(fill = NA))
sm <- sm + theme(strip.text.y = element_text(angle = 180))
sm <- sm + theme(axis.text.x = element_text(angle = 0, hjust = 0.5, vjust = 0.5))
sm <- sm + theme(axis.ticks.y = element_blank())
sm <- sm + theme(axis.ticks.x = element_blank())
sm <- sm + theme(panel.margin.y = unit(1, "lines"))
sm <- sm + theme(axis.line = element_line())
sm <- sm + theme(panel.border = element_blank())
sm <- sm + theme(panel.background = element_blank())
sm <- sm + theme(strip.background = element_blank())
sm <- sm + theme(plot.background = element_blank())
sm <- sm + theme(plot.subtitle = element_text(hjust = 0))
sm <- sm + theme(plot.caption = element_text(hjust = 1, size = 8, vjust = 1))
sm <- sm + theme(plot.margin=margin(10, 20, 10, 15))

# Bonus plotly national ----
plot_ly(
  national,
  x = scales::dollar(total_funding),
  y = total_homeless,
  hoverinfo = "text",
  text = sprintf(
    "National CoC Funding = <b>%s</b><br>National Homeless Population = <b>%s</b>",
    scales::dollar(national$total_funding),
    scales::comma(national$total_homeless)
  ),
  mode = "markers",
  showlegend = FALSE,
  marker = list(color = toRGB("grey20"))
) %>%
  add_trace(
    x = total_funding,
    y = total_homeless,
    line = list(shape = "spline", color = toRGB("grey20")),
    showlegend = FALSE,
    hoverinfo = "none"
  ) %>%
  add_trace(
    text = year,
    x = total_funding + nudge_x,
    y = total_homeless + nudge_y,
    mode = "text",
    showlegend = FALSE,
    hoverinfo = "none"
  ) %>%
  config(displayModeBar = F) %>%
  layout(
    xaxis = list(title = "Total CoC Funding ($)"),
    yaxis = list(title = "Total Homeless Population<br>"),
    title = 'Temporal Scatterplot of US Department of Housing & Urban Development (HUD) Unsheltered (Estimated) Homeless Population contrasted with HUD Continuum of Care Program (CoC) Funding',
    font = list(family = "Oswald-Light", size = 14),
    autosize = T,
    width = 1600,
    height = 1000,
    margin =list(
      l = 75,
      r = 75,
      b = 100,
      t = 100,
      pad = 4
    )
  )

# Bonus plotly states ----

plots <- function(df){

  p <- plot_ly(
    df,
    x = funding_per_100k,
    y = total_homeless_per_100k,
    group = state,
    hoverinfo = "text",
    text = sprintf(
      "Year: <b>%s</b><br>National CoC Funding = <b>%s</b><br>National Homeless Population = <b>%s</b>",
      states$year,
      scales::dollar(states$funding_per_100k),
      scales::comma(states$total_homeless_per_100k)
    ),
    mode = "markers",
    showlegend = FALSE,
    marker = list(color = toRGB("grey20"))
  ) %>%
    add_trace(
      x = funding_per_100k,
      y = total_homeless_per_100k,
      xaxis = list(title = ""),
      yaxis = list(title = ""),
      group = state,
      line = list(shape = "spline", color = toRGB("grey20")),
      showlegend = FALSE,
      hoverinfo = "none"
    ) %>%
    layout(xaxis = list(title = paste(unique(name))),
           yaxis = list(title = ""))

  return(p)
}

plots <- dlply(states, .(state), plots)

options <- list(nrows=12)

do.call(subplot,  c(plots,options)) %>%
  config(displayModeBar = F) %>%
  layout(
    autosize = T,
    width = 1600,
    height = 2000,
    margin =list(l = 50, r = 50, b = 50, t = 50, pad = 4),
    title = 'Temporal Scatterplot of US Department of Housing & Urban Development (HUD) Unsheltered (Estimated) Homeless Population contrasted with HUD Continuum of Care Program (CoC) Funding',
    font = list(family = "Oswald-Light", size = 12))


