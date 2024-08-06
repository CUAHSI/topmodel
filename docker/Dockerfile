# Use the R base image from the Rocker project
FROM rocker/r-ver:4.3.0

# Install system dependencies for R packages
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy R script (the full working example) into the container
COPY ./docker/Full_Run.R /usr/src/app

# Copy TOPMODEL source code into the container
COPY ../topmodel /usr/src/app/topmodel

# Install remotes package to manage package installations
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org/')"

# Install renv package from CRAN
RUN R -e "remotes::install_cran('renv', force = TRUE)"

# Install other R packages needed for your project
RUN R -e "install.packages(c('tinytex', 'xfun', 'htmlTable', 'topmodel', 'Hmisc'), repos='https://cloud.r-project.org/')"

# Run the R script
CMD ["Rscript", "Full_Run.R"]
