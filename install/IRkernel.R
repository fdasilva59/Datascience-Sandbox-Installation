install.packages(c('repr', 'IRdisplay', 'evaluate', 'crayon', 'pbdZMQ', 'devtools', 'uuid', 'digest') , repos='https://mirror.ibcp.fr/pub/CRAN/' )
devtools::install_github('IRkernel/IRkernel', force=TRUE)
IRkernel::installspec()


