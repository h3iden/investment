using DelimitedFiles, StatsBase, RandomNumbers, Distributions, CSV, Statistics, DataFrames
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

# function every_fitness(solver::ga, μ, R)
function every_fitness(solver::ga, μ, σ)
	points = []
	if solver.next_population == []
		merged = solver.population
	else
		merged = [solver.population; solver.next_population]
	end
	for ind in merged
		ret, var = feetness(ind, μ, σ)
		push!(points, (ret, var))
		push!(solver.fitness, (ret, var))
	end
	frontiers, indexes = nds(points)
	return frontiers, indexes
end

insert_and_dedup!(v::Vector, x) = (splice!(v, searchsorted(v,x), [x]); v)

function dominates(p, q)
    if p[1] < q[1] && p[2] > q[2]
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

function feetness(ind, μ, σ)
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

function filter_by_distance(fitness, indexes, n, old_population)
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

    println("pop needs ", n)
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
			println("pop has ", length(solver.population), " frontier has ", length(is))
			selected = filter_by_distance(solver.fitness, is, pop_sz, old_population)
			append!(solver.population, selected)
			return
		end
	end
end

function data(frontiers, i)
	cont = 1
	for points in frontiers
		file = "plots/plots" * string(i) * "/ef" * string(cont)
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

for i in 1:it
	println(i)

	# every_fitness(solver, μ, R)
	frontiers, indexes = every_fitness(solver, μ, σ)
	
	# filter_population(solver, frontiers, indexes, pop_sz)
	
	# solver.next_population = []

	selection = tourney4nsga(solver, 2, frontiers, indexes)
	# println("len pop = ", length(solver.population), " len sel = ", length(selection), " len next = ", length(solver.next_population))
	arithmetic(solver, selection)
	mut4nsga(solver)
	# println("len pop = ", length(solver.population))
	
	reset_fitness(solver)
	filter_population(solver, frontiers, indexes, pop_sz)
	
	solver.next_population = []
	# println(i, " ", solver.elitist[2])	

	if i % 100 == 0
		data(frontiers, Int64(i / 100))
	end
end


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