library(stove)
library(datatoys)
library(dplyr)
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

rmse_plot <- stove::plotRmseComparison(
  tunedResultsList = tuned_results_list,
  v = v,
  iter = iter
)
rmse_plot