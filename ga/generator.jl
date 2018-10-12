m = rand(0:1, 100, 100)

for i = 1:size(m, 1)
	for value in m[i, :]
		print(string(value) * " ")
	end
	println()
end
