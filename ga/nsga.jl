using DelimitedFiles
using StatsBase
using RandomNumbers
using Distributions
using CSV
using Statistics
using DataFrames
using Distributed

include("cvar.jl")
include("class.jl")
include("selection.jl")
include("crossover.jl")
include("mutation.jl")
include("markowicz.jl")

# include("ga.jl") --> Benchmark

# function params(solver::ga)
# 	println("Cx: ", solver.cx)
# 	println("Mr: ", solver.mr)
# 	println("Elitist: ", solver.elitist)
# 	println("Population + Fitness:")
# 	for i in 1:length(solver.fitness)
# 		println(solver.population[i], " : " , solver.fitness[i])
# 	end
# 	println("Fitness: ", solver.fitness)
# 	println("Total fitness: ", solver.total_fitness)
# end

function every_fitness(solver::ga, μ, risk)
	# points = []
	# solver.fitness = []
	if solver.next_population == []
		merged = solver.population
	else
		merged = [solver.population; solver.next_population]
	end

	points = [(-1.0, -1.0) for x in 1:length(merged)]
	solver.fitness = [(-1.0, -1.0) for x in 1:length(merged)]

	Threads.@threads for i in 1:length(merged)
		# original
		# var, ret = feetness(ind, μ, risk)
		# push!(points, (var, ret))
		# push!(solver.fitness, (var, ret))

		# adaptado pra threads
		var, ret = feetness(merged[i], μ, risk)
		points[i] = (var, ret)
		solver.fitness[i] = (var, ret)

	end

	# println(a)

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

# risco = variância
# function feetness(ind, μ, σ)
#     var, ret = 0.0, 0.0
#     for i in 1:length(ind)
#     	for j in i:length(ind)
# 	    	var += σ[i][j] * ind[i] * ind[j]
#     	end
#     	# expected portfolio return
# 	    ret += ind[i] * μ[i]
#     end
#     return var, ret
# end

# risco = cvar
function feetness(ind, μ, cvar)
	risk, ret = 0.0, 0.0
	for i in 1:length(ind)
		if ind[i] > 0
			ret += ind[i] * μ[i]
			risk += ind[i] * cvar[i]
		end
	end
 	return risk, ret
end

function random_solve(n)
	rng = MersenneTwisters.MT19937()

	# x = [0.0 for i in 1:n]
	# idx = sample(1:n, cardinality)
	# for i in idx
	# 	x[i] = rand(rng)
	# end
	# x /= sum(x)
	# return x

	x = rand(rng, n)
	x /= sum(x)
	return x
end

function scan(file)
	lines = readlines(file)
	return tryparse(Int32, lines[1]), tryparse(Int32, lines[2]), tryparse(Float32, lines[3]), tryparse(Int32, lines[4]), tryparse(Float32, lines[5]), tryparse(Float32, lines[6])
end

function reset_fitness(solver::ga)
	solver.fitness = []
	solver.total_fitness = 0
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

function data(frontier)
	file = "pontos"
	open(file, "w") do f
		for point in frontier
			write(f, string(point[1]) * " " * string(point[2]) * "\n")
		end
	end
	run(`gnuplot plot.gnu`)
	run(`display portfolios.png`)
end

file = "params.in"
it, pop_sz, β, cardinality, cx, mr = scan(file)


# markowicz
# T, μ, σ = markowicz_params()
# assets = length(T)
# pp = [random_solve(assets) for x in 1:pop_sz]
# solver = ga(cx, mr, pp)

# cvar
assets, μ, σ = params(β)
pp = [random_solve(length(assets)) for x in 1:pop_sz]
solver = ga(cx, mr, pp)

@time for i in 1:it
	if i % 50 == 0
		println(i)
	end

	frontiers, indexes = every_fitness(solver, μ, σ)

	selection = tourney4nsga(solver, 2, frontiers, indexes)
	
	arithmetic(solver, selection)
	
	mut4nsga(solver)
	
	frontiers, indexes = every_fitness(solver, μ, σ)
	
	println(frontiers[1])

	filter_population(solver, frontiers, indexes, pop_sz)

end

# for ind in solver.population
# 	println(ind, " ", sum(ind))
# end

println("threads = ", Threads.nthreads())
frontiers, indexes = every_fitness(solver, μ, σ)
data(frontiers[1])