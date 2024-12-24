library(tidymodels)
library(readr)
library(janitor)
library(discrim)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

# https://archive.ics.uci.edu/dataset/848/secondary+mushroom+dataset

download_name <- tempfile()

download.file(
  "https://archive.ics.uci.edu/static/public/848/secondary+mushroom+dataset.zip",
  destfile = download_name
)

zip_name <- unzip(download_name, exdir = tempdir())
new_name <- unzip(zip_name,  exdir = tempdir())
csv_name <- grep("csv$", new_name, value = TRUE)
csv_name <- grep("secondary", csv_name, value = TRUE)

# ------------------------------------------------------------------------------

mushroom_secondary <- 
  read_delim(csv_name, delim = ";") %>% 
  clean_names() %>% 
  mutate(
    class = if_else(class == "p", "poisonous", "edible"),
    does_bruise_or_bleed = if_else(does_bruise_or_bleed, "yes", "no"),
    has_ring = if_else(has_ring, "yes", "no"),
    cap_shape = 
      case_when(
        cap_shape == "b" ~ "bell",
        cap_shape == "c" ~ "conical",
        cap_shape == "x" ~ "convex",
        cap_shape == "f" ~ "flat",
        cap_shape == "s" ~ "sunken",
        cap_shape == "p" ~ "spherical",
        TRUE ~ "others"
      ),
    cap_surface = 
      case_when(
        cap_surface == "i" ~ "fibrous",
        cap_surface == "g" ~ "grooves",
        cap_surface == "y" ~ "scaly",
        cap_surface == "s" ~ "smooth",
        cap_surface == "h" ~ "shiny",
        cap_surface == "l" ~ "leathery",
        cap_surface == "k" ~ "silky",
        TRUE ~ "sticky"
      ),
    cap_color = 
      case_when(
        cap_color == "n" ~ "brown",
        cap_color == "b" ~ "buff",
        cap_color == "g" ~ "gray",
        cap_color == "r" ~ "green",
        cap_color == "p" ~ "pink",
        cap_color == "u" ~ "purple",
        cap_color == "e" ~ "red",
        cap_color == "w" ~ "white",
        cap_color == "y" ~ "yellow",
        cap_color == "l" ~ "blue",
        cap_color == "o" ~ "orange",
        TRUE ~ "black"
      ),
    gill_attachment = 
      case_when(
        gill_attachment == "a" ~ "adnate",
        gill_attachment == "x" ~ "adnexed",
        gill_attachment == "d" ~ "decurrent",
        gill_attachment == "e" ~ "free",
        gill_attachment == "s" ~ "sinuate",
        gill_attachment == "p" ~ "pores",
        gill_attachment == "f" ~ "none",
        TRUE ~ "unknown"
      ),
    gill_spacing = 
      case_when(gill_spacing == "c" ~ "close",
                gill_spacing == "d" ~ "distant",
                TRUE ~ "none"),
    gill_color = 
      case_when(
        gill_color == "n" ~ "brown",
        gill_color == "b" ~ "buff",
        gill_color == "g" ~ "gray",
        gill_color == "r" ~ "green",
        gill_color == "p" ~ "pink",
        gill_color == "u" ~ "purple",
        gill_color == "e" ~ "red",
        gill_color == "w" ~ "white",
        gill_color == "y" ~ "yellow",
        gill_color == "l" ~ "blue",
        gill_color == "o" ~ "orange",
        gill_color == "k" ~ "black",
        TRUE ~ "none"
      ),
    stem_root = 
      case_when(
        stem_root == "b" ~ "bulbous",
        stem_root == "s" ~ "swollen",
        stem_root == "c" ~ "club",
        stem_root == "u" ~ "cup",
        stem_root == "e" ~ "equal",
        stem_root == "z" ~ "rhizomorphs",
        TRUE ~ "rooted"
      ),
    stem_surface =
      case_when(
        stem_surface == "i" ~ "fibrous",
        stem_surface == "g" ~ "grooves",
        stem_surface == "y" ~ "scaly",
        stem_surface == "s" ~ "smooth",
        stem_surface == "h" ~ "shiny",
        stem_surface == "l" ~ "leathery",
        stem_surface == "k" ~ "silky",
        stem_surface == "t" ~ "sticky",
        stem_surface == "w" ~ "wrinkled",
        stem_surface == "e" ~ "fleshy",
        TRUE ~ "none"
      ),
    stem_color =
      case_when(
        stem_color == "n" ~ "brown",
        stem_color == "b" ~ "buff",
        stem_color == "g" ~ "gray",
        stem_color == "r" ~ "green",
        stem_color == "p" ~ "pink",
        stem_color == "u" ~ "purple",
        stem_color == "e" ~ "red",
        stem_color == "w" ~ "white",
        stem_color == "y" ~ "yellow",
        stem_color == "l" ~ "blue",
        stem_color == "o" ~ "orange",
        stem_color == "k" ~ "black",
        TRUE~ "none"
      ),
    partial_veil = if_else(is.na(veil_type), "unknown", "partial"),
    veil_color = 
      case_when(
        veil_color == "n" ~ "brown",
        veil_color == "b" ~ "buff",
        veil_color == "g" ~ "gray",
        veil_color == "r" ~ "green",
        veil_color == "p" ~ "pink",
        veil_color == "u" ~ "purple",
        veil_color == "e" ~ "red",
        veil_color == "w" ~ "white",
        veil_color == "y" ~ "yellow",
        veil_color == "l" ~ "blue",
        veil_color == "o" ~ "orange",
        veil_color == "k" ~ "black",
        TRUE~ "none"
      ),
    ring_type = 
      case_when(
        ring_type == "c" ~ "cobwebby",
        ring_type == "e" ~ "evanescent",
        ring_type == "r" ~ "flaring",
        ring_type == "g" ~ "grooved",
        ring_type == "l" ~ "large",
        ring_type == "p" ~ "pendant",
        ring_type == "s" ~ "sheathing",
        ring_type == "z" ~ "zone",
        ring_type == "y" ~ "scaly",
        ring_type == "m" ~ "movable",
        ring_type == "f" ~ "none",
        TRUE ~ "unknown"
      ),
    spore_print_color = 
      case_when(
        spore_print_color == "n" ~ "brown",
        spore_print_color == "b" ~ "buff",
        spore_print_color == "g" ~ "gray",
        spore_print_color == "r" ~ "green",
        spore_print_color == "p" ~ "pink",
        spore_print_color == "u" ~ "purple",
        spore_print_color == "e" ~ "red",
        spore_print_color == "w" ~ "white",
        spore_print_color == "y" ~ "yellow",
        spore_print_color == "l" ~ "blue",
        spore_print_color == "o" ~ "orange",
        TRUE ~ "black"
      ),
    habitat = 
      case_when(
        habitat == "g" ~ "grasses",
        habitat == "l" ~ "leaves",
        habitat == "m" ~ "meadows",
        habitat == "p" ~ "paths",
        habitat == "h" ~ "heaths",
        habitat == "u" ~ "urban",
        habitat == "w" ~ "waste",
        TRUE ~ "woods"
      ),
    season = 
      case_when(
        season == "s" ~ "spring",
        season == "u" ~ "summer",
        season == "a" ~ "autumn",
        TRUE ~ "winter"
      ),
    across(where(is.character), as.factor)
  ) %>% 
  select(-veil_type)

# ------------------------------------------------------------------------------

set.seed(669)
shroom_split <- initial_validation_split(mushroom_secondary, prop = c(.7, .1))
shroom_train <- training(shroom_split)
shroom_val <- validation(shroom_split)
shroom_rs <- validation_set(shroom_split)
shroom_other <- testing(shroom_split)
cal_test_split <- initial_split(shroom_other, prop = 1/2)
shroom_cal <- training(cal_test_split)
shroom_test <- testing(cal_test_split)

save(shroom_train, shroom_val, shroom_cal, shroom_test, shroom_rs, 
     file = "RData/mushrooms.RData")

# ------------------------------------------------------------------------------
# Session versions

sessioninfo::session_info()

if ( !interactive() ) {
  q("no")
}

