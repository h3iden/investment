using CSV, DataFrames

function scan_assets()
	T, assets = [], []
	dir = "./assets/"
	files = readdir(dir)
	println(files)

	for i in 1:length(files)
		df = CSV.read(dir * files[i])
		# replaces the " " in the column name with a "_" for direct access
		rename!(df, Symbol("Adj Close") => Symbol("Adj_Close"))
		append!(T, CSV.nrow(df))
		push!(assets, df.Adj_Close)
	end

	return assets, T
end

function expected_return(asset, T)
	rj = 0.0
	for i in 2:T
		rj += (asset[i] - asset[i-1])
	end
	μj = (1 / (T-1)) * rj
	return μj
end

function μ(asset)
	returns = [0.0 for i = 1:length(asset)]
	returns[1] = 0.0 # undefined value
	for i in 2:length(asset)
		returns[i] = asset[i] - asset[i-1] / asset[i-1]
	end
	return returns[2:end]
end

function calculate_count(β, total)
	return ceil(Int, (1 - β/100) * total)
end

function cvar(assets, samples_sizes)
	risk = 0.0
	for i in 1:length(assets)
		returns = μ(assets[i])
		sorted_returns = sort!(returns)
		total_count = samples_sizes[i]
		idx = calculate_count(99, total_count) # returns the count that will be used for VaR / CVaR. param should be 95, 99 or 99.9
		# risk += sorted_returns[idx] # VaR
		risk += (1 / idx) * sum(sorted_returns[1:idx]) # CVaR
	end
	return risk
end

function params()
	assets, samples_sizes = scan_assets()
	risk = cvar(assets, samples_sizes)
    μ = []
    for i in 1:length(assets)
    	push!(μ, expected_return(assets[i], samples_sizes[i]))
    end
    return assets,  samples_sizes, μ
end

# precisa calcular cada cvar (apenas 1 vez) e multiplicar pelo investimento pra ver o total de possivel perda