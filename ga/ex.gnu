set encoding utf8
set xlabel "Retorno"
set ylabel "Risco"

set key top right box 1
set style data points

plot 'portef1.txt'

set term pngcairo size 1200, 700 
set output "example.png"
replot
set output