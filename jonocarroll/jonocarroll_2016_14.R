## 52vis challenges, week 2
## originally seen at
## https://rud.is/b/2016/04/06/52vis-week-2-2016-week-14-honing-in-on-the-homeless/
## this version blogged @ http://jcarroll.com.au/2016/04/10/52vis-week-2-challenge/
## github: github.com/jonocarroll/2016-14

## This script produces a chloropleth for the USA homeless population
## as a per mille proportion of each state's population, with the
## colorscale set to white at the national median, blue at the
## lowest value, and capped at 3x the national median in red.
## The yearly data is looped over in a .gif

## load relevant packages
pacman::p_load(magrittr, dplyr, tidyr, ggplot2, httr, readxl, purrr)
pacman::p_load(data.table, maptools, broom, ggthemes, ggalt, viridis)
pacman::p_load_gh("hrbrmstr/albersusa")
pacman::p_load_gh("dgrtwo/gganimate")

## git repository 2016-14 forked from https://github.com/52vis/2016-14.git
## and new folder created
setwd("jonocarroll")

## load the data from hudexchange.info (download once)
# URL <- "https://www.hudexchange.info/resources/documents/2007-2015-PIT-Counts-by-CoC.xlsx"
# GET(URL, write_disk("homeless.xlsx", overwrite=TRUE))

## load the sheets into a list (by sheet name, a.k.a. year) of data.frames via map
HUDdata <- map(as.character(2007:2015), ~read_excel("homeless.xlsx", sheet=.x)) %>%
  map(function(x) mutate(x, Year=as.integer(sub(".*, ","",names(x)[3])))) %>% ## add a year column to each list element
  map(function(x) setNames(x, sub("(.*),.*","\\1",names(x))))                 ## remove the year from the column names

## bind the list back to a data.frame, leaving entries blank where not supplied (new categories added in 2011)
HUDdataDF <- rbindlist(HUDdata, fill=TRUE) %>% filter(`CoC Name`!="Total")

## change the integers back to integers
HUDdataDF %<>% map_at(c(3:ncol(.)), as.integer) %>% as_data_frame

## add a state column based on the 2-letter prefix of CoC Number
HUDdataDF %<>% mutate(State=substr(`CoC Number`, 1, 2))

## save a copy so we don't have to do that again
save(HUDdataDF, file="HUDdata_data.frame_2016-14.RData")

## sum the total homeless within each state
## drop the remaining columns, we'll work with those another time
HUDdataDF %<>%
  select(Year, State, `Total Homeless`) %>%
  group_by(State, Year) %>%
  summarise(nHomeless=sum(`Total Homeless`))

## use the state populations courtesy of hrbrmstr
uspop <- read.csv("../uspop.csv", stringsAsFactors=FALSE)
uspop_long <- gather(uspop, year, population, -name, -iso_3166_2)
uspop_long$year <- as.integer(sub("X", "", uspop_long$year))
HUDdataDF %<>% merge(uspop_long, by.x=c("State", "Year"), by.y=c("iso_3166_2", "year"))

## normalise the total homeless population as a proportion of 1000 persons (per mille) in each state population
HUDdataDF %<>% group_by(Year, State) %>% mutate(HomelessProp=1e3L*nHomeless/population)

## I needed an excuse to us the albersusa package, this is a good one
us <- usa_composite()
us_map <- tidy(us, region="name")

## merge the us_map data with ours
map_with_data <- HUDdataDF %>% merge(us_map, by.x="name", by.y="id") %>% mutate(id=name)

## make more than 3x the median value as a 'plus' group
## NB: this doesn't affect the median value
map_with_data$HomelessProp[map_with_data$HomelessProp > 3*median(map_with_data$HomelessProp, na.rm=TRUE)] <- 3*median(map_with_data$HomelessProp, na.rm=TRUE)

## save a copy so we don't have to do that again
save(map_with_data, file="map_with_data_2016-14.RData")

## build the animated plot
gg <- ggplot(map_with_data)
gg <- gg + labs(subtitle=paste0("USA Homeless population scaled by state population,\ncapped at 3x national median (",
                                format(3*median(map_with_data$HomelessProp, na.rm=TRUE), digits=3),"/1000)"),
                caption="Data: https://www.hudexchange.info/resources/documents/2007-2015-PIT-Counts-by-CoC.xlsx  ")
gg <- gg + geom_map(map=us_map,
                    aes(x=long, y=lat, map_id=id, fill=HomelessProp, frame=Year),
                    color="#2b2b2b", size=0.1)
gg <- gg + theme_map()
gg <- gg + coord_proj(us_laea_proj)
gg <- gg + scale_fill_gradient2(name="Homeless\npopulation \u2030",
                                low="steelblue", high="firebrick",
                                midpoint=median(map_with_data$HomelessProp, na.rm=TRUE),
                                limits=range(map_with_data$HomelessProp, na.rm=TRUE),
                                breaks=c(0,1,2,3,4),
                                labels=c("0","1","2","3","4+"))
gg <- gg + theme(legend.position=c(0.86, 0.3), legend.key.size=unit(2,"cm"))
gg <- gg + theme(text=element_text(size=30, family="Arial Narrow"))

## view the animation
gg_animate(gg)

## output the animation
gg_animate(gg, interval=1, ani.width=1600, ani.height=1200, file="HomelessPopulation.gif")

## optimise the gif using Imagemagick
system("convert HomelessPopulation.gif -fuzz 10% -layers OptimizePlus -layers OptimizeTransparency HomelessPopulation_optim.gif")
