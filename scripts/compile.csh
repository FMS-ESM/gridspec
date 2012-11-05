#!/bin/csh 
set echo

set bindir   = /home/z1l/project/tools/Quebec/20090716/bin
set tooldir  = /home/z1l/project/tools/Quebec/20090716/src/tools

cd $tooldir

source /opt/modules/default/init/tcsh
module purge
module load icc.9.1.049
module load idb.9.1.045
module load scsl-1.5.1.0
module load mpt-1.18


foreach tool (fregrid make_coupler_mosaic make_hgrid make_mosaic make_topog make_vgrid)
  cd $tool
  rm -f *.o
  make
  if ( $status != 0 ) then
    unset echo
    echo "ERROR: make failed for $tool"
    exit 1
  endif
  cp $tool $bindir
  if( -e Makefile_mpi ) then
     rm -f *.o
     make -f Makefile_mpi
     if ( $status != 0 ) then
       unset echo
       echo "ERROR: make failed for parallel $tool"
       exit 1
     endif   
     cp ${tool}_parallel $bindir
  endif
  cd ..
end
