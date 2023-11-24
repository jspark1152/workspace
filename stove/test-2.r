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

rec <- stove::prepForCV(data = data_train, formula = formula, imputation =T, normalization = T, seed = seed)

rec