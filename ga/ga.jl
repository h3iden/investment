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
	for ind in solver.population
		f = feetness(ind, μ, σ)
		solver.total_fitness += f
		append!(solver.fitness, f)
		if f > solver.elitist[2]
			solver.elitist = Pair(ind, f)
		end
	end
end

# function feetness(ind, μ, R)
function feetness(ind, μ, σ)
    var = 0.0
    ret = 0.0
    for i in 1:length(ind)
    	for j in i:length(ind)
	    	# portfolio variance
	    	# σij = asset_pair_variance(R[i], μ[i], R[j], μ[j])
	    	# println(i, " ", j, " ", σij)
	    	var += (σ[i][j] * ind[i] * ind[j])
    	end
    	# expected portfolio return
	    ret += ind[i] * μ[i]
    end
    # println(ret, " ", var, " ", ret-var)
    return ret - var # maximize ret, minimize var
end

function random_solve(n)
	rng = MersenneTwisters.MT19937()
	x = rand(n)
	x /= sum(x)
	return x
end

function scan(file)
	lines = readlines(file)
	return tryparse(Int32, lines[1]), tryparse(Float64, lines[2]), tryparse(Float64, lines[3])
end

function reset_aux(solver::ga)
	solver.next_population = []
	solver.fitness = []
	solver.total_fitness = 0
end

function gambiarra(ind, μ, σ)
    var = 0.0
    ret = 0.0
    for i in 1:length(ind)
    	for j in i:length(ind)
	    	# portfolio variance
	    	# σij = asset_pair_variance(R[i], μ[i], R[j], μ[j])
	    	# println(i, " ", j, " ", σij)
	    	var += (σ[i][j] * ind[i] * ind[j])
    	end
    	# expected portfolio return
	    ret += ind[i] * μ[i]
    end
    println(ret, " ", var)
end

file = "params.in"
pop_sz, cx, mr = scan(file)
# T, μ, R = markowicz_params()
T, μ, σ = markowicz_params()
assets = length(T)

pp = [random_solve(assets) for x in 1:pop_sz]

solver = ga(cx, mr, pp)

# params(solver)
# println("T: ", T)
# println("μ: ", μ)
# println("R: ", R)

for i in 1:1000
	# every_fitness(solver, μ, R)
	every_fitness(solver, μ, σ)
	selection = tourney(solver, 2)
	arithmetic(solver, selection)
	mut(solver)
	reset_aux(solver)
	# println(i, " ", solver.elitist[2])	
end

for ind in solver.population
	gambiarra(ind, μ, σ)
end

# println(solver.elitist)

# println("=======")
# for ind in solver.population
# 	feetness(ind, μ, σ)
# end