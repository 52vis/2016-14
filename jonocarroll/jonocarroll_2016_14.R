## 52vis challenges, week 2
## originally seen at
## https://rud.is/b/2016/04/06/52vis-week-2-2016-week-14-honing-in-on-the-homeless/
## this version blogged @ jcarroll.com.au/
## github: github.com/jonocarroll/2016-14

## load relevant packages
pacman::p_load(magrittr, dplyr, tidyr, ggplot2, httr, readxl, purrr, data.table)

setwd("jonocarroll")

## load the data from hudexchange.info (download once)
# URL <- "https://www.hudexchange.info/resources/documents/2007-2015-PIT-Counts-by-CoC.xlsx"
# GET(URL, write_disk("homeless.xlsx", overwrite=TRUE))

## load the sheets into a list of data.frames
HUDdata <- map(as.character(2007:2015), ~read_excel("homeless.xlsx", sheet=.x)) %>%
  map(function(x) mutate(x, Year=sub(".*, ","",names(x)[3]))) %>%
  map(function(x) setNames(x, sub("(.*),.*","\\1",names(x))))

HUDdataDF <- rbindlist(HUDdata, fill=TRUE)
