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

function markowicz_params()
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

	return T, μ, R
end
