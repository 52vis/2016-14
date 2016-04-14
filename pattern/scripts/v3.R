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

# Alternate 1 ####
# Calculating CAGR ####
df.1 <- 
  states %>%
  select(year,name,homeless_per_100k) %>%
  filter(year == "2007" | year == "2015") %>%
  arrange(name) %>% 
  group_by(name) 


# http://stackoverflow.com/questions/21667262/how-to-find-difference-between-values-in-two-rows-in-an-r-dataframe-using-dplyr
# df.2 <- 
#   df.1 %>%
#   mutate(volume =  homeless_per_100k - lag(homeless_per_100k, default = 0))
  
# calculating CAGR
# ((End Value / Beg Value) ^ (1/# of Years)) - 1
df.2 <- 
  df.1 %>%
  mutate(
    delta.V = homeless_per_100k / lag(homeless_per_100k, default = 1),
    cagr =  ((delta.V)^(1/(2015-2007))) -1) %>%
  filter(year == "2015") %>%
  select(name,cagr)

# manual calculation for Columbia
# ((1085/932)^(1/(2015-2007)))-1

# Alternate 1 Conclusion ####
# Plotting CAGR seemed too boring, going with heat map for the entire data set 

# Alternate 2 ####
df.1 = states 
# df.1 %>%
#   mutate(homeless = rescale(states$homeless_per_100k, to=c(0,1), 
#                             from=range(states$homeless_per_100k, na.rm=TRUE))) %>%
#   select(year,state,homeless) -> df.2

df.1 %>%
  mutate(homeless = rescale(states$homeless_per_100k)) %>%
  select(year,state,homeless) -> df.3



## `````````````````````````````````````````````

## `````````````````````````````````````````````
## Data Visulization ####
## `````````````````````````````````````````````

# Heat Map
# http://www.r-bloggers.com/recreating-the-vaccination-heatmaps-in-r-2/
# https://learnr.wordpress.com/2010/01/26/ggplot2-quick-heatmap-plotting/

p <-
  ggplot(df.3, aes(x=homeless, y=year)) + 
  geom_tile(aes(fill = factor(state))) + 
  scale_fill_gradient(low = "white",high = "steelblue")


## `````````````````````````````````````````````
