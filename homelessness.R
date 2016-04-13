library(readxl)
library(dplyr)
library(magrittr)
library(purrr)
library(stringr)
library(ggplot2)
library(gganimate)

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

states <- homeless %>%
  filter(state %in% state.abb) %>%
  group_by(year, state) %>%
  summarize(total_homeless = sum(total_homeless),
            sheltered_homeless = sum(sheltered_homeless)) %>%
  mutate(prop_sheltered = (sheltered_homeless / total_homeless) * 100)

states$region <- tolower(state.name[match(states$state,
                                            state.abb)])

us <- map_data("state")

p <- ggplot() +
  geom_map(aes(x = long, y = lat, map_id = region), data = us,
           map = us, fill = "#ffffff", color = "#ffffff", size = 0.5) +
  geom_map(aes(fill = prop_sheltered, frame = year, map_id = region),
           map = us, data = states) +
  coord_map("albers", lat0 = 39, lat1 = 45) +
  scale_fill_gradient(name = NULL, low = "red",
                      high = "blue") +
  labs(x = NULL,
       y = NULL,
       title = "Percent of Homeless who are Sheltered") +
  theme(axis.ticks = element_blank(),
        axis.text = element_blank(),
        panel.background = element_blank(),
        panel.border = element_blank())

gg_animate(p, "sheltered-homeless-by-state.gif",
           ani.height = 400, ani.width = 800)
