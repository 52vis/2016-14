rm(list = ls())
library("readxl")
library("readr")
library("purrr")
library("dplyr")
library("tidyr")
library("stringr")

# grab the HUD homeless data
URL <- "https://www.hudexchange.info/resources/documents/2007-2015-PIT-Counts-by-CoC.xlsx"
fil <- basename(URL)
if (!file.exists(fil)) download.file(URL, fil, mode = "wb")

# turn the excel tabs into a long data.frame
yrs <- 2015:2007
names(yrs) <- 1:9
homeless <- map_df(names(yrs), function(i) {
  df <- suppressWarnings(read_excel(fil, as.numeric(i)))
  df[,3:ncol(df)] <- suppressWarnings(lapply(df[,3:ncol(df)], as.numeric))
  new_names <- tolower(make.names(colnames(df)))
  new_names <- str_replace_all(new_names, "\\.+", "_")
  df <- setNames(df, str_replace_all(new_names, "_[[:digit:]]+$", ""))
  bind_cols(df, data_frame(year = rep(yrs[i], nrow(df))))
})

rm(URL, fil, yrs)

# clean it up a bit
homeless <- homeless %>% 
  mutate(state = str_match(coc_number, "^([[:alpha:]]{2})")[,2],
         coc_name = str_replace(coc_name, " CoC$", "")) %>% 
  select(year, state, everything()) %>% 
  filter(!is.na(state))

# read in the us population data
URL2 <- "https://raw.githubusercontent.com/52vis/2016-14/master/uspop.csv"
fil2 <- basename(URL2)
if (!file.exists(fil2)) download.file(URL2, fil2, mode = "wb")

uspop <- read_csv(fil2)
uspop <- uspop %>%
  gather(year, population, -name, -iso_3166_2) %>% 
  mutate(year = sub("X", "", year)) %>% 
  rename(state = iso_3166_2)

rm(fil2, URL2)

df <-   homeless %>%
  group_by(year, state) %>% 
  summarise(n = sum(total_homeless)) %>% 
  ungroup() %>% 
  mutate(year = as.character(year)) %>% 
  left_join(uspop, by = c("year", "state")) %>% 
  mutate(total_homeless_per_100k = (n/population)*100000) %>% 
  filter(!is.na(name))