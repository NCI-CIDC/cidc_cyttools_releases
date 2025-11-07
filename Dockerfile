# Base image 
FROM amd64/ubuntu:24.04
MAINTAINER Frankie Parks <frankie.parks@bioappdev.org>

## Run all root level commands 1st
# Create a user and group used to launch processes
# Assigned pipeline user to 999 ID; keep UID pinned at 1000
RUN groupadd -r pipeline -g 999 && useradd -u 999 -r -g pipeline -m -d /home/pipeline -s /bin/bash -c "pipeline user" pipeline && chmod 755 /home/pipeline && chown pipeline:pipeline /home/pipeline

 #Create mount point directory
RUN mkdir -p /media/analysis && chmod 777 /media/analysis

## Update to latest OS packages
RUN apt-get autoclean && apt-get update && apt-get -y dist-upgrade
RUN apt-get -y install wget vim curl bc less

USER pipeline
WORKDIR /home/pipeline

## Download and install miniconda
RUN wget "https://github.com/conda-forge/miniforge/releases/download/23.11.0-0/Mambaforge-$(uname)-$(uname -m).sh" && bash Mambaforge-$(uname)-$(uname -m).sh -b -u
ENV PATH="/home/pipeline/mambaforge/bin:$PATH"

## Download and install gcloud utils
RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH $PATH:/home/pipeline/google-cloud-sdk/bin


RUN mkdir cyttools
WORKDIR /home/pipeline/cyttools

#Copy in all of the files/directories/etc.. from the project into the container
COPY . .
USER root
RUN chown -R pipeline:pipeline /home/pipeline/cyttools
USER pipeline

## Install and initialize a mamba environment
#RUN conda install -y -n base -c conda-forge mamba
RUN mamba init

## Add conda channels and set priorities
RUN mamba env create -f=/home/pipeline/cyttools/cyttools_cidc.yml
RUN conda create -n nci-cli -c bioconda python=3.11

#ENTRYPOINT ["conda", "activate", "cidc_atac"]

CMD ["/bin/bash"]
