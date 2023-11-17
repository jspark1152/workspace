library(rsample)
rsample::initial_split
rsample::mc_cv
set.seed(0)
iris_mc <- mc_cv(iris)
iris_mc
length(iris_mc)
iris_mc$splits[[1]]
summary(iris_mc$splits[[1]])
class(iris_mc$splits[[1]])
iris_mc$splits[[1]][[2]]

iris_mc <- mc_cv(iris)
iris_mc$splits[[1]]



iris_mc <- initial_split(iris)
summary(iris_mc)
iris_mc

getAnywhere(strata_check)