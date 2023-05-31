FROM continuumio/miniconda3:4.12.0

### UPDATING CONDA ------------------------- ###

RUN conda update -y conda

### INSTALLING PIPELINE PACKAGES ----------- ###

# Adding bioconda to the list of channels
RUN conda config --add channels bioconda

# Adding conda-forge to the list of channels
RUN conda config --add channels conda-forge

# Installing mamba
RUN conda install -y mamba

# Installing packages
# N.B. have to add weasyprint and specify tb-profiler=4.4.2 or the version automatically installed is 2.8
RUN mamba install -y \
    bbmap=39.01 \
    bcftools=1.12 \
    bowtie2=2.5.1 \
    bwa=0.7.17 \
    cutadapt=4.4 \
    entrez-direct=16.2 \
    fastqc=0.12.1 \
    gatk=3.6 \
    gatk4=4.4.0.0 \
    kraken2=2.1.2 \
    lofreq=2.1.5 \
    mummer=3.23 \
    mykrobe=0.12.1 \
    openjdk=17.0.3 \
    picard=2.20.4 \
    sambamba=0.8.1 \
    seqtk=1.3 \
    tabix=1.11 \
    tb-profiler=4.4.0 \
    trim-galore=0.6.10 \
    weasyprint=59.0 && \
    conda clean -afty

RUN conda install --force-reinstall openjdk # Needed to fix "java: symbol lookup error: java: undefined symbol: JLI_StringDup" error

### FIX KRAKEN2-BUILD ---------------------- ###

# Fixes the "rsync_from_ncbi.pl: unexpected FTP path (new server?)" error
# Thanks to Bent Petersen, PhD (https://www.bpetersen.dk/post/kraken2-rsync_from_ncbi-pl-unexpected-ftp-path-new-server-for)
#RUN mv /opt/conda/libexec/rsync_from_ncbi.pl /opt/conda/libexec/rsync_from_ncbi.pl.bak && \
#    sed '46 s/ftp/https/' /opt/conda/libexec/rsync_from_ncbi.pl.bak > /opt/conda/libexec/rsync_from_ncbi.pl && \
#    chmod 775 /opt/conda/libexec/rsync_from_ncbi.pl

### SETTING WORKING ENVIRONMENT ------------ ###

# Set workdir to /home/
WORKDIR /home/

# Launch bash automatically
CMD ["/bin/bash"]
