library(caret)
library(tidymodels)
library(sf)
library(gganimate)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
ia_roads <- st_read(dsn = "R/iowa_highway.shp") # also requires iowa_highway.SHX

light_bg <- "#fcfefe"

# ------------------------------------------------------------------------------

data(ames)

# aspect ratio
diff(range(ames$Longitude)) / diff(range(ames$Latitude))

# Even though longitude and latitude are in the same units, we scale them to
# deal with the magnitude of the two sets of numbers.
ames_scaled <-
  ames %>%
  select(Longitude, Latitude) %>%
  mutate(scaled_lon = scale(Longitude)[,1], scaled_lat = scale(Latitude)[,1]) %>%
  select(starts_with("scaled"))
n <- nrow(ames)

# Select a data point near the middle
starter <-
  ames_scaled %>%
  mutate(
    .row = row_number(),
    dist = (scaled_lon)^2 + (scaled_lat)^2
  ) %>%
  slice_min(dist, n = 1) %>%
  pluck(".row")

ames_scaled_start <- ames_scaled[ starter,]
ames_scaled_pool  <- ames_scaled[-starter,]
ames_start <- ames[ starter,]
ames_pool  <- ames[-starter,]

n_added <- 24
n_selected <- n_added + 1
selection_path <- maxDissim(ames_scaled_start, ames_scaled_pool, n_added)
ames_seq <-
  bind_rows(ames_start, ames_pool[selection_path,]) %>%
  mutate(iteration = row_number())

# ------------------------------------------------------------------------------

ames_x <- extendrange(ames$Longitude)
ames_y <- extendrange(ames$Latitude)

all_ames <-
  ggplot() +
  xlim(ames_x) +
  ylim(ames_y) +
  theme(
    panel.background = element_rect(fill = light_bg, colour = NA),
    plot.background = element_rect(fill = light_bg, colour = NA),
    panel.grid = element_blank(),
    panel.border = element_blank(),
    plot.margin = unit(c(0, 0, 0, 0), "null"),
    panel.margin = unit(c(0, 0, 0, 0), "null"),
    axis.ticks = element_blank(),
    axis.text = element_blank(),
    axis.title = element_blank(),
    axis.line = element_blank(),
    legend.position = "none",
    axis.ticks.length = unit(0, "null"),
    axis.ticks.margin = unit(0, "null"),
    legend.margin = margin(0, 0, 0, 0, "null")
  ) +
  geom_sf(data = ia_roads, aes(geometry = geometry), alpha = .1) +
  geom_point(
    data = ames, aes(x = Longitude, y = Latitude),
    size = 1 / 8, alpha = 1
  )

# ------------------------------------------------------------------------------

base_cols <- RColorBrewer::brewer.pal(9, "YlOrRd")[-(1:2)]
ames_pal <- colorRampPalette(RColorBrewer::brewer.pal(9, "YlOrRd")[-(1:2)])(n_selected)

if (interactive()) {
  all_ames +
    geom_point(
      data = ames_seq,
      aes(x = Longitude, y = Latitude, col = format(iteration), size = -iteration),
      show.legend = FALSE
    ) +
    scale_color_manual(values = ames_pal) +
    scale_size(range = c(3, 8))
}

md_anim <-
  all_ames +
  geom_point(
    data = ames_seq,
    aes(x = Longitude, y = Latitude,col = format(iteration), size = -iteration),
    show.legend = FALSE
  ) +
  transition_states(
    iteration,
    transition_length = 2,
    state_length = 1
  ) +
  shadow_mark() +
  labs(title = "{closest_state} points selected") +
  scale_color_manual(values = ames_pal) +
  scale_size(range = c(3, 8))

animate(
  md_anim,
  device = "png",
  detail = 5,
  width = 1500,
  height = 1000,
  res = 200,
  renderer = gifski_renderer(),
  duration = 25
)

anim_save("premade/anime_ames_selection.gif")

