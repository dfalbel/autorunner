FROM rstudio/plumber
RUN Rscript -e 'install.packages(c("googleComputeEngineR", "readr", "gh", "glue", "jsonlite", "future", "purrr"))'

COPY ./ /service
COPY ../task.R /

EXPOSE 8000/tcp
CMD ["/service/api.R"]
