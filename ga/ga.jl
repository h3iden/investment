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

function every_fitness(solver::ga, μ, R)
	for ind in solver.population
		f = feetness(ind, μ, R)
		solver.total_fitness += f
		append!(solver.fitness, f)
		if f > solver.elitist[2]
			solver.elitist = Pair(ind, f)
		end
	end
end

function feetness(ind, μ, R)
    fit = 0.0
    ret = 0.0
    for i in 1:length(ind)
    	for j in 1:length(ind)
	    	if i != j
	    		# portfolio variance
	    		σij = asset_pair_variance(R[i], μ[i], R[j], μ[j])
	    		fit += (σij * ind[i] * ind[j])
	    	end
    	end
    	# expected portfolio return
	    ret += ind[i] * μ[i]
    end
    return ret - fit # maximize ret, minimize fit
end

function random_solve(n, total)
	rng = MersenneTwisters.MT19937()
	x = rand(0:total, n)
    return x / sum(x) * total
end

function scan(file)
	lines = readlines(file)
	return tryparse(Int32, lines[1]), tryparse(Float64, lines[2]), tryparse(Float64, lines[3]), tryparse(Int32, lines[4])
end

function reset_aux(solver::ga)
	solver.next_population = []
	solver.fitness = []
	solver.total_fitness = 0
end

file = "params.in"
pop_sz, cx, mr, capital = scan(file)
T, μ, R = markowicz_params()
assets = length(T)

pp = [random_solve(assets, capital) for x in 1:pop_sz]

solver = ga(cx, mr, pp)

params(solver)
println("T: ", T)
println("μ: ", μ)
println("R: ", R)

for i in 1:10
	every_fitness(solver, μ, R)
	selection = tourney(solver, 2)
	arithmetic(solver, selection)
	mut(solver)
	reset_aux(solver)
	println(i, " ", solver.elitist[2])	
	println(solver.population)
end
println(solver.elitist)