Proteomic Pipeline Generator
============================

Proteomic Pipeline generator is a comandline script that generates multiple pipelines for use with proteomics data.

## Programs
The PPG currently uses two types of software: database search software, and statistical validation software. It also offers statistical enrichment analysis with g:profiler

### Database search
  * [Comet](http://comet-ms.sourceforge.net/)
  * [X!tandem](https://www.thegpm.org/tandem/)
  * [MS-GF+](https://omics.pnl.gov/software/ms-gf)
  
### Statistical validation
  * [PeptideProphet](https://sourceforge.net/projects/sashimi/files/Trans-Proteomic%20Pipeline%20%28TPP%29/) (not avalible outside of the TPP)
  * [Percolator](https://github.com/percolator/percolator/wiki)

### Analysis
 * [g:profiler](https://biit.cs.ut.ee/gprofiler/page/docs)

## Instalation
Add the location of the programs that you have installed to second collumn of the install_locations file

## Options
The PPG is issued with multiple variables some are optional.
**options requiered to generate the pipelines**
`-P [database search programs]`
`-V [Statistical validation programs]`
**options requiered to automaticaly run the pipelines**
`-p [parameterfiles (in the same order as the programs)]` 
`-i [input file]`
`-g [g:profiler parameter file]`

This is a README file which we can use to document and discuss the project.
