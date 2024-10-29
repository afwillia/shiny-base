FROM ubuntu:noble

RUN apt-get -y update && apt-get -y upgrade 
# The following is necessary to avoid an interactive prompt when installing r-base
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata wget
# instructions here: https://www.rstudio.com/products/shiny/download-server/ubuntu/
# additional instructions to install R 4.4 on ubuntu noble
# https://cran.r-project.org/bin/linux/ubuntu/#install-r
RUN apt update -qq -y
RUN apt install -y --no-install-recommends software-properties-common dirmngr
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu/noble-cran40/"
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
RUN apt install -y --no-install-recommends r-base
RUN apt-get install -y libssl-dev libcurl4-openssl-dev libxml2-dev jq pip sudo python3-venv cmake gdebi-core

RUN Rscript -e "install.packages('shiny', repos='http://cran.rstudio.com/')"
#RUN wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
RUN wget https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-18.04/x86_64/shiny-server-1.5.21.1007-amd64.deb
RUN gdebi --n shiny-server-1.5.21.1007-amd64.deb

# remove the default landing page and link to sample app's
RUN rm /srv/shiny-server/*

# overwrite the default config with our modified copy
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf 
RUN chmod 777 /etc/shiny-server/shiny-server.conf

# This is the app folder specified in shiny-server.conf
RUN mkdir -p /srv/shiny-server/app

# make the installation folder and library folder accessible to the 'shiny' user
RUN chmod -R 777 /srv/shiny-server/
RUN chmod -R 777 /usr/local/lib/R/site-library
RUN chmod -R 777 /var/lib/shiny-server

# This is where the app' will be installed
WORKDIR /srv/shiny-server/app

# Set up the entrypoint script
COPY ./startup.sh ./

# Run the server as the 'shiny' user
USER shiny

# Send application logs to stderr
ENV SHINY_LOG_STDERR=1
ENV SHINY_LOG_LEVEL=INFO

# start up the server
CMD ["./startup.sh"]
