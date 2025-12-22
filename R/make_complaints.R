library(tidymodels)
library(lubridate)
library(readr)
library(stringr)
library(forcats)
library(janitor)
library(survival)
library(sf)

# -------------------------------------------------------------------------
# Based on https://www.tidymodels.org/learn/statistics/survival-case-study/
# https://data.cityofnewyork.us/Housing-Development/DOB-Complaints-Received/eabe-havv/about_data
# https://www.nyc.gov/site/buildings/safety/inspection-units.page
# https://www.nyc.gov/site/brooklyncb1/about/community-boards-explained.page

# File pulled on 2025-12-22, 450 MB
complaints_raw <-
  read_csv("DOB_Complaints_Received_20251222.csv") %>%
  clean_names()

complaints_init <-
  complaints_raw %>%
  mutate(
    date_entered = mdy(date_entered),
    date_disposition = mdy(disposition_date),
    days_to_disposition = difftime(
      pmin(date_disposition, dob_run_date),
      date_entered,
      units = "days"
    ) %>%
      as.numeric(),
    year_entered = year(date_entered),
    week_entered = week(date_entered),

    borough = str_sub(complaint_number, 1, 1),
    borough = case_when(
      borough == "1" ~ "Manhattan",
      borough == "2" ~ "Bronx",
      borough == "3" ~ "Brooklyn",
      borough == "4" ~ "Queens",
      borough == "5" ~ "Staten Island"
    ),
    borough = gsub(" ", "_", tolower(borough)),
    borough = factor(borough),

    inspection_unit = gsub("([[:punct:]])", "", unit),
    inspection_unit = gsub(" ", "", inspection_unit),
    inspection_unit = factor(inspection_unit),

    special_district = if_else(
      is.na(special_district),
      "None",
      special_district
    ),
    special_district = fct_relevel(special_district, "None"),

    community_board = factor(community_board),

    complaint_category = factor(complaint_category),

    zip_code = factor(zip_code),

    event_time = Surv(days_to_disposition, status == "CLOSED")
  ) |>
  filter(!is.na(status)) |>
  filter(days_to_disposition > 0) |>
  select(
    days_to_disposition,
    status,
    year_entered,
    date_entered,
    week_entered,
    borough,
    special_district,
    inspection_unit,
    community_board,
    complaint_category,
    zip_code,
    event_time
  )

recent_data <-
  complaints_init |>
  filter(year(date_entered) %in% 2023:2024)

# ------------------------------------------------------------------------------
# Make class value

deadline <- 250
data_filter <- parsnip:::graf_weight_time_vec(recent_data$event_time, deadline)

recent_data <- recent_data[!is.na(data_filter), ]
sum(!is.na(data_filter))

# Give some buffer for most recent data
week_lag <- 4
first_complaint <- min(recent_data$date_entered)
first_complaint_lag <- first_complaint - weeks(week_lag)
difftime(first_complaint, first_complaint_lag)
max_date <- max(recent_data$date_entered)

two_year_complaints <-
  recent_data %>%
  filter(date_entered < max_date - week_lag) |>
  mutate(
    class = if_else(days_to_disposition < deadline, "yes", "no"),
    class = factor(class)
  ) %>%
  select(-days_to_disposition, -status, -event_time) %>%
  relocate(class)

two_year_complaints |> count(class)
mean(two_year_complaints$class == "no")

# ------------------------------------------------------------------------------
# Not currently used but code kept in case we change our mind

historical_data <-
  two_year_complaints |>
  filter(year_entered == 2023) |>
  select(week_entered, class) |>
  summarize(
    historical_rate = mean(class == "no"),
    historical_num_entered = length(class),
    .by = c(week_entered)
  )

complaints_with_hist <-
  two_year_complaints |>
  filter(year_entered == 2024 & !is.na(class)) |>
  # full_join(historical_data, by = c("week_entered")) |>
  select(-year_entered) |>
  mutate(day = yday(date_entered)) |>
  arrange(day)

complaints_with_hist |> count(class)
mean(complaints_with_hist$class == "no", na.rm = TRUE)

# ------------------------------------------------------------------------------
# Get data from the modeldatatoo version of the data and extract the priority
priority <-
  modeldatatoo::building_complaints |>
  distinct(complaint_category, complaint_priority) |>
  mutate(
    complaint_priority = as.character(complaint_priority),
    complaint_priority = ifelse(
      is.na(complaint_priority),
      "U",
      complaint_priority
    ),
    complaint_priority = factor(complaint_priority)
  )

complaints_with_priority <-
  full_join(complaints_with_hist, priority, by = join_by(complaint_category)) |>
  select(-date_entered, -week_entered, -contains("histor"))

# Remove a very small number of missing values
complaints <-
  complaints_with_priority[complete.cases(complaints_with_priority), ]


# ------------------------------------------------------------------------------
# Shapefile for plot

# https://data.cityofnewyork.us/Health/Modified-Zip-Code-Tabulation-Areas-MODZCTA-Map/5fzm-kpwv
library(sf)
nyc_geo_data <- st_read(
  "Modified_Zip_Code_Tabulation_Areas_(MODZCTA)_20251222.geojson"
)

st_write(nyc_geo_data, "nyc_shapefile.shp")

nyc_map <- st_read("nyc_shapefile.shp")

complaints_by_zip <-
  complaints |>
  summarize(
    `Percent Unresolved` = mean(class == "no") * 100,
    .by = c(zip_code)
  ) |>
  mutate(
    modzcta = as.character(zip_code, )
  )

complaints_by_zip <- full_join(
  nyc_map,
  complaints_by_zip,
  by = join_by(modzcta)
)

# ------------------------------------------------------------------------------

save(complaints, file = "RData/complaints.RData")
save(complaints_by_zip, file = "RData/complaints_by_zip.RData")
