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

split_tmp <- stove::trainTestSplit(data = cleaned_data,
                                    target = target_var,
                                    prop = train_set_ratio,
                                    seed = seed
                                    )

data_train <- split_tmp[[1]]
data_test <- split_tmp[[2]]
data_split <- split_tmp[[3]]

rec <- stove::prepForCV(data = data_train,
                        formula = formula,
                        seed = seed
                        )

models_list <- list()
tuned_results_list <- list()

mode <- "regression"
algo <- "linearRegression"
engine <- "glmnet"
v <- 2
metric <- "rmse"
gridNum <- 5
iter <- 10
seed <- 1234

finalized <- stove::linearRegression(
    algo =algo,
    engine = engine,
    mode = mode,
    trainingData = data_train,
    splitedData = data_split,
    formula = formula,
    rec = rec,
    v = v,
    gridNum =gridNum,
    iter = iter,
    metric = metric,
    seed = seed
)

models_list[[paste0(algo, "_", engine)]] <- finalized$finalized$finalFittedModel
tuned_results_list[[paste0(algo, "_", engine)]] <- finalized$bayes_opt_result

names(models_list)
model_name <- "linearRegression_glmnet"

"
rp <- stove::regressionPlot(modelName = model_name,
                            modelsList = models_list,
                            targetVar = target_var)

rp

evalMet <- stove::evalMetricsR(models_list, target_var)
knitr::kable(evalMet)

rmse_plot <- stove::plotRmseComparison(tunedResultsList = tuned_results_list,
                                        v = v,
                                        iter = iter)

rmse_plot
"
#regressionPlot 분석
#인수로 modelName, modelsList, targetVar 받음
models_list
tmpDf <- models_list[[model_name]]

tmpDf
tmpDf <- models_list[[model_name]] %>%
            tune::collect_predictions()
tmpDf

lims <- c(min(tmpDf[[target_var]]), max(tmpDf[[target_var]]))

lims

plot <- models_list[[model_name]] %>%
            tune::collect_predictions() %>%
            ggplot(aes(x = eval(parse(text = target_var)),
                        y = models_list[[model_name]]$.predictions[[1]][1]$.pred)) +
                    theme(
                        panel.grid.major = element_blank(),
                        panel.grid.minor = element_blank(),
                        panel.background = element_blank(),
                        axis.line = element_line(colour = "#C70A80")
                    ) +
                    labs(
                        title = "Regression Plot (Actual vs Predicted)",
                        x = "Actual Value",
                        y = "Predicted Value"
                    ) +
                    geom_abline(color = "black", lty = 2) +
                    geom_point(alpha = 0.8, colour = "#C70A80") +
                    scale_x_continuous(limits = lims) +
                    scale_y_continuous(limits = lims)

plot