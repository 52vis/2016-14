#### Rud.Is Challenge #2
# https://github.com/52vis/2016-14
# https://rud.is/b/2016/04/06/52vis-week-2-2016-week-14-honing-in-on-the-homeless/

## `````````````````````````````````````````````
## Load Libraries ####

# only install if not already done
# http://stackoverflow.com/questions/4090169/elegant-way-to-check-for-missing-packages-and-install-them
list.of.packages <- c("ggplot2", "showtext", "grid","ggalt","ggthemes","readxl","hrbrmisc","stringr","virdis","purrr","dplyr","tidyr","scales","albersusa","openxlsx")
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
library(openxlsx)
library(ggthemes)
## `````````````````````````````````````````````

## `````````````````````````````````````````````
## Scraping Data ####
## `````````````````````````````````````````````
# grab the HUD homeless data

# URL <- "https://www.hudexchange.info/resources/documents/2007-2015-PIT-Counts-by-CoC.xlsx"
# fil <- basename(URL)
# if (!file.exists(fil)) download.file(URL, fil, mode="wb")
# 
# # turn the excel tabs into a long data.frame
# yrs <- 2015:2007
# names(yrs) <- 1:9
# homeless <- map_df(names(yrs), function(i) {
#   df <- suppressWarnings(read_excel(fil, as.numeric(i)))
#   df[,3:ncol(df)] <- suppressWarnings(lapply(df[,3:ncol(df)], as.numeric))
#   new_names <- tolower(make.names(colnames(df)))
#   new_names <- str_replace_all(new_names, "\\.+", "_")
#   df <- setNames(df, str_replace_all(new_names, "_[[:digit:]]+$", ""))
#   bind_cols(df, data_frame(year=rep(yrs[i], nrow(df))))
# })
# 
# # clean it up a bit
# homeless <- mutate(homeless,
#                    state=str_match(coc_number, "^([[:alpha:]]{2})")[,2],
#                    coc_name=str_replace(coc_name, " CoC$", ""))
# homeless <- select(homeless, year, state, everything())
# homeless <- filter(homeless, !is.na(state))
# 
# # store the df for later use
# write.xlsx(homeless, file = "/mnt/r.rudis.challenge2/data/homeless.xlsx")
# write.csv(homeless, file = "/mnt/r.rudis.challenge2/data/homeless.csv")

# read the stored df homeless
homeless = read.csv(file="/mnt/r.rudis.challenge2/data/homeless.csv")
## `````````````````````````````````````````````


## `````````````````````````````````````````````
## Read Data ####
## `````````````````````````````````````````````
# read in the us population data (seperate file from the one scrapped above)
# uspop <- read.csv("/mnt/r.rudis.challenge2/data/uspop - 2.csv", stringsAsFactors=FALSE)
# uspop_long <- gather(uspop, year, population, -name, -iso_3166_2)
# uspop_long$year <- sub("X", "", uspop_long$year)
## `````````````````````````````````````````````



## `````````````````````````````````````````````
## Data Manipulations ####
# normalize the values
# states <- count(homeless, year, state, wt=total_homeless)
# states <- left_join(states, albersusa::usa_composite()@data[,3:4], by=c("state"="iso_3166_2"))
# states <- ungroup(filter(states, !is.na(name)))
# states$year <- as.character(states$year)
# states <- mutate(left_join(states, uspop_long), homeless_per_100k=(n/population)*100000)
# 
# # we want to order from worst to best
# group_by(states, name) %>%
#   summarise(mean=mean(homeless_per_100k, na.rm=TRUE)) %>%
#   arrange(desc(mean)) -> ordr
# 
# states$year <- factor(states$year, levels=as.character(2006:2016))
# states$name <- factor(states$name, levels=ordr$name)
# 
# # save df for later use
# write.csv(states, file = "/mnt/r.rudis.challenge2/data/states.csv")

# read the stored df states
states = read.csv(file="/mnt/r.rudis.challenge2/data/states.csv")


# Alternate 1 ###
# Refer to v3 for CAGR Calculation

# Alternate 2 ####
df.1 = states 

df.1 %>%
  mutate(homeless = rescale(states$homeless_per_100k)) %>%
  select(year,state,homeless) -> df.3

#remove any NA
#http://stackoverflow.com/questions/26665319/removing-na-in-dplyr-pipe
df.3 %>%
  na.omit() %>%
  filter(!is.na(homeless)) -> df.3
## `````````````````````````````````````````````

## `````````````````````````````````````````````
## Data Visulization ####
## `````````````````````````````````````````````

# Heat Map
# http://www.r-bloggers.com/recreating-the-vaccination-heatmaps-in-r-2/
# https://learnr.wordpress.com/2010/01/26/ggplot2-quick-heatmap-plotting/
# https://rpubs.com/daattali/heatmapsGgplotVsLattice
# https://rud.is/b/2016/02/14/making-faceted-heatmaps-with-ggplot2/
# http://www.r-bloggers.com/ggplot2-quick-heatmap-plotting/
# http://www.sthda.com/english/wiki/ggplot2-quick-correlation-matrix-heatmap-r-software-and-data-visualization





#scale fill gradient from
# http://www.guru-gis.net/plot-heat-maps-for-correlations-confusion-matrices-etc/

# aestherics from
# https://rud.is/b/2016/02/14/making-faceted-heatmaps-with-ggplot2/

p <-
  ggplot(df.3, aes(x=factor(state), y=factor(year))) + 
  geom_tile(aes(fill = homeless),colour = "white",size=0.1) + 
  scale_fill_gradient2(low="#006400", mid="#f2f6c3",high="#cd0000",midpoint=0.5)

# 1:1 aspect ratio (i.e. geom_tile()–which draws rectangles–will draw nice squares).
p1 <- p + coord_equal()

p1 <- p1 + labs(x=NULL, y=NULL)

p1 <- p1 + theme_tufte(base_family="Helvetica")

# tick marks on the axes and I want the text to be slightly smaller than the default.
p1 <- p1 + theme(axis.ticks=element_blank())
p1 <- p1 + theme(axis.text=element_text(size=7))

# legend
p1 <- p1 + theme(legend.title=element_text(size=8))
p1 <- p1 + theme(legend.text=element_text(size=6))
p1

# x-axis labels
p1 <- p1 + theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))


# legend 
# http://juliasilge.com/blog/You-Must-Allow-Me/
p2 <- p1 +
  theme(legend.title=element_text(size=6)) + 
  theme(legend.title.align=1) + 
  theme(legend.text=element_text(size=6)) + 
  theme(legend.position="bottom") + 
  theme(legend.key.size=unit(0.2, "cm")) + 
  theme(legend.key.width=unit(1, "cm"))

p2 <- p2 +
ggtitle(expression(atop(bold("Homeless Across the States"), atop(italic("Coloumbia Stands Out ..."), ""))))

## `````````````````````````````````````````````
  