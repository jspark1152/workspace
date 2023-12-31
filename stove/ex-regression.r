library(stove)
library(datatoys)
library(dplyr)
library(ggplot2)
set.seed(1234)
cleaned_data <- datatoys::bloodTest
cleaned_data <- cleaned_data %>%
  mutate_at(vars(SEX, ANE, IHD, STK), factor) %>%
  sample_n(1000)

target_var <- "TG"
train_set_ratio <- 0.7
seed <- 1234
formula <- paste0(target_var, " ~ .")

split_tmp <- stove::trainTestSplit(
  data = cleaned_data,
  target = target_var,
  prop = train_set_ratio,
  seed = seed
)
data_train <- split_tmp[[1]] # train data
data_test <- split_tmp[[2]] # test data
data_split <- split_tmp[[3]] # whole data with split information

rec <- stove::prepForCV(
  data = data_train,
  formula = formula,
  seed = seed
)

models_list <- list()
tuned_results_list <- list()

mode <- "regression"
algo <- "linearRegression"
engine <- "glmnet" # glmnet (default)
v <- 2
metric <- "rmse" # rmse (default), rsq
gridNum <- 5
iter <- 10
seed <- 1234

finalized <- stove::linearRegression(
  algo = algo,
  engine = engine,
  mode = mode,
  trainingData = data_train,
  splitedData = data_split,
  formula = formula,
  rec = rec,
  v = v,
  gridNum = gridNum,
  iter = iter,
  metric = metric,
  seed = seed
)

models_list[[paste0(algo, "_", engine)]] <- finalized$finalized$finalFittedModel
tuned_results_list[[paste0(algo, "_", engine)]] <- finalized$bayes_opt_result

names(models_list)
model_name <- "linearRegression_glmnet"

rp <- stove::regressionPlot(
  modelName = model_name,
  modelsList = models_list,
  targetVar = target_var
)
rp

evalMet <- stove::evalMetricsR(models_list, target_var)
knitr::kable(evalMet)


tunedResultsList <- tuned_results_list
v <- v
iter <- iter

combined_rmse_df <- data.frame()
model_name <- names(tunedResultsList)

for (i in seq_along(tunedResultsList)) {
  iter_df_merge <- data.frame()
  for (j in seq(v + 1, v + v * iter, by = 1)) {
    # model's name
    custom_name <- model_name[i] %>%
      as.data.frame()
    colnames(custom_name) <- "model"

    # iteration
    iteration <- j - v %>%
      as.data.frame()
    colnames(iteration) <- "iteration"

    # rmse value
    rmse_value <- tunedResultsList[[i]]$result$.metrics[[j]] %>%
      dplyr::filter(.metric == "rmse") %>%
      dplyr::pull(.estimate) %>%
      as.data.frame()
    colnames(rmse_value) <- "rmse_value"

    tmp <- cbind(custom_name, iteration, rmse_value)
    iter_df_merge <- rbind(iter_df_merge, tmp)
  }
  combined_rmse_df <- rbind(combined_rmse_df, iter_df_merge)
}

rmse_summary <- combined_rmse_df %>%
    group_by(model) %>%
    dplyr::summarize(
      mean_rmse = mean(rmse_value),
      rmse_se = sd(rmse_value) / sqrt(n())
    ) %>%
    mutate(
      lower_bound = mean_rmse - 1.96 * rmse_se,
      upper_bound = mean_rmse + 1.96 * rmse_se
    )

colors <- grDevices::colorRampPalette(c("#C70A80", "#FBCB0A", "#3EC70B", "#590696", "#37E2D5"))

  rmse_plot <- ggplot(rmse_summary, aes(x = model, y = mean_rmse, 
                      ymin = lower_bound, ymax = upper_bound, 
                      color = model)) +
    geom_point(size = 3) +
    geom_errorbar(width = 0.2) +
    scale_color_manual(values = colors(length(tunedResultsList))) +
    labs(
      title = "RMSE Comparison",
      x = "Model",
      y = "Mean RMSE"
    ) +
    cowplot::theme_cowplot() +
    theme(
      axis.title.x = element_blank(),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      panel.grid.major.y = element_line(color = "grey", linetype = "solid"),
      panel.grid.minor.y = element_line(color = "grey", linetype = "dashed")
    )
  
rmse_plot