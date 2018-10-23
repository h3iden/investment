set encoding utf8
set xlabel "Retorno"
set ylabel "Risco"

set key top right box 1
set style data points

plot 'out' title "Portfólios"

set term pngcairo size 700, 480 
set output "portfolios.png"
replot
set output