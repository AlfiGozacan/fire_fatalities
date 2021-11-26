### Load libraries

library(dplyr)
library(tidyr)
library(vcd)
library(ggplot2)
library(ggthemes)

### Read in data

df <- read.csv("C:/Users/agozacan/OneDrive - Humberside Fire and Rescue Service/Fire Fatality Profiling/Data/model_data_no_undersamp.csv")

### Test association between is.NIGHT and is.FAL

df %>%
     filter(
          (INCIDENT_LOCATION_TYPE == "Dwellings") &
          (CAUSE_OF_FIRE != "Unspecified cause")
     ) %>%
     mutate(
          is.NIGHT = (HOUR_BANDS %in% c("h22-23",
                                        "h23-00",
                                        "h00-01",
                                        "h01-02",
                                        "h02-03",
                                        "h03-04",
                                        "h04-05",
                                        "h05-06")),
          is.FAL = (CAUSE_OF_FIRE == "Faulty appliances and leads")
     ) %>%
     count(is.NIGHT, is.FAL) %>%
     xtabs(n ~ ., data=.) %>%
     #mosaic(shade=TRUE)
     #chisq.test()
     odds.ratio()

### Test associations between age and fatality rate across genders

df %>%
     filter(
          (INCIDENT_LOCATION_TYPE == "Dwellings") &
          (VICTIM_GENDER != "Not known") &
          (VICTIM_AGE != "Unspecified")
     ) %>%
     mutate(
          is.SENIOR = (VICTIM_AGE %in% c("80 or over"))
     ) %>%
     count(is.SENIOR, FATALITY) %>%
     xtabs(n ~ ., data=.) %>%
     .[c("TRUE", "FALSE"), c("1", "0")] %>%
     #mosaic(shade=TRUE)
     #mantelhaen.test()
     odds.ratio()

### Test association between smoking and fatality rate across genders

df %>%
     filter(
          (INCIDENT_LOCATION_TYPE == "Dwellings") &
               (SOURCE_OF_IGNITION != "Other/ Unspecified") &
               (VICTIM_GENDER != "Not known")
     ) %>%
     mutate(
          is.SMOKING = (SOURCE_OF_IGNITION == "Smokers' materials")
     ) %>%
     count(is.SMOKING, FATALITY) %>%
     xtabs(n ~ ., data=.) %>%
     .[c("TRUE", "FALSE"), c("1", "0")] %>%
     #mosaic(shade=TRUE)
     #mantelhaen.test()
     odds.ratio()

### Plot fatality rates

ages = c("Under 1", "1 to 5", "6 to 10", "11 to 16", "17 to 24", "25 to 39", "40 to 54", "55 to 64", "65 to 79", "80 or over")

fatality_rates <- data.frame("AGE_GROUP" = ages)

for(i in 1:length(ages)){
     
     fat_rate <- df %>%
                    filter(
                         (INCIDENT_LOCATION_TYPE == "Dwellings") &
                         (VICTIM_AGE == ages[i])
                    ) %>%
                    .$FATALITY %>%
                    mean()
     
     fatality_rates$FATALITY_RATE[i] = fat_rate
     
}

remove(i)
remove(fat_rate)
remove(ages)

fatality_rates$AGE_GROUP <- factor(fatality_rates$AGE_GROUP, levels=fatality_rates$AGE_GROUP)

ggplot(data=fatality_rates, mapping=aes(x=AGE_GROUP, y=FATALITY_RATE)) +
     geom_col(fill="darkslateblue") +
     theme_economist() +
     theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1)) +
     scale_color_economist() +
     ggtitle("Fatality rate by age group") +
     xlab("Age Group") +
     ylab("Fatality Rate")
