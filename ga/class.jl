mutable struct ga
	cx
	mr
	elitist
	population
	next_population
	fitness # every fitness
	total_fitness
	ga(cx, mr, pp) = new(cx, mr, Pair([], Inf), pp, [], [], 0)
end