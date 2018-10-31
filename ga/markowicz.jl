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
	file = "port1.txt"
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

# ind -> portfolio || R -> assets' exact_return over time 1:T
function portfolio_loss(ind, R, α) # f(X, R) = Σi=1:T Σ j=1:n -(rjt * xj)
    loss = 0.0
    for i in 1:length(R)
    	for j in 1:length(R[i])
    		loss -= (R[i][j] * ind[i] - α)
    	end
    end
    return loss
end

# α = var()
function cvar(ind, R, α, β)
	α + 1 / (length(R[1]) * (1 - β)) * portfolio_loss(ind, R, α)
end