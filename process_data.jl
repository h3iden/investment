using CSV
using Statistics
using DataFrames

# asset's expected return over time t = [1, T]
function expected_return(asset, T)
	rj = 0.0
	for i in 2:T
		rj += (asset[i] - asset[i-1])
	end
	μj = (1 / T+1) * rj
	return μj
end

file = "gerdau.csv"
df = CSV.read(file)

T = CSV.nrow(df)

# replaces the " " in the column name with a "_" for direct access
rename!(df, Symbol("Adj Close") => Symbol("Adj_Close"))

asset = df.Adj_Close

μj = expected_return(asset, T)

println("T: ", T)
println(μj)