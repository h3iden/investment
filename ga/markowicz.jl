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