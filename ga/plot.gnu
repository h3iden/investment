set encoding utf8
set xlabel "Risco"
set ylabel "Retorno"

set key bottom right box 1

plot "pontos" smooth sbezier title "nsga", "pontos" notitle

set term pngcairo size 800, 600 
set output "portfolios.png"
replot
set output