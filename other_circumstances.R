df <- data.frame(expand.grid(is.Alcohol = c("Yes", "No"),
                             is.Cooking = c("Yes", "No")),
                 Count = c(2955, 29219, 1565, 51398))

cont_table <- xtabs(Count ~ is.Alcohol + is.Cooking, data = df)

library(vcd)

par(mfrow=c(2, 2))

mosaic(cont_table,
       shade = T,
       colorize = T,
       gp = gpar(fill = matrix(c("red",
                                 "blue",
                                 "pink",
                                 "light blue"), 2, 2)
       )
)

chisq.test(cont_table)

df2 <- data.frame(expand.grid(is.Immobile = c("Yes", "No"),
                             is.Cooking = c("Yes", "No")),
                 Count = c(1741, 30433, 1438, 51525))

cont_table2 <- xtabs(Count ~ is.Immobile + is.Cooking, data = df2)

mosaic(cont_table2,
       shade = T,
       colorize = T,
       gp = gpar(fill = matrix(c("red",
                                 "blue",
                                 "pink",
                                 "light blue"), 2, 2)
       )
)

chisq.test(cont_table2)
