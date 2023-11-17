#1. Import DATA
#Global preproc = 중복값 제거, 원-핫 인코딩, 피처 선택
#Local preproc = Imputaton, Scaling, Oversampling

library(stove)
library(datatoys) #공공 데이터셋 패키지
library(dplyr)

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
    mutate(TG = ifelse(TG < 150, 0, 1)) %>%
    mutate_at(vars(TG), factor) %>%
    group_by(TG) %>%
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

rec <- stove::prepForCV(data = data_train, formula = formula, imputation =T, normalization = T, seed = seed)

#3. Modeling
#algo : 사용자 정의 알고리즘명
#engine : 알고리즘 구현 engine 선택
#mode : 분류/회귀 선택
#trainingData : 훈련 데이터 셋
#splitedData : 분할 정보가 담긴 전체 데이터 셋
#formula : Target 변수와 Feature 변수를 정의한 formula
#rec : 교차 검증에서 각 fold에 적용할 local preproc. 정보를 담은 recipe
#v : 교차 검증 시 훈련 셋을 몇 번 분할할 것인지 입력
#gridNum : 각 하이퍼 파라미터 별로 몇 개의 그리드를 할당해 베이지안 최적화를 할지 설정
#iter : 베이지안 최적화 시 반복 횟수
#metric : Best performance에 대한 평가지표 선택
#seed : 결과 재현을 위한 시드값 설정

models_list <- list()

#(1) Logistic Regression
mode <- "classification"
algo <- "logisticRegression"
engine <- "glmnet"
v <- 2
metric <- "roc_auc"
gridNum <- 5
iter <- 10
seed <- 1234

finalized <- stove::logisticRegression(
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
) #Modeling

models_list[[paste0(algo, "_", engine)]] <- finalized$finalized$finalFittedModel

#(2) K Nearest Neighbor
mode <- "classification"
algo <- "KNN"
engine <- "kknn"
v <- 2
metric <- "roc_auc"
gridNum <- 5
iter <- 10
seed <- 1234

finalized <- stove::KNN(
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
) #Modeling

models_list[[paste0(algo, "_", engine)]] <- finalized$finalized$finalFittedModel

#(3) Naive Bayes
mode <- "classification"
algo <- "naiveBayes"
engine <- "naivebayes"
v <- 2
metric <- "roc_auc"
gridNum <- 5
iter <- 10
seed <- 1234

finalized <- stove::naiveBayes(
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
) #Modeling

models_list[[paste0(algo, "_", engine)]] <- finalized$finalized$finalFittedModel

#(4) Decision Tree
mode <- "classification"
algo <- "decisionTree"
engine <- "partykit"
v <- 2
metric <- "roc_auc"
gridNum <- 5
iter <- 10
seed <- 1234

finalized <- stove::decisionTree(
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
) #Modeling

models_list[[paste0(algo, "_", engine)]] <- finalized$finalized$finalFittedModel

#(5) Random Forest
mode <- "classification"
algo <- "randomForest"
engine <- "randomForest"
v <- 2
metric <- "roc_auc"
gridNum <- 5
iter <- 10
seed <- 1234

finalized <- stove::randomForest(
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
) #Modeling

models_list[[paste0(algo, "_", engine)]] <- finalized$finalized$finalFittedModel

#(6) XGBoost
mode <- "classification"
algo <- "XGBoost"
engine <- "xgboost"
v <- 2
metric <- "roc_auc"
gridNum <- 5
iter <- 10
seed <- 1234

finalized <- stove::xgBoost(
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
) #Modeling

models_list[[paste0(algo, "_", engine)]] <- finalized$finalized$finalFittedModel

#(7) lightGBM
mode <- "classification"
algo <- "lightGBM"
engine <- "lightgbm"
v <- 2
metric <- "roc_auc"
gridNum <- 5
iter <- 10
seed <- 1234

finalized <- stove::lightGbm(
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
) #Modeling

models_list[[paste0(algo, "_", engine)]] <- finalized$finalized$finalFittedModel

#(8) MLP
mode <- "classification"
algo <- "MLP"
engine <- "nnet"
v <- 2
metric <- "roc_auc"
gridNum <- 5
iter <- 10
seed <- 1234

finalized <- stove::MLP(
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
) #Modeling

models_list[[paste0(algo, "_", engine)]] <- finalized$finalized$finalFittedModel

#(9) SVM -Linear Kernel
mode <- "classification"
algo <- "SVM_linear"
engine <- "kernlab"
v <- 2
metric <- "roc_auc"
gridNum <- 5
iter <- 10
seed <- 1234

finalized <- stove::SVMLinear(
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
) #Modeling

models_list[[paste0(algo, "_", engine)]] <- finalized$finalized$finalFittedModel

#Sources for report
roc_curve <- stove::rocCurve(
    modelsList = models_list,
    targetVar = target_var
)

roc_curve