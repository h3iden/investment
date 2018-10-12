include("class.jl")

function elitism(solver::ga)
	solver.next_population[1] = solver.elitist[1]
end

function gaussian(solver::ga)
	d = Normal(0.0, 1.0) # Normal(μ = 0.0, σ = 0.5), σ = 1.0 also works
	for ind in solver.next_population
		for i in 1:length(ind)
			ω = rand()
			if ω < solver.mr
				ind[i] += rand(d)
			end
		end
		clamp!(ind, solver.lb, solver.ub)
	end
	elitism(solver)
	solver.population = solver.next_population
end

function delta(solver::ga)
	d = Uniform(solver.lb, solver.ub)
	for ind in solver.next_population
		for i in 1:length(ind)
			ω = rand()
			if ω < solver.mr
				α = rand(d)
				ω = rand()
				ω > 0.5 ? ind[i] += α : ind[i] -= α
			end
		end
		clamp!(ind, solver.lb, solver.ub)
	end
	elitism(solver)
	solver.population = solver.next_population
end