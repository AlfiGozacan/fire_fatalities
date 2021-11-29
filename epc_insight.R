### Load libraries

library(tidyverse)

### Load data

df <- read.csv("C:/Users/agozacan/OneDrive - Humberside Fire and Rescue Service/Fire Fatality Profiling/Data/Residential EPC Data/epc_with_incs.csv")

### Histograms

par(mfrow=c(2, 1))

df %>%
     mutate(
          FIRE = (ref != 0)
     ) %>%
     filter(FIRE) %>%
     select(CURRENT_ENERGY_EFFICIENCY) %>%
     pull() %>%
     hist(nclass=50,
          xlim=c(0, 100),
          xlab="Energy Efficiency Rating",
          main="Distribution of energy efficiency ratings for dwellings where fires have occurred",
          col="pink")

df %>%
     mutate(
          FIRE = (ref != 0)
     ) %>%
     filter(!FIRE) %>%
     select(CURRENT_ENERGY_EFFICIENCY) %>%
     pull() %>%
     hist(nclass=100,
          xlim=c(0, 100),
          xlab="Energy Efficiency Rating",
          main="Distribution of energy efficiency ratings for dwellings where fires have not occurred",
          col="lightblue")

### Balance data

df <- rbind(df[df$ref != 0,], df[df$ref == 0,][-sample(1:nrow(df), 340000),])

### Fit logistic regression model

fit <- df %>%
          mutate(
               FIRE = (ref != 0)
          ) %>%
          glm(FIRE ~ CURRENT_ENERGY_EFFICIENCY, data=., family=binomial(link="logit"))

a <- summary(fit)$coeff[1]
b <- summary(fit)$coeff[2]

par(mfrow=c(1, 1))

### Plot data

df %>%
     mutate(
          FIRE = (ref != 0)
     ) %>%
     select(CURRENT_ENERGY_EFFICIENCY, FIRE) %>%
     plot()

xseq <- seq(
          min(df$CURRENT_ENERGY_EFFICIENCY),
          max(df$CURRENT_ENERGY_EFFICIENCY),
          length.out=100
          )

response <- function(x){
     
     return(1 / (1 + exp(-(a + b*x))))
     
}

lines(xseq, response(xseq))

### See summary of model

summary(fit)