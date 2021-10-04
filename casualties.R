breakpoints <- c(0,1,5.5,10.5,16.5,24.5,39.5,54.5,64.5,79.5,100)

df2 <- data.frame(Age = unique(df$VICTIM_AGE))
df2$Age <- sort(df2$Age)
for(i in 1:10) df2$Frequency[i] <- length(which(df$VICTIM_AGE == df2$Age[i]))

hist(
    df$VICTIM_AGE,
    breaks = breakpoints,
    freq = FALSE,
    main = "Histogram of Victim Age",
    xlab = "Victim Age",
    ylab = "Frequency",
    col = "lightblue"
    )

unique(df$SOURCE_OF_IGNITION)

df3 <- data.frame(Age = df$VICTIM_AGE, Gender = df$VICTIM_GENDER, Source = df$SOURCE_OF_IGNITION)

df4 <- data.frame(aggregate(seq(nrow(df3))~., data=df3, FUN=length))
colnames(df4)[which(names(df4) == "seq.nrow.df3..")] <- "Count"

df5 <- data.frame("Source" = unique(df$SOURCE_OF_IGNITION))

for(i in 1:length(df5$Source)){
    df5$Count[i] = sum(df$SOURCE_OF_IGNITION == df5$Source[i])
}

source = "Cooking appliances"
age = 59.5
age = 72

counts <- c(sum(df4$Count[which(df4$Age < age & df4$Gender == "Male" & df4$Source == source)]),
sum(df4$Count[which(df4$Age >= age & df4$Gender == "Male" & df4$Source == source)]),
sum(df4$Count[which(df4$Age < age & df4$Gender == "Female" & df4$Source == source)]),
sum(df4$Count[which(df4$Age >= age & df4$Gender == "Female" & df4$Source == source)]),
sum(df4$Count[which(df4$Age < age & df4$Gender == "Male" & df4$Source != source)]),
sum(df4$Count[which(df4$Age >= age & df4$Gender == "Male" & df4$Source != source)]),
sum(df4$Count[which(df4$Age < age & df4$Gender == "Female" & df4$Source != source)]),
sum(df4$Count[which(df4$Age >= age & df4$Gender == "Female" & df4$Source != source)]))

df6 <- data.frame(expand.grid(Age = c(paste("Under", age), paste(age, "or Over")),
                              Gender = c("Male", "Female"),
                              Source = c(source, "Other")
                              ),
                              Count = counts
)

cont_table <- xtabs(Count ~ Age + Source + Gender, data = df6)
cont_table

library(vcd)

mosaic(cont_table,
       shade=T,
       colorize = T,
       gp = gpar(fill = matrix(c("red",
                                 "blue",
                                 "pink",
                                 "light blue"), 2, 2)
                 )
)

mantelhaen.test(cont_table)

