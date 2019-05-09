library(ggplot2)
library(readstata13)
library(dplyr)
library(tidyr)
library(lubridate)

root <- dirname(getwd())
datadir <- file.path(root,"data")
outdir <- file.path(root,"output")

#######################################
# San Bruno news searches

sbdata <- read.csv(paste(datadir,'GoogleTrends','sanbruno_cities_news.csv',sep='/'),skip=2)
# Filter out junk
pat <- "^[0-9]{4}-[0-9]{2}-[0-9]{2}"
reppat <- "(^[0-9]{4}-[0-9]{2}-[0-9]{2}).*"
sbdata <- sbdata %>% filter(grepl(pat, Week))

# Get start date
sbdata <- sbdata %>% mutate(WeekStart=sub(reppat,"\\1",grep(pat,Week,value = TRUE)))
sbdata <- sbdata %>% select(-Week)
sbdata <- sbdata %>% gather("City","Search",1:4)
sbdata <- sbdata %>% mutate(Search = as.numeric(Search))
sbdata <- sbdata %>% mutate(WeekStart = ymd(WeekStart))
sbdata <- sbdata %>% filter(WeekStart > "2010-04-01", WeekStart < "2011-01-01")
sbdata$City <- sub('.*\\.\\.\\.', "",sbdata$City)
sbdata$City <- gsub('\\.'," ",sbdata$City)

(sbplot <- ggplot(sbdata,aes(x=WeekStart,y=Search,colour=City,group=City)) + 
  geom_line(size=1) + 
  geom_vline(xintercept= as.numeric(ymd(c("2010-09-02","2010-09-16")))) +
  ggtitle('News searches for San Bruno event') + xlab("Weekly data (2010)") +
  scale_y_continuous(limits = c(0,100)) +
  theme(plot.title = element_text(size=24),
        axis.title.x = element_text(size=20),
        axis.text.x = element_text(size=14),
        axis.title.y = element_text(size=20),
        axis.text.y = element_text(size=14),
        legend.title = element_text(size=20),
        legend.text = element_text(size=14),
        legend.position = "bottom") +
  guides(col = guide_legend(nrow = 2)))

ggsave(paste(outdir,'google_sanbruno_cities_news.png',sep='/'),height = 5, width = 10)

#######################################
# San Bruno web searches

sbdata <- read.csv(paste(datadir,'GoogleTrends','sanbruno_cities_web.csv',sep='/'),skip=2)
# Filter out junk
pat <- "^[0-9]{4}-[0-9]{2}-[0-9]{2}"
reppat <- "(^[0-9]{4}-[0-9]{2}-[0-9]{2}).*"
sbdata <- sbdata %>% filter(grepl(pat, Week))

# Get start date
sbdata <- sbdata %>% mutate(WeekStart=sub(reppat,"\\1",grep(pat,Week,value = TRUE)))
sbdata <- sbdata %>% select(-Week)
sbdata <- sbdata %>% gather("City","Search",1:4)
sbdata <- sbdata %>% mutate(Search = as.numeric(Search))
sbdata <- sbdata %>% mutate(WeekStart = ymd(WeekStart))
sbdata <- sbdata %>% filter(WeekStart > "2010-04-01", WeekStart < "2011-01-01")
sbdata$City <- sub('.*\\.\\.\\.', "",sbdata$City)
sbdata$City <- gsub('\\.'," ",sbdata$City)

(sbplot <- ggplot(sbdata,aes(x=WeekStart,y=Search,colour=City,group=City)) + 
  geom_line(size=1) + 
  geom_vline(xintercept= as.numeric(ymd(c("2010-09-02","2010-09-16")))) +
  ggtitle('Web searches for San Bruno event') + xlab("Weekly data (2010)") +
  scale_y_continuous(limits = c(0,100)) +
  theme(plot.title = element_text(size=24),
        axis.title.x = element_text(size=20),
        axis.text.x = element_text(size=14),
        axis.title.y = element_text(size=20),
        axis.text.y = element_text(size=14),
        legend.title = element_text(size=20),
        legend.text = element_text(size=14),
        legend.position = "bottom") +
  guides(col = guide_legend(nrow = 2)))

ggsave(paste(outdir,'google_sanbruno_cities_web.png',sep='/'),height = 5, width = 10)

#######################################
# World series news searches

sbdata <- read.csv(paste(datadir,'GoogleTrends','WorldSeries_news.csv',sep='/'),skip=2)
# Filter out junk
pat <- "^[0-9]{4}-[0-9]{2}-[0-9]{2}"
reppat <- "(^[0-9]{4}-[0-9]{2}-[0-9]{2}).*"
sbdata <- sbdata %>% filter(grepl(pat, Week))

# Get start date
sbdata <- sbdata %>% mutate(WeekStart=sub(reppat,"\\1",grep(pat,Week,value = TRUE)))
sbdata <- sbdata %>% select(-Week)
sbdata <- sbdata %>% gather("Topic","Search",1:2)
sbdata <- sbdata %>% mutate(Search = as.numeric(Search))
sbdata <- sbdata %>% mutate(WeekStart = ymd(WeekStart))
sbdata <- sbdata %>% filter(WeekStart > "2010-04-01", WeekStart < "2011-01-01")
sbdata <- sbdata %>% mutate(Topic = ifelse(grepl("San.Bruno",Topic),"San Bruno","World Series"))

(sbplot <- ggplot(sbdata,aes(x=WeekStart,y=Search,colour=Topic,group=Topic)) + 
          geom_line(size=1) + 
          geom_vline(xintercept= as.numeric(ymd(c("2010-09-02","2010-09-16")))) +
          ggtitle('Searches in SF Bay Area') + xlab("Weekly data (2010)") +
          scale_y_continuous(limits = c(0,100)) +
          theme(plot.title = element_text(size=24),
                axis.title.x = element_text(size=20),
                axis.text.x = element_text(size=14),
                axis.title.y = element_text(size=20),
                axis.text.y = element_text(size=14),
                legend.title = element_text(size=20),
                legend.text = element_text(size=14),
                legend.position = "bottom") +
          guides(col = guide_legend(nrow = 2)))

ggsave(paste(outdir,'google_worldseries_news.png',sep='/'),height = 5, width = 10)

#######################################
# World series web searches

sbdata <- read.csv(paste(datadir,'GoogleTrends','WorldSeries_web.csv',sep='/'),skip=2)
# Filter out junk
pat <- "^[0-9]{4}-[0-9]{2}-[0-9]{2}"
reppat <- "(^[0-9]{4}-[0-9]{2}-[0-9]{2}).*"
sbdata <- sbdata %>% filter(grepl(pat, Week))

# Get start date
sbdata <- sbdata %>% mutate(WeekStart=sub(reppat,"\\1",grep(pat,Week,value = TRUE)))
sbdata <- sbdata %>% select(-Week)
sbdata <- sbdata %>% gather("Topic","Search",1:2)
sbdata <- sbdata %>% mutate(Search = as.numeric(Search))
sbdata <- sbdata %>% mutate(WeekStart = ymd(WeekStart))
sbdata <- sbdata %>% filter(WeekStart > "2010-04-01", WeekStart < "2011-01-01")
sbdata <- sbdata %>% mutate(Topic = ifelse(grepl("San.Bruno",Topic),"San Bruno","World Series"))

(sbplot <- ggplot(sbdata,aes(x=WeekStart,y=Search,colour=Topic,group=Topic)) + 
  geom_line(size=1) + 
  geom_vline(xintercept= as.numeric(ymd(c("2010-09-02","2010-09-16")))) +
  ggtitle('Searches in SF Bay Area') + xlab("Weekly data (2010)") +
  scale_y_continuous(limits = c(0,100)) +
  theme(plot.title = element_text(size=24),
        axis.title.x = element_text(size=20),
        axis.text.x = element_text(size=14),
        axis.title.y = element_text(size=20),
        axis.text.y = element_text(size=14),
        legend.title = element_text(size=20),
        legend.text = element_text(size=14),
        legend.position = "bottom") +
  guides(col = guide_legend(nrow = 2)))

ggsave(paste(outdir,'google_worldseries_web.png',sep='/'),height = 5, width = 10)
