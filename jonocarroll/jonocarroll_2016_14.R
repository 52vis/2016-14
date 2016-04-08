## 52vis challenges, week 2
## originally seen at
## https://rud.is/b/2016/04/06/52vis-week-2-2016-week-14-honing-in-on-the-homeless/
## this version blogged @ jcarroll.com.au/
## github: github.com/jonocarroll/2016-14

## load relevant packages
pacman::p_load(magrittr, dplyr, tidyr, ggplot2, httr, readxl)

## load the data from hudexchange.info (download once)
# URL <- "https://www.hudexchange.info/resources/documents/2007-2015-PIT-Counts-by-CoC.xlsx"
# GET(URL, write_disk("homeless.xlsx", overwrite=TRUE))
HUDdata <- read_excel("homeless.xlsx")


