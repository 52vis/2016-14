#### Rud.Is Challenge #2
# https://github.com/52vis/2016-14
# https://rud.is/b/2016/04/06/52vis-week-2-2016-week-14-honing-in-on-the-homeless/

## `````````````````````````````````````````````
## Load Libraries ####

# only install if not already done
# http://stackoverflow.com/questions/4090169/elegant-way-to-check-for-missing-packages-and-install-them
list.of.packages <- c("ggplot2", "showtext", "grid","ggalt","ggthemes","readxl","hrbrmisc","stringr","virdis","purrr","dplyr","tidyr","scales","albersusa")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(ggplot2)
library(grid)
library(ggalt)
library(readxl)
library(hrbrmisc)
library(stringr)
library(purrr)
library(dplyr)
library(tidyr)
library(scales)
devtools::install_github("hrbrmstr/albersusa")
## `````````````````````````````````````````````

## `````````````````````````````````````````````
## Scraping Data ####
## `````````````````````````````````````````````
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
## `````````````````````````````````````````````


## `````````````````````````````````````````````
## Read Data ####
## `````````````````````````````````````````````
# read in the us population data
uspop <- read.csv("/mnt/r.rudis.challenge2/data/uspop - 2.csv", stringsAsFactors=FALSE)
uspop_long <- gather(uspop, year, population, -name, -iso_3166_2)
uspop_long$year <- sub("X", "", uspop_long$year)
## `````````````````````````````````````````````



## `````````````````````````````````````````````
## Data Manipulations ####
# normalize the values
states <- count(homeless, year, state, wt=total_homeless)
states <- left_join(states, albersusa::usa_composite()@data[,3:4], by=c("state"="iso_3166_2"))
states <- ungroup(filter(states, !is.na(name)))
states$year <- as.character(states$year)
states <- mutate(left_join(states, uspop_long), homeless_per_100k=(n/population)*100000)

# we want to order from worst to best
group_by(states, name) %>%
  summarise(mean=mean(homeless_per_100k, na.rm=TRUE)) %>%
  arrange(desc(mean)) -> ordr

states$year <- factor(states$year, levels=as.character(2006:2016))
states$name <- factor(states$name, levels=ordr$name)
## `````````````````````````````````````````````

## `````````````````````````````````````````````
## Data Visulization ####
## `````````````````````````````````````````````
# plot
#+ fig.retina=2, fig.width=10, fig.height=15
gg <- ggplot(states, aes(x=year, y=homeless_per_100k))
gg <- gg + geom_segment(aes(xend=year, yend=0), size=0.33)
gg <- gg + geom_point(size=0.5)
gg <- gg + scale_x_discrete(expand=c(0,0),
                            breaks=seq(2007, 2015, length.out=5),
                            labels=c("2007", "", "2011", "", "2015"),
                            drop=FALSE)
gg <- gg + scale_y_continuous(expand=c(0,0), labels=comma, limits=c(0,1400))
gg <- gg + labs(x=NULL, y=NULL,
                title="US Department of Housing & Urban Development (HUD) Total (Estimated) Homeless Population",
                subtitle="Counts aggregated from HUD Communities of Care Regional Surveys (normalized per 100K population)",
                caption="Data from: https://www.hudexchange.info/resource/4832/2015-ahar-part-1-pit-estimates-of-homelessness/")
gg <- gg + facet_wrap(~name, scales="free", ncol=6)
#gg <- gg + theme_hrbrmstr_an(grid="Y", axis="", strip_text_size=9)
gg <- gg + theme(axis.text.x=element_text(size=8))
gg <- gg + theme(axis.text.y=element_text(size=7))
gg <- gg + theme(panel.margin=unit(c(10, 10), "pt"))
gg <- gg + theme(panel.background=element_rect(color="#97cbdc44", fill="#97cbdc44"))
gg <- gg + theme(plot.margin=margin(10, 20, 10, 15))
gg
## `````````````````````````````````````````````
