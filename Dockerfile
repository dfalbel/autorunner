FROM rstudio/plumber
RUN Rscript -e 'install.packages(c("googleComputeEngineR", "readr", "gh", "glue", "jsonlite"))'

COPY api.R /
COPY bootstrap.sh /
COPY $GCE_AUTH_FILE /

EXPOSE 8000/tcp
CMD ["/api.R"]
