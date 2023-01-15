FROM rstudio/plumber
RUN Rscript -e 'install.packages(c("googleComputeEngineR", "readr", "gh", "glue", "jsonlite", "future"))'

COPY ./ /

EXPOSE 8000/tcp
CMD ["/api.R"]
