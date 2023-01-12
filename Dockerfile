FROM rstudio/plumber
RUN Rscript -e 'install.packages(c("googleComputeEngineR", "readr", "gh", "glue", "jsonlite"))'

COPY api.R /

EXPOSE 8000/tcp
CMD ["/api.R"]
