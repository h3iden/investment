using CSV, Statistics, DataFrames

# asset's EXPECTED return over time t = [1, T]
function expected_return(asset, T)
	rj = 0.0
	for i in 2:T
		rj += (asset[i] - asset[i-1])
	end
	μj = (1 / T+1) * rj
	return μj
end

# asset's EXACT return over time t = [1, T]
function exact_return(asset, T)
	return asset[T] - asset[1]
end

function asset_pair_variance(Ri, Rj, μi, μj)
    return (Ri - μi) * (Rj - μj)
end

function portfolio_variance(x, R, μ)
    acc = 0.0
    for i in 1:length(x)
    	for j in 1:length(x)
	    	if i != j
	    		σij = asset_pair_variance(R[i], μ[i], R[j], μ[j])
	    		acc += (σij * x[i] * x[j])
	    		println(acc)
	    	end
    	end
    end
    return acc
end

T, assets, μ, R = [], [], [], []
dir = "./assets/"
files = readdir(dir)
println(files)

for i in 1:length(files)
	df = CSV.read(dir * files[i])
	# replaces the " " in the column name with a "_" for direct access
	rename!(df, Symbol("Adj Close") => Symbol("Adj_Close"))
	append!(T, CSV.nrow(df))
	push!(assets, df.Adj_Close)
	append!(μ, expected_return(assets[i], T[i]))
	append!(R, exact_return(assets[i], T[i]))
end

capital = [5000, 15000]
c = portfolio_variance(capital, R, μ)

println("T: ", T)
println("Exact: ", R)
println("Expected: ", μ)
println("Portfolio variance: ", c)