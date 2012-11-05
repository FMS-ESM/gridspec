#!/bin/csh
set echo

set bindir   = ${PWD}/../bin
set tooldir  = ${PWD}/../src/tools
set currdir = ${PWD}
cd $tooldir

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
#  if( -e Makefile_mpi ) then
#     rm -f *.o
#     make -f Makefile_mpi
#     if ( $status != 0 ) then
#       unset echo
#       echo "ERROR: make failed for parallel $tool"
#       exit 1
#     endif   
#     cp ${tool}_parallel $bindir
#  endif
  cd ..
end

cd $currdir