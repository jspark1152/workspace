#' Train-Test Split
#'
#' @details
#' Separate the entire data into a training set and a test set.
#'
#' @param data  Full data set with global preprocess completed.
#' @param target The target variable.
#' @param prop  Proportion of total data to be used as training data.
#' @param seed  Seed for reproducible results.
#'
#' @import rsample
#' @importFrom tidyselect all_of
#'
#' @export

#함수 정의
trainTestSplit <- function(data = NULL,
                           target = NULL,
                           prop,
                           seed = "4814") {
  set.seed(seed = as.numeric(seed)) #난수를 4814개 생성 > 데이터셋 개수가 엄청 많진 않은듯
  dataSplit <- rsample::initial_split(data, strata = tidyselect::all_of(target), prop = as.numeric(prop))
  #initial_split 내부에 mc_cv 교차검증 함수가 선행 > 25번의 교차 검증을 진행 > 그중 1번째 샘플링을 이용
  train <- rsample::training(dataSplit)
  test <- rsample::testing(dataSplit)

  return(list(train = train, test = test, dataSplit = dataSplit, target = target))
}


#' Preprocessing for cross validation
#'
#' @details
#' Define the local preprocessing method to be applied to the training data for each fold when the training data is divided into several folds.
#'
#' @param data  Training dataset to apply local preprocessing recipe.
#' @param formula formula for modeling
#' @param imputation If "imputation = TRUE", the model will be trained using cross-validation with imputation.
#' @param normalization If "normalization = TRUE", the model will be trained using cross-validation with normalization
#' @param nominalImputationType Imputation method for nominal variable (Option: mode(default), bag, knn)
#' @param numericImputationType Imputation method for numeric variable (Option: mean(default), bag, knn, linear, lower, median, roll)
#' @param normalizationType Normalization method (Option: range(default), center, normalization, scale)
#' @param seed seed
#'
#' @rawNamespace import(recipes, except = c(step))
#'
#' @export

prepForCV <- function(data = NULL,
                      formula = NULL,
                      imputation = FALSE,
                      normalization = FALSE,
                      nominalImputationType = "mode",
                      numericImputationType = "mean",
                      normalizationType = "range",
                      seed = "4814") {
  set.seed(seed = as.numeric(seed))

  # one-hot encoding
  result <- recipes::recipe(eval(parse(text = formula)), data = data) %>%
    recipes::step_dummy(recipes::all_nominal_predictors())
    #명목형 변수를 원본 데이터의 수준에 해당하는 이항으로 변환

  # Imputation
  if (imputation == TRUE) {
    if (!is.null(nominalImputationType)) {
      cmd <- paste0("result <- result %>% recipes::step_impute_", nominalImputationType, "(recipes::all_nominal_predictors())")
      #명목형 변수의 결측값을 해당 변수의 트레이닝 세트의 mode로 대체
      #mode : 데이터 분포에서 관측치가 높은 부분 ex) 정규분포에서는 평균 = mode
      eval(parse(text = cmd))
    }
    if (!is.null(numericImputationType)) {
      cmd <- paste0("result <- result %>% recipes::step_impute_", numericImputationType, "(recipes::all_numeric_predictors())")
      #수치형 변수의 결측값을 해당 변수의 트레이닝 세트의 평균으로 대체
      eval(parse(text = cmd))
    }
  }

  # Normalization
  if (normalization == TRUE) {
    if (!is.null(normalizationType)) {
      cmd <- paste0("result <- result %>% recipes::step_", normalizationType, "(recipes::all_numeric_predictors())")
      #수치형 데이터를 사전 정의된 값 범위 내에 있도록 정규화
      eval(parse(text = cmd))
    }
  }

  return(result)
}