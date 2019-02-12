set encoding utf8
set xlabel "Risco"
set ylabel "Retorno"

set key bottom right box 1

filename(n) = sprintf("pontos%d", n)
plot for [i=0:9] filename(i) smooth sbezier title "nsga", for [i=0:9] filename(i) with points notitle

set term pngcairo size 800, 600 
set output "portfolios.png"
replot
set output