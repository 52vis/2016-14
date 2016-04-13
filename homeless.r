#Who takes care of their veterans? (script)
#Note, you need to reformat the cells in the Excel sheet so they don't 
#automatically insert commas above a thousand (ie 1,024->1024)

#Grab the 2015 data as a csv
data<-read.csv(file.choose())

#Now just the data we want
df<-data[, c("State", "Homeless.Veterans..2015", "Sheltered.Homeless.Veterans..2015", "Unsheltered.Homeless.Veterans..2015")]

#Now a new column in df showing Unsheltered Homeless veterans as a percentage of all Homeless Veterans
df$value<-df$Unsheltered.Homeless.Veterans..2015/df$Homeless.Veterans..2015

#Ok, now to generate the choropleth
#get our library
library(choroplethr)


#Ok, so now we need to match up the state names from our data with those the choroplethr package accepts
#Now there might be an elegant solution but ain't nobody got time for dat
#So we just manually insert them as a vector of strings
#also Guam, Puerto Rico, Virgin Islands, and Total  get dropped
df$region<-c("alaska", "alabama", "arkansas", "arizona", "california", "colorado", "connecticut", "district of columbia", "delaware", 
             "florida", "georgia", "CUT", "hawaii", "iowa", "idaho", "illinois", "indiana", "kansas", "kentucky", "louisiana", 
             "massachusetts", "maryland", "maine", "michigan", "minnesota", "missouri", "mississippi", "montana", "north carolina",
             "north dakota", "nebraska", "new hampshire", "new jersey", "new mexico", "nevada", "new york", "ohio", "oklahoma", "oregon",
             "pennsylvania", "CUT", "rhode island", "south carolina", "south dakota", "tennessee", "texas", "utah", "virginia", "CUT", 
             "vermont", "washington", "wisconsin", "west virginia", "wyoming", "CUT" )
project<-df[df$region!="CUT", c("region", "value")]

#Ugh, now we reorder the rows to match choroplethr
project<-project[order(project$region),]

#And now the choropleth
state_choropleth(project, title="Worst states for veterans", legend="Percent of homeless veterans without shelter", num_colors = 4)
