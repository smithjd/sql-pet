annotate_color <- function(x) {

  cap_text <- ifelse(x==1,"Colour with No Family", str_glue("Colour with {x} Colours in a Family"))

  base_plot +
    geom_mark_rect(aes(group=name_parent, color=name_parent,
                       label=str_c(name_parent)),
                   label.margin=margin(0,0,0,0,"mm"),
                   label.buffer=unit(1,"mm"),
                   label.fontsize=13,
                   label.fill="#000000ae", con.colour="#ffffffae",
                   data = . %>% filter(n_children==x),
                   label.colour="#ffffffae",
                   con.cap=unit(0,"mm")) +
    labs(title=cap_text)

}

annotate_color(1)
annotate_color(5)
