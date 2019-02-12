import os
for i in range(10):
	os.system("jl nsga.jl")
	os.system("mv pontos pontos{0}".format(i))