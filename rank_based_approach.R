################################################################################ 
# R implementation of the rank-based approach proposed in 
# Vivek Nair, Tim Menzies, Norbert Siegmund, and Sven Apel. Using Bad Learners
# to Find Good Configurations. In 11th Joint Meeting on Foundations of Software
# Engineering (ESEC/FSE), page 257–267, Paderborn, Germany, 2017.
################################################################################ 
# Running the rank-based approach on BerkeleyDBC, 7z, and VP9
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
LIVES <- 10
INITIAL_TRAINING_SIZE <- 10
################################################################################ 

VERSION <- "Rank-based Approach"

# SPLs considered in the experiments.
# The SPLs' data are read from the "data" directory
SPLs <- c("BerkeleyDBC", "7z", "VP9")

SAMPLE_SIZE <- 1000

EXPERIMENTAL_RUNS <- 100

NROWS <- EXPERIMENTAL_RUNS*length(SPLs)

near_optimals <- tibble(
  version = rep(VERSION, NROWS),
  spl = rep(NA, NROWS),
  achieved_best_perf = rep(NA, NROWS),
)

source("./cart_hyperparameter_tuning.R")

i <- 1
while (i <= NROWS) {
  for (spl in SPLs) {
    writeLines(str_c("Running experiment ", i, " of ", NROWS, "..."))
    writeLines(str_c("Optimizing the performance of ", spl, "..."))
    
    data <- read.delim(str_c("./data/", spl, ".csv"), sep = ";")
    
    sample_indices <-
      sample(1:nrow(data), round(SAMPLE_SIZE), replace = FALSE)
    sample <- data[sample_indices,]
    
    validation_indices <- sample(1:nrow(sample),
                                 round(VALIDATION_SIZE * nrow(sample)),
                                 replace = FALSE)
    validation <- data[validation_indices,]
    training_pool <- sample[-validation_indices,]
    
    # shuffle the training pool
    training_pool = training_pool[sample(1:nrow(training_pool), replace =
                                           FALSE), ]
    
    last_rd <- Inf
    j <- INITIAL_TRAINING_SIZE
    lives <- LIVES
    while ((j <= nrow(training_pool)) && (lives > 0)) {
      train <- training_pool[1:j,]
      
      cart_recipe <-
        recipe(PERFORMANCE ~ ., data = train) %>%
        step_dummy(all_nominal_predictors())
      
      cart_params <-
        read.delim(str_c("./results/", spl, "_tuned_pars.csv"), sep = ";")
      cart_spec <-
        decision_tree(cost_complexity = cart_params$cost_complexity,
                      min_n = cart_params$min_n) %>%
        set_engine("rpart") %>%
        set_mode("regression")
      
      wflow <-
        workflow() %>%
        add_recipe(cart_recipe) %>%
        add_model(cart_spec)
      
      cart_fit <- fit(wflow, data = train)
      cart_validation_res <-
        predict(cart_fit, new_data = validation)
      validation_rank <- min_rank(validation$PERFORMANCE)
      validation_res_rank <- min_rank(cart_validation_res$.pred)
      rd <- mean(abs(validation_rank - validation_res_rank))
      
      if (rd >= last_rd) {
        lives <- lives - 1
      }
      last_rd <- rd
      j <- j + 1
      writeLines(str_c("last_rd=", last_rd, "; j=", j))
      
    }
    
    data <- data %>%
      mutate(PREDICTED_PERFORMANCE = predict(cart_fit, new_data = data)$.pred) %>%
      mutate(ACTUAL_RANK = min_rank(PERFORMANCE)) %>%
      mutate(PREDICTED_RANK = min_rank(PREDICTED_PERFORMANCE)) %>%
      mutate(ACTUAL_NORMALIZED_RANK = (ACTUAL_RANK-1)*100/(max(ACTUAL_RANK)-1)) %>%
      mutate(PREDICTED_NORMALIZED_RANK = (PREDICTED_RANK-1)*10/(max(ACTUAL_NORMALIZED_RANK)-1))
    predicted_optimal <- data %>%
      filter(PREDICTED_NORMALIZED_RANK == min(PREDICTED_NORMALIZED_RANK))  %>%
      sample_n(1) %>%
      select(ACTUAL_NORMALIZED_RANK)
    
    near_optimals[i, ]$spl <- spl
    near_optimals[i, ]$achieved_best_perf <- predicted_optimal[[1, 1]]
    i <- i + 1
  }
}

write.table(near_optimals,
            "./results/rank_based_approach.csv",
            sep=";",
            row.names = FALSE)

