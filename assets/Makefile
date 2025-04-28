
# Makefile for generating species reference library scripts from GenBank searches and tissues collected
# Alexander Hill, Aug 2021


# format
# output : dependencies
# commands (preceded by a tab)

# to execute, simply run "make" in the terminal from the scripts dir

reports/coverage_report.md : assets/coverage-report-test.Rmd assets/fasta/references.12s.evans-Ac.cleaned.v265.csv
	Rscript -e "require('rmarkdown'); rmarkdown::render(input='assets/coverage-report-test.Rmd', output_dir='reports/')"
