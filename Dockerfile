FROM rstudio/plumber

COPY api.R /

EXPOSE 8000/tcp
CMD ["/api.R"]
