function ef(points)
	marks = [0 for i in 1:length(points)]
	for i in 1:length(points)
		for j in 1:length(points)
			if v[j][1] < v[i][1]
				if r[j][2] > r[i][2]
					marks[i] = 1
				end
			end
		end
	end
	return marks
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
    pl = []
    push!(pl, points[1])
    for i in 2:length(points)
    	p = points[i]
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
    return pl
end

file = "out"
lines = readlines(file)
points = []
for i in 1:length(lines)
	v, r = split(lines[i], " ")
	v = tryparse(Float64, v)
	r = tryparse(Float64, r)
	push!(points, (v, r))
end

pts = nds(points)
for i in 1:length(pts)
	println(pts[i][1], " ", pts[i][2])
end

# marks = ef(points)
# for i in 1:length(marks)
# 	if marks[i] == 0
# 		println(marks[1], " ", marks[2])
# 	end
# end