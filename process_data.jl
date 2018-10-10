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

function asset_pair_variance(Ri, Rj, μi, μj)
    return (Ri - μi) * (Rj - μj)
end

function portfolio_variance(x, R, μ)
    acc = 0.0
    for i in 1:length(x, R, μ)
    	for j in 1:length(x)
    		σij = asset_pair_variance(R[i], μ[i], R[j], μ[j])
    		acc += (σ * x[i] * x[j])
    	end
    end
    return acc
end

T, assets, μ, R = [], [], [], []
files = readdir("./assets/")
id = 1
for file in files
	df = CSV.read(file)
	# replaces the " " in the column name with a "_" for direct access
	rename!(df, Symbol("Adj Close") => Symbol("Adj_Close"))
	append!(T, CSV.nrow(df))
	push!(assets, df.Adj_Close)
	append(μ, expected_return(assets[id], T[id]))
	append!(R, exact_return(assets[id], T[id]))
	id += 1
end


# file = "assets/gerdau.csv"

# T = CSV.nrow(df)


# asset = df.Adj_Close

c = portfolio_variance(Rj, μj)

println("T: ", T)
println("Exact: ", Rj)
println("Expected: ", μj)
println("Portfolio variance: ", c)