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

file = "out"
lines = readlines(file)
vars, rets = [], []
for i in 1:length(lines)
	v, r = split(lines[i], " ")
	v = tryparse(Float64, v)
	r = tryparse(Float64, r)
	push!(vars, v)
	push!(rets, r)
end

marks = ef(vars, rets)
for i in 1:length(marks)
	if marks[i] == 0
		println(rets[i], " ", vars[i])
	end
end