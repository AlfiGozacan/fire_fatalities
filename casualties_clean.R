setwd("C:/../Data")
casualties <- read.csv("casualties.csv")
df <- as.data.frame(casualties)

unique(df$INJURY_TYPE)
unique(df$INJURY_SEVERITY)
unique(df$VICTIM_AGE)
unique(df$VICTIM_GENDER)

sum(df$VICTIM_GENDER =="Not known")
sum(df$VICTIM_AGE =="Unspecified")

df<-df[!(df$VICTIM_GENDER =="Not known"),]
df<-df[!(df$VICTIM_AGE =="Unspecified"),]

df$VICTIM_AGE[df$VICTIM_AGE == "65 to 79"] <- mean(c(65, 79))
df$VICTIM_AGE[df$VICTIM_AGE == "55 to 64"] <- mean(c(55, 64))
df$VICTIM_AGE[df$VICTIM_AGE == "40 to 54"] <- mean(c(40, 54))
df$VICTIM_AGE[df$VICTIM_AGE == "25 to 39"] <- mean(c(25, 39))
df$VICTIM_AGE[df$VICTIM_AGE == "17 to 24"] <- mean(c(17, 24))
df$VICTIM_AGE[df$VICTIM_AGE == "80 or over"] <- mean(c(80, 100))
df$VICTIM_AGE[df$VICTIM_AGE == "1 to 5"] <- mean(c(1, 5))
df$VICTIM_AGE[df$VICTIM_AGE == "Under 1"] <- mean(c(0, 1))
df$VICTIM_AGE[df$VICTIM_AGE == "11 to 16"] <- mean(c(11, 16))
df$VICTIM_AGE[df$VICTIM_AGE == "6 to 10"] <- mean(c(6, 10))

df$VICTIM_AGE <- as.numeric(df$VICTIM_AGE)
