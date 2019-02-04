set encoding utf8
set xlabel "Risco"
set ylabel "Retorno"

set key top right box 1
set style data points

# plot for [i=1:29] 'ef'.i title 'ef'.i
plot 'ef1' title 'NSGA'

set term pngcairo size 1200, 700 
set output "portfolios2.png"
replot
set output