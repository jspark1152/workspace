a <- '5+5'
eval(parse(text = a))

for(i in 1:5){
    a <- 'i+i'
    print(eval(parse(text = a)))
}