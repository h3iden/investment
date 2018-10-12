using CSV, Statistics, DataFrames

function f()
    a = 5
    b = 10
    return a, b
end

# function f()
# 	r = rand(0:0, 100)
# 	a, b = rand(1:1, 100), rand(1:1, 100)
# 	for i in 1:10000000
# 		@. r += a + b # broadcast the + operator
# 		# r += a + b
# 	end
# 	return r
# end

# @time r = f()
# println(r)

x = readdir("./assets/")
println(x)
c, d = f()
println(c, d)