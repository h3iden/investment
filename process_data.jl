using CSV
using Statistics

file = "test.csv"
df = CSV.read(file)
println(df.Adj_Close)

T = CSV.nrow(df)

while true
    print(df.Adj_Close[rand(1:T)])
end