set encoding utf8
set xlabel "Risco"
set ylabel "Retorno"

set key top right box 1

plot "ef1" smooth sbezier title "nsga", "ef1" with points notitle

set term pngcairo size 800, 600 
set output "portfolios.png"
replot
set output