using DelimitedFiles, StatsBase, RandomNumbers, Distributions, CSV, Statistics, DataFrames, Distributed
include("class.jl"), include("selection.jl"), include("crossover.jl"), include("mutation.jl"), include("markowicz.jl")

# include("ga.jl") --> Benchmark

function params(solver::ga)
	println("Cx: ", solver.cx)
	println("Mr: ", solver.mr)
	println("Elitist: ", solver.elitist)
	println("Population + Fitness:")
	for i in 1:length(solver.fitness)
		println(solver.population[i], " : " , solver.fitness[i])
	end
	println("Fitness: ", solver.fitness)
	println("Total fitness: ", solver.total_fitness)
end

function calc(solver::ga, ind, μ, σ, i)
	# println("afe")
    var, ret = feetness(ind, μ, σ)
	solver.fitness[i] = (var, ret)
	return (var, ret)	
end

# function every_fitness(solver::ga, μ, R)
function every_fitness(solver::ga, μ, σ)
	# points = []
	# solver.fitness = []
	if solver.next_population == []
		merged = solver.population
	else
		merged = [solver.population; solver.next_population]
	end

	points = [(-1.0, -1.0) for x in 1:length(merged)]
	solver.fitness = [(-1.0, -1.0) for x in 1:length(merged)]

	# https://stackoverflow.com/questions/37287020/how-and-when-to-use-async-and-sync-in-julia
	# https://juliacomputing.com/docs/press_pdfs/linux-magazine.pdf

	# Threads.@threads for ind in merged

	# a = cell(nworkers())
	a = [-1 for x in 1:nworkers()]
	# @sync for i in 1:length(merged)
	@sync for (idx, pid) in enumerate(workers())
		# original
		# var, ret = feetness(ind, μ, σ)
		# push!(points, (var, ret))
		# push!(solver.fitness, (var, ret))
		
		# adaptado pra threads
		# var, ret = feetness(merged[i], μ, σ)
		# points[i] = (var, ret)
		# solver.fitness[i] = (var, ret)
	
		# adaptado pra async --nao ta funcionando
		# println("id = ", myid(), " it = ", i)
		
		# println(length(merged))
		# @async points[i] = calc(solver, merged[i], μ, σ, i)

		println(idx, pid)
		@async a[idx] = remotecall_fetch(()->feetness(merged[idx], μ, σ), pid)

	end

	println(a)

	frontiers, indexes = nds(points)
	# println(frontiers)
	# println(indexes)
	return frontiers, indexes
end

insert_and_dedup!(v::Vector, x) = (splice!(v, searchsorted(v,x), [x]); v)

function dominates(p, q)
    if p[1] < q[1] && p[2] > q[2] # (var, ret)
    	return true
    else
    	return false
    end
end

function nds(points)
    frontiers, is = [], []
    original_points = copy(points)
    while !isempty(points)
		pl = []
    	push!(pl, points[1])
        # for i in 2:length(points)
	    	# p = points[i]
	    for p in points[2:end]
	    	pushfirst!(pl, p)
	    	remove_these = []
	    	for j in 2:length(pl)
	    		q = pl[j]
	    		if dominates(p, q)
	    			insert_and_dedup!(remove_these, j)
	    			# splice!(pl, j) # remove jth element (which is q) from pl
	    		else
	    			if dominates(q, p)
	    				insert_and_dedup!(remove_these, 1)
	    				# splice!(pl, 1) # remove 1st element (which is p) from pl
	    			end
	    		end
	    	end
	    	deleteat!(pl, remove_these)
	    end

	    # keep original indexes of points in each frontier
	    index = []
	    for p in pl
	    	push!(index, findfirst(isequal(p), original_points))
	    end
	    push!(is, index)
	    
	    push!(frontiers, pl)
	    filter!(x -> x ∉ pl, points)
	end
    return frontiers, is
end

# risco = variância bosta
@everywhere function feetness(ind, μ, σ)
    var, ret = 0.0, 0.0
    for i in 1:length(ind)
    	for j in i:length(ind)
	    	var += σ[i][j] * ind[i] * ind[j]
    	end
    	# expected portfolio return
	    ret += ind[i] * μ[i]
    end
    return var, ret
end

function calculate_count(β, tc)
	return ceil((1 - β/100) * tc)
end

function cvar(sorted_returns, β)
    total_count = length(sorted_returns)
    i = calculate_count(β, tc)
    return (1 / i) * sum(sorted_returns[1:i])
end

# risco = cvar
# function feetness(ind, assets_sorted_returns, μ)
# 	β = 99
# 	risk, ret = 0.0, 0.0
# 	for i in 1:length(ind)
# 		if ind[i] > 0
# 			ret += ind[i] * μ[i]
# 			risk += cvar(assets_sorted_returns[i], β)
# 		end
# 	end
#  	return risk, ret
# end

function random_solve(n)
	rng = MersenneTwisters.MT19937()
	x = rand(n)
	x /= sum(x)
	return x
end

function scan(file)
	lines = readlines(file)
	return tryparse(Int32, lines[1]), tryparse(Int32, lines[2]), tryparse(Float64, lines[3]), tryparse(Float64, lines[4])
end

function reset_fitness(solver::ga)
	solver.fitness = []
	solver.total_fitness = 0
end

function gambiarra(ind, μ, σ)
    v, r = 0.0, 0.0
    for i in 1:length(ind)
    	for j in i:length(ind)
	    	v += (σ[i][j] * ind[i] * ind[j])
    	end
    	r += ind[i] * μ[i]
    end
    return v, r
end

function ef(v, r)
	marks = [0 for i in 1:length(v)]
	for i in 1:length(v)
		for j in 1:length(r)
			if v[j] < v[i]
				if r[j] > r[i]
					marks[i] = 1
				end
			end
		end
	end
	return marks
end

function filter_by_distance(fitness, indexes, n)
    if n == 1
    	return [indexes[1]]
   	elseif n == 2
   		return [indexes[1], indexes[end]]
   	end

    obj = [[] for i in 1:length(fitness[1])]
    for i in 1:length(fitness[1])
    	for j in indexes
    		push!(obj[i], fitness[j][i])
    	end
    end

    # println("pop needs ", n)
    # println(obj)

    dist = [0.0 for i in 1:length(indexes)]
    dist[1], dist[end] = Inf, Inf
    for i in 1:length(obj)
    	sort!(obj[i])
    	for j in 2:length(indexes) - 1
    		dist[j] += (obj[i][j-1] - obj[i][j+1])
    	end
    end
    
    sorted = sort(dist)
    selected = [indexes[1], indexes[end]]
    for s in sorted[end-n+1:end-2]
    	push!(selected, indexes[findfirst(isequal(s), dist)])
    end
    # println(selected)
    return selected
end

function filter_population(solver::ga, frontiers, indexes, pop_sz)
	if solver.next_population == []
		old_population = solver.population
	else
		old_population = [solver.population; solver.next_population]
	end
	solver.population = []
	for is in indexes
		# println(is)
		if length(is) <= pop_sz
			for i in is
				push!(solver.population, old_population[i])
			end
			pop_sz -= length(is)
			if pop_sz == 0
				return
			end
		else # number will exceed, include the n points with biggest distance
			# println("pop has ", length(solver.population), " frontier has ", length(is))
			selected = filter_by_distance(solver.fitness, is, pop_sz)
			for s in selected
				push!(solver.population, old_population[s])
			end
			return
		end
	end
end

function data(frontiers)
	cont = 1
	for points in frontiers
		file = "test/ef" * string(cont)
		open(file, "w") do f
			for point in points
				write(f, string(point[1]) * " " * string(point[2]) * "\n")
			end
		end
		cont += 1
	end
end

file = "params.in"
it, pop_sz, cx, mr = scan(file)
# T, μ, R = markowicz_params()
T, μ, σ = markowicz_params()
assets = length(T)

pp = [random_solve(assets) for x in 1:pop_sz]

solver = ga(cx, mr, pp)

addprocs(100)
@time for i in 1:it
	# if i % 10 == 0
	# 	println(i)
	# end

	println(i)

	# tested everything, one step at a time - fixed?

	# frontiers, indexes = every_fitness(solver, μ, σ)
	# for i in 1:length(solver.population)
	# 	println(solver.fitness[i])
	# end
	# println(indexes)
	# selection = tourney4nsga(solver, 2, frontiers, indexes)
	# println(selection)
	
	# arithmetic(solver, selection)
	# frontiers, indexes = every_fitness(solver, μ, σ)
	# for i in 1:length(solver.population)
	# 	println(solver.fitness[i])
	# end
	# println(indexes)
	# # REIMPLANTAR ELITISMO E VER NO QUE DÁ!!

	# mut4nsga(solver)
	# frontiers, indexes = every_fitness(solver, μ, σ)
	# for i in 1:length(solver.population)
	# 	println(solver.fitness[i])
	# end
	# println(length(solver.fitness))
	# println(indexes)

	# filter_population(solver, frontiers, indexes, pop_sz)
	# frontiers, indexes = every_fitness(solver, μ, σ)
	# for i in 1:length(solver.population)
	# 	println(solver.fitness[i])
	# end
	# println(length(solver.fitness))
	# println(indexes)

	# for ind in solver.population
	# 	println(ind)
	# end
	# println(length(solver.population))

	# frontiers, indexes = every_fitness(solver, μ, σ)
	# println(length(solver.fitness))
	# println(length(solver.population))
	# selection = tourney4nsga(solver, 2, frontiers, indexes)
	# println(length(solver.fitness))
	# println(length(solver.population))
	# arithmetic(solver, selection)
	# println(length(solver.fitness))
	# println(length(solver.population))
	# mut4nsga(solver)
	# println(length(solver.fitness))
	# println(length(solver.population))
	# frontiers, indexes = every_fitness(solver, μ, σ)
	# println(length(solver.fitness))
	# println(length(solver.population))
	# filter_population(solver, frontiers, indexes, pop_sz)

	# frontiers, indexes = every_fitness(solver, μ, σ)
	# println(length(solver.fitness))
	# # println(length(solver.population))

	# do this
	frontiers, indexes = every_fitness(solver, μ, σ)
	# println(frontiers)
	# println(indexes)
	selection = tourney4nsga(solver, 2, frontiers, indexes)
	arithmetic(solver, selection)
	mut4nsga(solver)
	frontiers, indexes = every_fitness(solver, μ, σ)
	filter_population(solver, frontiers, indexes, pop_sz)

end

println("threads = ", Threads.nthreads())
frontiers, indexes = every_fitness(solver, μ, σ)
data(frontiers)

# vars, rets = [], []
# for ind in solver.population
# 	v, r = gambiarra(ind, μ, σ)
# 	push!(vars, v)
# 	push!(rets, r)
# end

# marks = ef(vars, rets)
# for i in 1:length(marks)
# 	if marks[i] == 0
# 		println(rets[i], " ", vars[i])
# 	end
# end

# println(solver.elitist)

# println("=======")
# for ind in solver.population
# 	feetness(ind, μ, σ)
# end