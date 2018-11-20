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

# assets from yahoo into ./assets/
# function markowicz_params()
# 	T, assets, μ, R = [], [], [], []
# 	dir = "./assets/"
# 	files = readdir(dir)
# 	println(files)

# 	for i in 1:length(files)
# 		df = CSV.read(dir * files[i])
# 		# replaces the " " in the column name with a "_" for direct access
# 		rename!(df, Symbol("Adj Close") => Symbol("Adj_Close"))
# 		append!(T, CSV.nrow(df))
# 		push!(assets, df.Adj_Close)
# 		append!(μ, expected_return(assets[i], T[i]))
# 		append!(R, exact_return(assets[i], T[i]))
# 	end

# 	return T, μ, R
# end


# benchmark assets
function markowicz_params()
	T, μ, desvio = [], [], []
	file = "port5.txt"
	lines = readlines(file)
	n = tryparse(Int32, lines[1])

	for i = 1+1:n+1
		a, b = split(lines[i], " ")
		append!(μ, tryparse(Float64, a))
		append!(desvio, tryparse(Float64, b))
		append!(T, 1)
	end

	σ = [[0.0 for i in 1:n] for j in 1:n]
	for i in n+2:length(lines)
		x, y, cov = split(lines[i], " ")
		x = tryparse(Int32, x)
		y = tryparse(Int32, y)
		cov = tryparse(Float64, cov)
		σ[x][y] = cov
	end
	return T, μ, σ
end

function expected_return_for_every_day(asset)
	returns = [0 for i = 1:length(asset)]
	returns[1] = 0 # undefined value
	for i in 2:length(asset)
		returns[i] = asset[i] - asset[i-1] / asset[i-1]
	end
	return returns[2:end]
end

function calculate_count(β, total)
	return ceil((1 - β/100) * total)
end

# esqueleto, implementar depois

# asset = scan(...)
# returns = expected_return_for_every_day(asset)
# sorted_returns = sort!(returns)
# total_count = length(returns)
# idx = calculate_count(99, total_count) # returns the count that will be used for VaR / CVaR. param should be 95, 99 or 99.9
# var = sorted_returns[idx]
# cvar = (1 / idx) * sum(sorted_returns[1:idx])