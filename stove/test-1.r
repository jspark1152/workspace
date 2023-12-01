library(stove)
library(datatoys) #공공 데이터셋 패키지
library(dplyr)
library(hardhat)
library(ggplot2)

set.seed(1234)

cleaned_data <- datatoys::bloodTest
head(cleaned_data)
#SEX : 성별 남1 여2
#AGE_G : 연령
#HGB : 혈색소
#TCHOL : 총 콜레스테롤
#TG : 중성지방
#HDL : HDL 콜레스테롤
#ANE : 빈혈 진료여부 유1 무0
#IHD : 허혈심장질환 진료여부 유1 무0
#STK : 뇌혈관질환 진료여부 유1 무0
cleaned_data <- cleaned_data %>%
    mutate_at(vars(SEX, ANE, IHD, STK), factor) %>%
    #factor 함수로 변수를 범주화
    mutate(TG = ifelse(TG < 150, 0, 1)) %>%
    #TG 값을 2분화
    mutate_at(vars(TG), factor) %>%
    #TG를 범주화
    group_by(TG) %>%
    #TG의 갑 별로 그룹화 > summary 함수에서 그룹화된 결과 확인 가능
    sample_n(1000)

head(cleaned_data)

#2. DATA Setup
#target_var : 목적 변수
#train_set_ratio : 전체 데이터 중 train set의 비율(0.0 - 1.0)
target_var <- "TG"
train_set_ratio <- 0.7
seed <- 1234
formula <- paste0(target_var, " ~ .") #formula는 target_var 입력할 때 함께 생성

split_tmp <- stove::trainTestSplit(data = cleaned_data, target = target_var, prop = train_set_ratio, seed = seed)

data_train <- split_tmp[[1]] #train data set
data_test <- split_tmp[[2]] #test data set
data_split <- split_tmp[[3]] #whole data with split info
summary(data_train)

rec <- stove::prepForCV(data = data_train, formula = formula, imputation =T, normalization = T, seed = seed)
algo <- 'Logistic Regression'
engine <- 'glmnet'
mode <- 'classification'
model <- parsnip::logistic_reg(
  penalty = tune(),
  mixture = tune()
) %>%
  parsnip::set_engine(engine = engine) %>%
  parsnip::set_mode(mode = mode) %>%
  parsnip::translate()

model

tunedWorkflow <- workflows::workflow()
tunedWorkflow
tunedWorkflow <- tunedWorkflow %>% workflows::add_recipe(rec) %>% workflows::add_model(model)
tunedWorkflow

folds <- rsample::vfold_cv(data_train, v = 2, strata = rec$var_info$variable[rec$var_info$role == "outcome"])
folds

gridNum <- 5
initial <- ifelse(model$engine == 'kknn', gridNum, length(model$args) * gridNum)
initial

iter <- 10

model$args
quo_name(model$args$mtry)

if (quo_name(model$args$mtry) == "tune()") {
    param <- tunedWorkflow %>%
      hardhat::extract_parameter_set_dials() %>%
      recipes::update(mtry = dials::finalize(mtry(), trainingData))

    set.seed(seed = as.numeric(seed))
    result <-
      tunedWorkflow %>%
      tune::tune_bayes(folds, initial = initial, iter = iter, param_info = param)
  } else {
    set.seed(seed = as.numeric(seed))
    result <-
      tunedWorkflow %>%
      tune::tune_bayes(folds, initial = initial, iter = iter)
  }


list(tunedWorkflow = tunedWorkflow, result = result)
result
summary(result)
head(result)
glimpse(result)
result$splits[[1]][1]

bayes_opt_result <- list(tunedWorkflow =tunedWorkflow, result = result)

optResult <- list(tunedWorkflow = tunedWorkflow, result = result)
optResult[[2]]
metric <- 'roc_auc'
bestParams <- tune::select_best(optResult[[2]], metric)
bestParams
summary(bestParams)
bestParams[[1]]
bestParams[[2]]
bestParams[[3]]
finalSpec <- tune::finalize_model(model, bestParams)
finalSpec

finalModel <- finalSpec %>% fit(eval(parse(text = formula)), data_train)
finalModel
summary(finalModel)
#plot(finalModel$fit)

finalModel$spec

lambda_min <- bestParams[[2]]

coef(finalModel$fit, s = lambda_min)

optResult[[1]]
finalFittedModel <-
  optResult[[1]] %>%
  workflows::update_model(finalSpec) %>%
  tune::last_fit(data_split)

modelName = paste0(algo, "_", engine)

finalFittedModel$splits
finalFittedModel$.predictions[[1]]
finalFittedModel$.predictions[[1]] <- finalFittedModel$.predictions[[1]] %>%
    dplyr::mutate(model = modelName)
finalFittedModel$.predictions[[1]]

finalized <- list(finalModel =finalModel, finalFittedModel = finalFittedModel, bestParams = bestParams)
finalized <- list(finalized = finalized, bayes_opt_result = bayes_opt_result)

models_list <- list()
models_list[[paste0(algo, '_', engine)]] <- finalized$finalized$finalFittedModel

commnet = '
roc_curve <- stove::rocCurve(
  modelsList = models_list,
  targetVar = target_var
)

roc_curve
'

modelsList <- models_list
targetVar <- target_var

modelsList
length(modelsList)
tmp <- do.call(rbind, modelsList)[[5]]
tmp
tmp <- tmp %>% do.call(rbind, .)
tmp
tmp <- tmp %>% dplyr::group_by(model)
tmp

colors <- grDevices::colorRampPalette(c("#C70A80", "#FBCB0A", "#3EC70B", "#590696", "#37E2D5"))

plot <- do.call(rbind, modelsList)[[5]] %>%
  do.call(rbind, .) %>%
  dplyr::group_by(model) %>%
  yardstick::roc_curve(
    truth = targetVar,
    .pred_1,
    event_level = 'second'
  ) %>%
  ggplot(
    aes(
      x = 1 - specificity,
      y = sensitivity,
      color = model
    )
  ) +
  labs(
    title = 'ROC curve',
    x = 'False Positive Rate (1-Specificity)',
    y = 'True Positive Rate (Sensitivity)'
  ) +
  geom_line(size = 1.1) +
  geom_abline(slope = 1, intercept = 0, size = 0.5) +
  scale_color_manual(values = colors(length(modelsList))) + #values 값으로 컬러 팔렛 리스트
  coord_fixed() +
  cowplot::theme_cowplot()

plot

names(models_list)
model_name <- 'Logistic Regression_glmnet'
modelName = model_name
modelsList = models_list
targetVar = target_var

tmpDf <- modelsList[[modelName]] %>%
  tune::collect_predictions() %>% #.pred tibble을 기준으로 튜닝
  as.data.frame() %>% #데이터프레임으로 변환
  dplyr::select(targetVar, .pred_class)
  #Target변수 / 예측값만 Select하여 DF 구성

confDf <- stats::xtabs(~ tmpDf$.pred_class + tmpDf[[targetVar]])

input.matrix <- data.matrix(confDf)
confusion <- as.data.frame(as.table(input.matrix))
colnames(confusion)[1] <- 'y_pred'
colnames(confusion)[2] <- 'actual_y'
colnames(confusion)[3] <- 'Frequency'
confusion

plot <- ggplot(confusion, aes(x = actual_y, y = y_pred, fill = Frequency)) +
  geom_tile() +
  geom_text(aes(label = Frequency)) +
  scale_x_discrete(name = 'Actual Class') +
  scale_y_discrete(name = 'Predicted Class') +
  geom_text(aes(label = Frequency), colour = 'black') +
  scale_fill_continuous(high = '#E9BC09', low = '#F3E5AC')

plot

options(yardstick.event_level = 'second')
evalMet <- stove::evalMetricsC(models_list, target_var)
knitr::kable(evalMet)