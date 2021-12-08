library(targets)
library(tarchetypes)

source("R/functions.R")
source("R/helpers.R")

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("scales", "tidyverse", "hrbrthemes"))

list(
  tar_target(
    baseline_file,
    "../outputs/data_sharing rerun-baseline-table.csv",
    format = "file"
  ),
  tar_target(
    baseline,
    read_experiments(baseline_file)
  ),
  tar_target(
    baseline_detail_file,
    "../outputs/data_sharing baseline-detail-table.csv",
    format = "file"
  ),
  tar_target(
    baseline_detail,
    read_experiments(baseline_detail_file)
  ),
  tar_target(
    baseline_end_file,
    "../outputs/data_sharing baseline-end-table.csv",
    format = "file"
  ),
  tar_target(
    baseline_end,
    read_experiments(baseline_end_file)
  ),
  tar_render(baseline_report, "03-analyse-baseline.Rmd"),
  tar_target(
    data_sharing_file,
    "../outputs/data_sharing sharing-funders-2-table.csv",
    format = "file"
  ),
  tar_target(
    data_sharing,
    read_experiments(data_sharing_file)
  ),
  tar_render(sharing_report, "05-data-sharing.Rmd"),
  tar_target(
    funding_mechanism_file,
    "../outputs/data_sharing pubs-vs-data-table.csv",
    format = "file"
  ),
  tar_target(
    funding_mechanism,
    read_experiments(funding_mechanism_file)
  ),
  tar_render(funding_mechanism_report, "06-funding-mechanisms.Rmd"),
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
