install.packages(c('repr', 'IRdisplay', 'evaluate', 'crayon', 'pbdZMQ', 'devtools', 'uuid', 'digest') , repos='https://mirror.ibcp.fr/pub/CRAN/' )
devtools::install_github('IRkernel/IRkernel')
IRkernel::installspec()


