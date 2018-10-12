include("class.jl")

function one_point_crossover(solver::ga, selected)
	rng = MersenneTwisters.MT19937()
	for s in selected
		ia, ib = solver.population[s[1]], solver.population[s[2]]
		ω = rand()
		if ω < solver.cx
			oa, ob = [], []
			p = rand(rng, 1:length(ia))
			append!(oa, ia[1:p]), append!(oa, ib[p+1:length(ib)])
			append!(ob, ib[1:p]), append!(ob, ia[p+1:length(ia)])
		else
			oa, ob = ia, ib
		end
		push!(solver.next_population, oa), push!(solver.next_population, ob)
	end
end

function two_point_crossover(solver::ga, selected)
	rng = MersenneTwisters.MT19937()
	for s in selected
		ia, ib = solver.population[s[1]], solver.population[s[2]]
		ω = rand()
		if ω < solver.cx
			oa, ob = [], []
			px, py = sort!(rand(rng, 1:length(ia), 2))
			append!(oa, ia[1:px-1]), append!(oa, ib[px:py]), append!(oa, ia[py+1:length(ia)])
			append!(ob, ib[1:px-1]), append!(ob, ia[px:py]), append!(ob, ib[py+1:length(ib)])
		else
			oa, ob = ia, ib
		end
		push!(solver.next_population, oa), push!(solver.next_population, ob)
	end
end

function blx(solver::ga, selected)
	α = 0.5 # standard
	for s in selected
		ia, ib = solver.population[s[1]], solver.population[s[2]]
		ω = rand()
		if ω < solver.cx
			oa, ob = [], []
			for i in 1:length(ia)
				Δ = abs(ia[i] - ib[i])
				lb = max(solver.lb, min(ia[i], ib[i]) - α*Δ)
				ub = min(solver.ub, max(ia[i], ib[i]) + α*Δ)
				if Δ != 0 
					d = Uniform(lb, ub)
					x, y = rand(d), rand(d)
				else
					x, y = lb, lb
				end
				append!(oa, x)
				append!(ob, y)
			end
		else
			oa, ob = ia, ib
		end
		push!(solver.next_population, oa), push!(solver.next_population, ob)
	end
end