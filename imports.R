library(tidyverse)
library(dplyr)
library(glue)
library(stringr)
library(tibble)
library(jsonlite)
library(magrittr)
library(purrr)

file_sources <- list.files(c("api"), pattern = "\\.R$",
    full.names = TRUE, ignore.case = TRUE)
sapply(file_sources, source)
