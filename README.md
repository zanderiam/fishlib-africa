

# Fish-Lib-Africa: A generalised, dynamic DNA reference library for metabarcoding of African freshwater fishes

Based the original meta-fish-lib pipeline developed by: Collins, R.A., Trauzzi, G., Maltby, K.M., Gibson, T.I., Ratcliffe, F.C., Hallam, J., Rainbird, S., Maclaine, J., Henderson, P.A., Sims, D.W., Mariani, S. & Genner, M.J. (2021). Meta-Fish-Lib: A generalised, dynamic DNA reference library pipeline for metabarcoding of fishes. _Journal of Fish Biology_. [https://doi.org/10.1111/jfb.14852](https://doi.org/10.1111/jfb.14852).



This repository hosts a comprehensive multi-locus mitochondrial DNA reference library dataset for freshwater fish species of Africa, derived from the [NCBI GenBank](https://www.ncbi.nlm.nih.gov/nucleotide) and [Barcode of Life BOLD](http://www.boldsystems.org/index.php) databases. The dataset includes freshwater species, and can be employed in a variety of applications. Both native and introduced African freshwater fish species are included. A species coverage report for all primer sets can be found at [assets/reports-tables.md](assets/reports-tables.md). This African reference library is curated and ready-to-use, but the code provided here can easily generate a new reference library for a different location (see [FAQ](#FAQ)).

In addition to providing quality controlled and curated fish references, this reference library has several unique features that make it useful to the wider DNA barcoding and DNA metabarcoding communities:

* Flexible - the library is not limited to any particular metabarcode locus or primer set. I have included the most popular ones (Table 1), but new ones can be added as required.
* Comprehensive - seaching by single gene names can often miss critical results due to poorly annotated records, but using hidden Markov models it is simple to extract homologous DNA fragments from large dumps of sequence data.
* Exhaustive - searching by species names can exclude potential hits because of changes in taxonomy, but here we search for all species synonyms, and then subsequently validate those names to provide a taxonomically up-to-date reference library. 
* Reliable - sequence data on GenBank are frequently misannotated with incorrect species names, but we have created a list of dubious quality accessions that are automatically excluded when the reference library is loaded each time. We use phylogenetic quality control methods to assist in screening each new GenBank version and update this list accordingly.
* Dynamic - it's easy to update to each new GenBank release (see code [below](#bash-terminal)), and the versioning of this repository reflects the GenBank release on which it was made.
* Quick - the final reference library can be downloaded onto your computer in just a few seconds with only two packages loaded and eight lines of R code ([below](#retrieve-latest-reference-library)). Generating this reference library from scratch ([below](#bash-terminal)) takes a couple of hours, with the phylogenetic quality control steps completing overnight.
* Customisable - by forking or cloning the repository, custom modifications can be made, e.g. excluding particular species, making taxonomic changes, or using a completely different list of species.
* Self contained - to recreate the reference libraries, all code and R package versions are found within in this self contained project, courtesy of [renv](https://rstudio.github.io/renv/articles/renv.html). This means less risk of clashing installations or broken code when packages and R versions upgrade.




### Create/update the reference library manually

You don't need to run this code below if you just want a copy of the UK reference library (run code above). This code below is if you want to update it yourself or want to modify and make a new library.

System requirements: [R](https://cran.r-project.org/), [git](https://git-scm.com/), [hmmer](http://hmmer.org/), [mafft](https://mafft.cbrc.jp/alignment/software/) and [raxml-ng](https://github.com/amkozlov/raxml-ng) need to be installed on your system, and available on your [$PATH](https://www.howtogeek.com/658904/how-to-add-a-directory-to-your-path-in-linux/). With the exception of raxml-ng, the programs can be installed from Ubuntu repositories using `sudo apt install` (see also [Homebrew](https://brew.sh/) `brew install` for MacOS). In case of difficulties, check the developer's website and update to newer versions if required. Unfortunately, these scripts are optimised for a Unix system, and I'm unable to offer any Windows support here ([Windows is now able to run Ubuntu Linux ](https://tutorials.ubuntu.com/tutorial/tutorial-ubuntu-on-windows#0)).

You will also require an API key from NCBI in order to access GenBank data at a decent rate. See info here for how to get a key: [ncbiinsights.ncbi.nlm.nih.gov/2017/11/02/new-api-keys-for-the-e-utilities/](https://ncbiinsights.ncbi.nlm.nih.gov/2017/11/02/new-api-keys-for-the-e-utilities/)

##### Bash terminal:

```bash
### admin - clone the repository and create temporary directories ###
git clone --depth 1 https://github.com/genner-lab/meta-fish-lib.git meta-fish-lib
cd meta-fish-lib
mkdir -p reports temp/fasta-temp

### create NCBI API key (this is ignored by git) ###
# substitute the "<YOUR-NCBI-KEY>" part for your actual key obtained from NCBI
echo 'ncbi.key <- "<YOUR-NCBI-KEY>"' > assets/ncbi-key.R
echo 'ENTREZ_KEY=<YOUR-NCBI-KEY>' > .Renviron

### install required R packages using renv (only need to run this once) ###
Rscript -e "renv::restore()"

### check the genbank versions remotely (github), locally (your machine), and on genbank itself ###
# you can update if the remote or local versions are behind genbank
scripts/check-genbank.R

### OPTION [1] replace the species table with your custom list ###
# change to file location on your machine
# this will overwrite the current table at 'assets/species-table.csv'
cp ~/path/to/my-species-table.csv assets/species-table.csv

### OPTION [2] use FishBase to generate a species list for a chosen country
# this will overwrite the current table at 'assets/species-table.csv'
# argument "-c" [826] is the ISO country code for your chosen country
#     ISO country codes can be found at https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes
# argument "-s" [true] are species synonyms
#     a value of "true" provides all accepted names and junior synonyms, a value of "false" provides only the accepted names
scripts/get-species.R -c 826 -s true

### search GenBank ###
# argument "-q" [500] is the max search batch query length (in characters)
#     the maximum search query length technically allowed by NCBI is 2500
#     bigger queries will be faster, but can be more prone to server errors
#     conversely, many small queries can also result in server errors by increasing the individual chances that one will fail
# argument "-t" [4] is the number of processing threads to run in parallel
#     more threads are faster, but more prone to errors by overloading the server with requests
#     most laptops and desktops are hyperthreaded with two virtual CPUs (threads) for each physical CPU (cores)
#     run "lscpu | grep -E '^Thread|^Core|^Socket|^CPU\('" to obtain info on available cores/threads
#     make sure not to request more threads than are present on your system
# argument "-e" [false] is to run an exhaustive ("true") or simple search ("false")
#     the simple search just uses the terms "mitochondrion,mitochondrial"  
#     the exhaustive search in addition uses "COI,CO1,cox1,cytb,cytochrome,subunit,COB,CYB,12S,16S,rRNA,ribosomal"
#     the simple search will pick up 99% of mtDNA sequences, but may miss older sequences that were not well annotated
#     the simple search is faster, less prone to error, and may help if you need to search for a lot of species 
scripts/sequences-download.R -q 500 -t 4 -e false

### assemble the reference library with hidden Markov models and obtain metadata ###
# argument "-t" [4] is the number of processing threads to run in parallel
#     do not request more threads than metabarcode markers
#     do not request more threads than are present on your system
# argument "-m" [all] is the metabarcode marker, here choosing "all" eight available metabarcodes
#     if you don't require all metabarcodes, it's strongly recommended to specify only the one(s) you want
#     to choose a specific metabarcode marker(s), use the codes in Table 1 and separate with a comma and no space
#     e.g. "-m 12s.miya,coi.ward"
# note this script overwrites the local master reference library 'assets/reference-library-master.csv.gz'
scripts/references-assemble.R -t 4 -m all

### phylogenetic quality control (QC) ###
# argument "-t" [4] is the number of processing threads to run in parallel
#    note that the threads argument doesn't influence the performance operation of raxml-ng or mafft
#    these applications automatically determine the optimum number of threads for your system
#    the argument only applies to preparing/plotting
#    do not request more threads than metabarcode markers
#    do not request more threads than are present on your system
# argument "-v" [false] is verbosity (information printed to screen) from the alignment and phylogenetic steps
#    a value of "true" prints program info, a value of "false" prevents printing of info
#    seeing the output on screen is useful if you run into problems and need to debug, otherwise it's not required
scripts/qc.R -t 4 -v false

# now manually review the phylogenetic tree PDFs output into 'reports/qc_GBVERSION_MONTH-YEAR' 
# if found, add suspect accessions manually to 'assets/exclusions.csv'

### compile species coverage reports ###
make -f scripts/Makefile

### update GitHub repository (updates remote version - only works if you have forked the repository rather than cloned) ###
# change x to actual version
cp reports/reports-tables.md assets/reports-tables.md
git add assets/reference-library-master.csv.gz assets/exclusions.csv assets/reports-tables.md
git commit -m "updated master to genbank version x"
git push
git tag -a vX -m "GenBank vX"
git push --tags
# now make a release using this tag on GitHub
# if Zenodo has been set up correctly, a DOI should become available immediately

### confirm changes are made ###
scripts/check-genbank.R

### if all worked, you can clean up to save disk space ###
# be sure that you want to do this!
rm -r temp

### your master reference library is now located at 'assets/reference-library-master.csv.gz' ###
# IMPORTANT: this reference library contains the unfiltered records, and needs to be cleaned before use

### clean, dereplicate, length filter, and write out the reference library for use ###
# argument "-m" [12s.miya] is the metabarcode marker
#    choose one of the eight available metabarcodes in Table 1.
# argument "-d" [true] is the taxonomic dereplication flag
#    a value of "true" removes all duplicate sequences within each species, but sequences can be identical between species
#    subsequences, i.e. shorter sequences that differ only by nucleotides missing at ends, are considered duplicate haplotypes
#    a value of "false" keeps all sequences
# argument "-p" [0.5] is the sequence-length filtering flag
#    for example, a value of 0.5 removes all sequences shorter than 50% of the median sequence length 
#    can be any value between 0 and 1
#    a value of 0 retains all sequences
scripts/clean-derep-write.R -m 12s.miya -d true -p 0.5
```

note: depending on the size of your species list, the qc can be semi-automated using the SATIVA pipeline (https://github.com/amkozlov/sativa/tree/master). For taxonomic reconciliation, the  reconcile-species script can be run. There are two options for this: first you can run it with the species table but depending on how many species that contains it can take a relatively long time. Second, you can create a csv of unmatched species after the references-assemble step which will speed up this step, although this requires re-running the pipeline again afterwards.





* **How do I actually use the reference library?** - The reference library generated is provided in a tabular CSV format. This is because this type of data can be easily manipulated in R using popular packages such as [dplyr](https://dplyr.tidyverse.org/reference/dplyr-package.html). Most taxonomy assignment software, however, requires DNA sequence data in a format such as FASTA, and therefore the table requires converting before being used. I have provided a script `scripts/clean-derep-write.R` that loads up the local copy of the reference library and cleans, dereplicates, and length-filters it, before writing out as as FASTA. In the FASTA file the headers (lines commencing ">") contain the taxonomic assignment information, but unfortunately each of the many software implementations available tend to use its own syntax for these headers, and as such I am unable to know which ones you will be using. However, I have chosen some commonly used formats (e.g. sintax, dada2, plain dbid) for the default FASTA outputs. Please raise a ticket in [Issues](https://github.com/genner-lab/meta-fish-lib/issues) if you think an important one needs to be added. To make your own custom labels yourself, just use the dplyr `mutate()` and `paste()` functions to join columns in the table to make a new label column. Below I make a label of format 'dbid_family_genus_species' and write it out as a FASTA file. Table 2 explains the fields in the reference library table.


**Table 2: Key to reference library table fields**

Field (column name) | Description
----- | -----
source | source of record (GenBank or BOLD)
dbid | GenBank or BOLD database ID (GI, processid)
gbAccession | GenBank accession
sciNameValid | FishBase validated scientific name 
subphylum | taxonomic subphylum
class | FishBase taxonomic class
order | FishBase taxonomic order
family | FishBase taxonomic family
genus | FishBase taxonomic genus
sciNameOrig | original scientific name from GenBank/BOLD
fbSpecCode | FishBase species code
country | sample voucher collection country
catalogNumber | sample voucher catalogue number
institutionCode | sample voucher institution code
decimalLatitude | sample voucher collection latitude (decimal degrees)
decimalLongitude | sample voucher collection longitude (decimal degrees)
publishedAs | publication title
publishedIn | publication journal
publishedBy | publication lead author
date | date of sequence publication
notesGenBank | title of GenBank record
genbankVersion | version of GenBank used to generate this reference library
searchDate | date of reference library search
length | number of nucleotides in full record
nucleotides | nucleotides for full record
nucleotidesFrag.GENE.FRAGMENT.noprimers | nucleotides for gene fragment primer subset
lengthFrag.GENE.FRAGMENT.noprimers | number nucleotides in gene fragment primer subset


### Contents (A-Z)

* **`assets/`** - Required file and reference library.
    - **`hmms/`** - Hidden Markov models (HMMs) of gene markers of interest.
    - `collins2021_submitted_jfb.pdf` - preprint copy of paper describing software
    - `exclusions.csv` - unreliable accessions to be excluded 
    - `logo.svg` - project logo
    - `reference-library-master.csv.gz` - master copy of the reference library
    - `reports-tables.md` - species coverage reports
    - `species-list-synonyms.md` - tutorial and R code to generate species lists and synonyms
    - `species-table.csv` - list of species to search for
    - `species-table-testing.csv` - a test list of goby species
    - `taxonomy-changes.csv` - custom table to change species names
* **`renv/`** - Settings for the R environment.
* **`reports/`** - Location of QC reports. Temporary directory that is not committed to the repository, but needs to be created locally to run the scripts. Ignored by git.
* **`scripts/`** - R and shell scripts.
    - `check-genbank.R` - script to get genbank versions
    - `clean-derep-write.R` - script to clean sequences, dereplicate, length filter, and write out
    - `load-libs.R` - script to load all required packages and functions
    - `Makefile` - makefile to generate the species coverage reports
    - `qc.R` - quality control a reference library
    - `references-assemble.R` - extract and annotate reference libraries from ncbi/bold dumps 
    - `references-clean.R` - quality filter reference library
    - `references-load-local.R` - load reference library locally
    - `references-load-remote.R` - load reference library remotely
    - `reports-tables.Rmd` - knitr file to prepare species coverage reports
    - `sequences-download.R` - pulls all mitochondrial DNA from NCBI and BOLD for a list of species
* **`temp/`** - Temporary file directory that is not committed to the repository, but needs to be created locally to run the scripts. Ignored by git.
* `LICENSE` - Legal stuff
* `README.md` - This file
* `renv.lock` - R packages required and managed by renv
* `.gitignore` - files and directories ignored by git
* `.Renviron` - contains NCBI key (ignored by git)
* `.Rprofile` - activates renv
* `.R-version` - required version of R (used by renv-installer)
