################################################################################ 
# R implementation of the rank-based approach proposed in 
# Vivek Nair, Tim Menzies, Norbert Siegmund, and Sven Apel. Using Bad Learners
# to Find Good Configurations. In 11th Joint Meeting on Foundations of Software
# Engineering (ESEC/FSE), page 257–267, Paderborn, Germany, 2017.
################################################################################ 
# CART Hyperparameter tuning on BerkeleyDBC, 7z, and VP9
################################################################################ 

library(tidyverse)
library(tidymodels)
library(rpart)

################################################################################ 
# Parameters proposed in the implementation accompanying the paper:
# https://github.com/ai-se/Reimplement/blob/cleaned_version/rank_based_sampling.py
################################################################################ 
# The sample is splitted as:
# * For the whole population: training pool (40%), validation pool (20%) and 
#   testing pool (40%)
# * Therefore, scaling the proportions for a sample training pool (67%) and 
#   validation (33%)
VALIDATION_SIZE <- 0.33
################################################################################ 

SAMPLE_SIZE <- 1000

# Number of levels considered in for each hyperparameter
LEVELS <- 10

# SPLs considered in the experiments.
# The SPLs' data are read from the "data" directory
SPLs <- c("BerkeleyDBC", "7z", "VP9")

for (spl in SPLs) {
  writeLines(str_c("Tuning hyperparameters for ", spl, "..."))
  
  data <- read.delim(str_c("./data/", spl, ".csv"), sep = ";")
  
  sample_indices <- sample(1:nrow(data), round(SAMPLE_SIZE))
  sample <- data[sample_indices,]
  
  cart_recipe <- 
    recipe(PERFORMANCE ~ ., data = sample) %>%
    step_dummy(all_nominal_predictors())
  
  cart_spec <- 
    decision_tree(cost_complexity = tune(), min_n = tune()) %>% 
    set_engine("rpart") %>% 
    set_mode("regression")
  
  wflow <- 
    workflow() %>%
    add_recipe(cart_recipe) %>%
    add_model(cart_spec) 
  
  cart_folds <- vfold_cv(sample, v=10)
  cart_tune <-
    wflow %>%
    tune_grid(
      cart_folds,
      grid = extract_parameter_set_dials(cart_spec) %>% 
        grid_regular(levels=LEVELS)
    )
  select_best(cart_tune) %>% 
    select(-.config) %>%
    write.table(str_c("./results/", spl, "_tuned_pars.csv"),
                row.names = FALSE,
                sep = ";")
}



