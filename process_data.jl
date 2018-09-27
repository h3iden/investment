using CSV

file = "gerdau.csv"
df = CSV.read(file)
println(df.Date)