## 52vis challenges, week 2
## originally seen at
## https://rud.is/b/2016/04/06/52vis-week-2-2016-week-14-honing-in-on-the-homeless/
## this version blogged @ jcarroll.com.au/
## github: github.com/jonocarroll/2016-14

## load relevant packages
pacman::p_load(magrittr, dplyr, tidyr, ggplot2, httr, readxl, purrr, data.table, maptools, broom, ggthemes, ggalt, viridis)
pacman::p_load_gh("hrbrmstr/albersusa")
pacman::p_load_gh("dgrtwo/gganimate")

setwd("jonocarroll")

## load the data from hudexchange.info (download once)
# URL <- "https://www.hudexchange.info/resources/documents/2007-2015-PIT-Counts-by-CoC.xlsx"
# GET(URL, write_disk("homeless.xlsx", overwrite=TRUE))

## load the sheets into a list (by sheet name, a.k.a. year) of data.frames via map
HUDdata <- map(as.character(2007:2015), ~read_excel("homeless.xlsx", sheet=.x)) %>%
  map(function(x) mutate(x, Year=as.integer(sub(".*, ","",names(x)[3])))) %>% ## add a year column to each list element
  map(function(x) setNames(x, sub("(.*),.*","\\1",names(x))))                 ## remove the year from the column names

## bind the list back to a data.frame, leaving entries blank where not supplied (new categories added in 2011)
HUDdataDF <- rbindlist(HUDdata, fill=TRUE) %>% filter(`CoC Name` != "Total")

## change the integers back to integers
HUDdataDF %<>% map_at(c(3:ncol(.)), as.integer) %>% as_data_frame

## add a state column based on the 2-letter prefix of CoC Number
HUDdataDF %<>% mutate(State=substr(`CoC Number`, 1, 2))

## sum the total homeless within each state
## dtop the remaining columns, we'll work with those another time
HUDdataDF %<>%
  select(Year, State, `Total Homeless`) %>%
  group_by(State, Year) %>%
  summarise(nHomeless=sum(`Total Homeless`))

## save a copy so we don't have to do that again
save(HUDdataDF, file="HUDdata_data.frame.RData")

## use the state populations courtesy of hrbrmstr
uspop <- read.csv("../uspop.csv", stringsAsFactors=FALSE)
uspop_long <- gather(uspop, year, population, -name, -iso_3166_2)
uspop_long$year <- as.integer(sub("X", "", uspop_long$year))
HUDdataDF %<>% merge(uspop_long, by.x=c("State", "Year"), by.y=c("iso_3166_2", "year"))

## normalise the total homeless population as a proportion of 1000 persons in the state population
HUDdataDF %<>% group_by(Year, State) %>% mutate(HomelessProp=1e3L*nHomeless/population)

## I needed an excuse to use the albersusa package, this is a good one
us <- usa_composite()
us_map <- tidy(us, region="name")

## merge the us_map data with ours
HUDdataDF %>% merge(us_map, by.x="name", by.y="id") %>% mutate(id=name) -> map_with_data

## build the animated plot
gg <- ggplot()
gg <- gg + labs(subtitle="USA Homeless population scaled by state population",
                caption="Data: https://www.hudexchange.info/resources/documents/2007-2015-PIT-Counts-by-CoC.xlsx")
gg <- gg + geom_map(data=map_with_data, map=us_map,
                    aes(x=long, y=lat, map_id=id, fill=HomelessProp, frame=Year),
                    color="#2b2b2b", size=0.1)
gg <- gg + theme_map()
gg <- gg + coord_proj(us_laea_proj)
gg <- gg + scale_fill_viridis(name="Homeless/1000\npopulation", option="C", limits=c(0,12))
gg <- gg + theme(legend.position=c(0.8, 0.3), legend.key.size=unit(2,"cm"))
gg <- gg + theme(text=element_text(size=30))

## view the animation
gg_animate(gg)

## output the animation
gg_animate(gg, interval=1, ani.width=1800, ani.height=1200, file="HomelessPopulation.gif")
