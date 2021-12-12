library(targets)
library(tarchetypes)

source("R/functions.R")
source("R/helpers.R")

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("scales", "tidyverse", "hrbrthemes"))

list(
  # calibration ------
  tar_target(
    leiden_file,
    "../external_data/CWTS Leiden Ranking 2020.xlsx",
    format = "file"
  ),
  tar_target(
    leiden,
    read_leiden(leiden_file)
  ),
  tar_target(
    italy_groups,
    "../external_data/group_sizes.txt",
    format = "file"
  ),
  tar_target(
    italy,
    read_delim(italy_groups, delim = " ", skip = 2, 
               col_names = c("id", "n_researchers", 
                             "n_publications"),
               col_types = "cii-")
  ),
  tar_render(calibration_report, "01-calibration.Rmd"),
  # baseline file -----------
  tar_target(
    baseline_file,
    "../outputs/data_sharing 01-baseline-table.csv",
    format = "file"
  ),
  tar_target(
    baseline,
    read_experiments(baseline_file)
  ),
  tar_target(
    baseline_detail_file,
    "../outputs/data_sharing 02-baseline-detail-table.csv",
    format = "file"
  ),
  tar_target(
    baseline_detail,
    read_experiments(baseline_detail_file)
  ),
  tar_target(
    baseline_end_file,
    "../outputs/data_sharing 03-baseline-end-table.csv",
    format = "file"
  ),
  tar_target(
    baseline_end,
    read_nested_experiment(baseline_end_file)
  ),
  tar_render(baseline_report, "03-analyse-baseline.Rmd"),
  
  # data sharing experiment --------------
  tar_target(
    data_sharing_file,
    "../outputs/data_sharing 04-sharing-funders-table.csv",
    format = "file"
  ),
  tar_target(
    data_sharing,
    read_experiments(data_sharing_file)
  ),
  tar_render(sharing_report, "05-data-sharing.Rmd"),
  
  # another data sharing experiment ----
  tar_target(
    funding_mechanism_file,
    "../outputs/data_sharing 05-pubs-vs-data-table.csv",
    format = "file"
  ),
  tar_target(
    funding_mechanism,
    read_experiments(funding_mechanism_file)
  ),
  tar_render(funding_mechanism_report, "06-funding-mechanisms.Rmd"),
  
  # incentives for data sharing ------
  tar_target(
    incentives_file,
    "../outputs/data_sharing benefit-of-awarding-data-sharing-table.csv",
    format = "file"
  ),
  tar_target(
    incentives,
    read_nested_experiment(incentives_file)
  ),
  tar_render(incentives_report, "07-incentives.Rmd")
)
