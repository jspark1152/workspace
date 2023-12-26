library(stove)
library(datatoys)
library(dplyr)

set.seed(1234) #난수의 시드를 설정 > 난수를 재현케 함

cleaned_data <- datatoys::bloodTest

cleaned_data <- cleaned_data %>%
                sample_n(1000) %>% #1000개의 랜덤 샘플링
                subset(select = -c(TG)) #TG열 제외

max_k <- 15 
n_start <- 25 
iter_max <- 10
n_boot <- 100
algorithm <- "Hartigan-Wong"
select_optimal <- "silhouette"
seed <- 6471

km_model <- stove::kMeansClustering(data = cleaned_data,
                                    maxK = max_k, #최대 클러스터 수
                                    nStart = n_start, #각 클러스터 수에 대한 초기 중심점 설정 횟수
                                    iterMax = iter_max, #최대 반복 횟수
                                    nBoot = n_boot, #부트스트랩 샘플링 횟수
                                    algorithm = algorithm, #군집화 알고리즘 = 'Hartigan-Wong'
                                    selectOptimal = select_optimal, #최적 클러스터 수 선택 기준 = 'silhouette'
                                    seedNum = seed #난수 시드
                                    )

#여러 클러스터로 군집화하고, 최적 클러스터 수를 기준으로 선택 > 군집화된 데이터를 나타내는 km_model 객체 생성
km_model


#km_model$result
#km_model$elbowPlot
#km_model$optimalK
#km_model$clustVis


cl_vis <- stove::clusteringVis(data = cleaned_data,
                          model = km_model$result,
                          maxK = "15",
                          nBoot = "100",
                          selectOptimal = "silhouette",
                          seedNum = "6471")

cl_vis[3]