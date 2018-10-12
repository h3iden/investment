include("class.jl")

function tourney(solver::ga, x)
	selected = []
	rng = MersenneTwisters.MT19937()
	for i in 1:length(solver.population) / 2
		picks = sample(rng, 1:length(solver.population), x, replace = false)
		candidates = [(solver.fitness[i], i) for i in picks]
		sort!(candidates)
		# if min
		s = Pair(candidates[1][2], candidates[2][2])
		# else s = Pair(candidates[length(candidates) - 1][2], candidates[length(candidates)][2])
		push!(selected, s)
	end
	return selected
end