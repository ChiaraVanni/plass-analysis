#!/bin/bash -ex
BASE_DIR="$HOME/clone/regression_test"
PLASS="$HOME/clone/build/src/"
export PATH=$PLASS:$PATH
notExists() {
	[ ! -f "$1" ]
}


cd ${BASE_DIR}
# build the benchmark tools
if notExists "plass-analysis"; then
  git clone https://github.com/martin-steinegger/plass-analysis.git
  cd plass-analysis
  git submodule init
  git submodule update
  cd ..
fi  
# setup mmseqs2
if notExists "mmseqs2"; then
  git clone https://github.com/soedinglab/mmseqs2.git
  cd mmseqs2
  mkdir build && cd build
  cmake -DCMAKE_BUILD_TYPE=Release  ..
  make -j 4 VERBOSE=0
  cd ..
  cd ..
fi
MMSEQSPATH="$(realpath mmseqs2)/build/src"
export PATH=$MMSEQSPATH:$PATH

#setup benchmark database
mkdir results

PLASSANALPATH="$(realpath plass-analysis)/Prochloroccus/"
export PATH=$PLASSANALPATH:$PATH

# go run it
plass assemble ./plass-analysis/data/allgenomes_reads_sample_1.fastq ./plass-analysis/data/allgenomes_reads_sample_2.fastq results/final.contigs.aa.fa results/tmp
mmseqs createdb results/final.contigs.aa.fa results/final.contigs.aa
chmod -R u+x ./plass-analysis/
export PATH="$(realpath plass-analysis)":$PATH

# eval it
mmseqs createdb ./plass-analysis/data/prochloroccus_allproteins.fasta ./plass-analysis/data/prochloroccus_allproteins
mmseqs createdb ./plass-analysis/data/prochloroccus_allproteins_nr.fasta ./plass-analysis/data/prochloroccus_allproteins_nr
evaluateResults.sh results/final.contigs.aa ./plass-analysis/data/prochloroccus_allproteins ./plass-analysis/data/prochloroccus_allproteins_nr results/ 100 

cat results/sense > report-${CI_COMMIT_ID}
cat results/precision >> report-${CI_COMMIT_ID}
cat report-${CI_COMMIT_ID}
# fill out the report and fail
check_result.sh report-${CI_COMMIT_ID} "0.497 0.475 0.453 0.424 0.390 0.346 0.298 0.247 0.198 0.134 0.980 0.980 0.980 0.979 0.978 0.975 0.967 0.942 0.873 0.653"
exit $?

