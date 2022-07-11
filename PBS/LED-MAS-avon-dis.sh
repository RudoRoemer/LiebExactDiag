#!/bin/bash

# settings from input

disorder=${1:-10.0}
size=${2:-10}
seed=${3:-1}
config=${4:-2}
keep=${5:-1}

echo "LED: making for M=" $size "with starting seed=" $seed "and" $config "samples"

# settings for files

binary=LEDdiag.IC

# settings for directories

currdir=`pwd`
jobdir=$currdir

binarydir=$HOME/Projects/LiebExactDiag/EXE
#binarydir=/storage/disqs/LiebSparseDiag/EXE

#for disorder in 1.0 2.0 5.0 10.0 20.0 50.0 60.0 70.0 80.0
#do

echo "--- hDis=" $disorder

jobname="LED-$size-hD$disorder"
echo $jobname

jobfile=`printf "$jobname.sh"`
logfile=`printf "$jobname.log"`
jobdir="LED-$size"
mkdir -p $jobdir

echo "binarydir=" $binarydir " jobdir=" $jobdir 

# settings for parallel submission

cd $jobdir

cat > ${jobfile} << EOD
#!/bin/bash
#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=48
#SBATCH --time=48:00:00
#SBATCH --mem-per-cpu=31418
#SBATCH --partition=hmem

module purge
module load GCC/10.2.0 parallel 
module load intel

for iseed in {1..$config..1}
do

myseed=\$(( $seed + \$iseed - 1))
echo "--- working on config" \$iseed "with seed" \$myseed

# create the input file
echo create the input file
inpfile=LEDdiag-$disorder-\$iseed.inp
touch \$inpfile

echo "ISeed         = \$myseed       ">  \$inpfile #
echo "NConfig       = 1        ">>  \$inpfile #
echo "Dim           = 3            ">>  \$inpfile #
echo "Nx            = 1            ">>  \$inpfile #
echo "IBCFlag       = 1             ">>  \$inpfile #
echo "IRNGFlag      = 0             ">>  \$inpfile #
echo "IKeepFlag     = $keep      ">>  \$inpfile #
echo "IWriteFlag    = 2       ">>  \$inpfile #
echo "IStateFlag    = 2       ">>  \$inpfile #
echo "Width0        = $size       ">>  \$inpfile #
echo "Width1        = $size       ">>  \$inpfile #
echo "dWidth        = 2          ">>  \$inpfile #
echo "HubDis0       = $disorder      ">>  \$inpfile #
echo "HubDis1       = $disorder           ">>  \$inpfile #
echo "dHubDis       = 1.0           ">>  \$inpfile #
#echo "RimDis0       = $disorder      ">>  \$inpfile #
echo "RimDis0       = 0.0            ">>  \$inpfile #

cat \$inpfile

#$binarydir/$binary <\$inpfile

done

MY_PARALLEL_OPTS="-N 1 --delay .2 -j \$SLURM_NTASKS --joblog parallel-\${SLURM_JOBID}.log"
MY_SRUN_OPTS="-N 1 -n 1 --exclusive"
MY_EXEC="$binarydir/$binary <LEDdiag-$disorder-{}.inp"

parallel \$MY_PARALLEL_OPTS srun \$MY_SRUN_OPTS \$MY_EXEC ::: {1..$config}

pwd
zip -mv LED-$size.zip L31_*/Evec*.raw
zip -m inp.zip *.inp
zip -m sh.zip *.sh

exit 0

EOD

chmod 755 ${jobfile}
#(msub -q devel $jobdir/${jobfile}) # for queueing system
#(sbatch -q devel $jobdir/${jobfile}) # for queueing system
sbatch ${jobfile} # for queueing system
#(source $jobdir/${jobfile} ) >& $jobdir/${logfile} & # for parallel shell execution
#source ${jobfile} #>& ${logfile} # for sequential shell execution

sleep 1

cd ..

#done

