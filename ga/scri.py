import os
for i in range(10):
	os.system("jl nsga.jl")
	os.system("mv pontos pontos{0}".format(i))

os.system("gnuplot plot.gnu")
os.system("display portfolios.png")

for i in range(10):
	os.system("rm pontos{0}".format(i))