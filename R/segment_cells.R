# ------------------------------------------------------------------------------
# Code to create the segmented cells in the introduction. Images from
# http://www.cellimagelibrary.org/project/P2043

library(EBImage)
library(janitor)
library(dplyr)

# ------------------------------------------------------------------------------

imagefiles <-
  list.files(path = "MP6843_img_full/",
             pattern = "F04_1056",
             full.names = TRUE)


nuc <- normalize(readImage(imagefiles[2]))
cel <- normalize(readImage(imagefiles[1]))

## ----range--------------------------------------------------------------------
apply(raw_cells, 3, range)

cells <- normalize(raw_cells)

apply(cells, 3, range)

colored_cells <- 
  rgbImage(
    red   = getFrame(cells, nuc_ind),
    blue = getFrame(cells, cel_ind)
  )
plot(colored_cells)
# ------------------------------------------------------------------------------

## segment nuclei
nmask = thresh(nuc, 40, 40, 0.004)
nmask = opening(nmask, makeBrush(9, shape='disc'))
nmask = fillHull(nmask)
nmask = bwlabel(nmask)
plot(nmask)

## segment cells, using propagate and nuclei as 'seeds'
ctmask = opening(cel > 0.05, makeBrush(5, shape = 'disc'))
cmask = propagate(cel, nmask, ctmask)
cel_labs <- bwlabel(cmask)
plot(cmask)

## using paintObjects to highlight objects
res = paintObjects(cmask, colored_cells, col='#ff00ff')
res = paintObjects(nmask, res, col='#ffff00')


# ------------------------------------------------------------------------------

x_vals <- 800:1170
y_vals <- 600:940


plot(1 - res[x_vals, y_vals,])

plot(colored_cells[x_vals,  y_vals,])


writeImage(
  res[x_vals, y_vals,], 
  file = "~/tmp/aml4td/premade/segmented.png", 
  type = "png"
)
writeImage(
  colored_cells[x_vals, y_vals,], 
  file = "~/tmp/aml4td/premade/cells.png", 
  type = "png"
)

writeImage(
  1 - res[x_vals, y_vals,], 
  file = "~/tmp/aml4td/premade/segmented_inv.png", 
  type = "png"
)
writeImage(
  1 - colored_cells[x_vals, y_vals,], 
  file = "~/tmp/aml4td/premade/cells_inv.png", 
  type = "png"
)


nuclear_feat = 
  computeFeatures(nmask, nuc, xname = "nucleus", refnames = "nucleus") %>% 
  as_tibble() %>% 
  clean_names() %>% 
  select(nucleus_y = nucleus_nucleus_m_cy, nucleus_x = nucleus_nucleus_m_cx,
         nucleus_eccentricity = nucleus_nucleus_m_eccentricity, 
         nucleus_area = nucleus_0_s_area, nucleus_mean = nucleus_nucleus_b_mean) 



cell_tubulin = 
  computeFeatures(cmask, cel, xname = "cell") %>% 
  as_tibble() %>% 
  clean_names() %>% 
  select(cell_eccentricity = cell_0_m_eccentricity, 
         cell_area = cell_0_s_area, cell_mean = cell_cell_tubulin_b_mean) %>% 
  mutate(
    object_id = row_number()
  )

# finding the objects: 
# plot(res)
# text(
#   joint_features$nucleus_x,
#   joint_features$nucleus_y,
#   pch = 1:nrow(joint_features),
#   col = "white"
# )


joint_features <- 
  bind_cols(nuclear_feat, cell_tubulin) %>% 
  filter(nucleus_area < cell_area) %>% 
  slice(c(8, 9, 12, 13)) %>% 
  select(-nucleus_y, -nucleus_x)

joint_features %>% 
  mutate(across(everything(), ~ round(.x, 5))) %>% 
  datapasta::tribble_paste()

