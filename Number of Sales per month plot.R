ggplot(
  data = monthly_sales_rep_adjusted,
  aes(x = year_month, y = soh_count)
  ) +
  #geom_line(alpha = .5 , color = "green") +
  #geom_point(color = "green") +
  geom_point(
    data = monthly_sales_rep_as_is,
    aes(orderdate, soh_count
    ), color = "red", alpha = .5
  ) +
  geom_smooth(aes(group=0), method="lm") +
  #Labeling
  theme(plot.title = element_text(hjust = .5)) + # Center ggplot title
  labs(
    title = glue(
      "Number of Sales per month using corrected dates\n",
      "Counting Sales Order Header records"
    ),
    subtitle = glue("Red dots are Sales Reps as is. Green line is adjusted."),
    caption = glue("Datasets Include: \n
                   monthly_sales_rep_adjusted, monthly_sales_rep_as_is"),
    x = paste0("Monthly - between ", min_soh_dt, " - ", max_soh_dt),
    y = "Number of Sales Recorded"
  )
