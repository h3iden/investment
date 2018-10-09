using CSV, Statistics, DataFrames, Devectorize

# asset's EXPECTED return over time t = [1, T]
function expected_return(assets, T)
	rj = 0.0
	for i in 2:T
		rj += (asset[i] - asset[i-1])
	end
	μj = (1 / T+1) * rj
	return μj
end

# asset's EXACT return over time t = [1, T]
function exact_return(assets, T)
	return asset[T] - asset[1]
end

function portfolio_variance(Rj, μj)
    acc = 0
    for i in 1:length(Rj)
    	acc += 
    end
end

file = "gerdau.csv"
df = CSV.read(file)

T = CSV.nrow(df)

# replaces the " " in the column name with a "_" for direct access
rename!(df, Symbol("Adj Close") => Symbol("Adj_Close"))

asset = df.Adj_Close

μj = expected_return(assets, T)
Rj = exact_return(assets, T)
c = portfolio_variance(Rj, μj)

println("T: ", T)
println("Exact: ", Rj)
println("Expected: ", μj)
println("Portfolio variance: ", c)