#!/bin/csh -f
set echo

set tooldir = /home/z1l/bin/tools_20090401
set datadir = /archive/z1l/tools/test_20090401
set outdir  = $datadir/output_all
set indir   = $datadir/input
set river_regrid_outdir = $datadir/river_regrid
set transfer_outdir     = $datadir/transfer_to_mosaic_grid
mod
if( ! -e $outdir ) mkdir -p $outdir

#river_regrid
cd $river_regrid_outdir
$tooldir/river_regrid --mosaic $indir/M45/mosaic.nc --river_src $indir/z1l_river_output_M45_tripolar_aug24.nc --output river_data_M45
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for river_regri to regrid river data onto M45 mosaic grid."
    exit 1
endif

$tooldir/river_regrid --mosaic $indir/C48/mosaic.nc --river_src $indir/z1l_river_output_M45_tripolar_aug24.nc --output river_data_C48
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for river_regri to regrid river data onto C48 mosaic grid."
    exit 1
endif

#transfer_to_mosaic_grid
cd $transfer_outdir
$tooldir/transfer_to_mosaic_grid --input_file $indir/M45.tripolar.grid_spec.nc

if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for transfer_to_mosaic_grid."
    exit 1
endif


cd $outdir

#make_vgrid will make a grid file with 60 supergrid cells.

$tooldir/make_vgrid --nbnds 3 --bnds 10,200,1000 --nz 10,20
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_vgrid"
    exit 1
endif
#make_hgrid and make_solo_mosaic C48
$tooldir/make_hgrid --grid_type gnomonic_ed --nlon 96
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_hgrid C48"
    exit 1
endif
$tooldir/make_solo_mosaic --num_tiles 6 --dir $PWD --mosaic C48_mosaic
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_solo_mosaic C48"
    exit 1
endif

#make_hgrid and make_solo_mosaic N45
$tooldir/make_hgrid --grid_type regular_lonlat_grid --nxbnd 2 --nybnd 2 --xbnd 0,360 --ybnd -90,90 --nlon 288 --nlat 180 --grid_name N45_grid
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_hgrid N45"
    exit 1
endif
$tooldir/make_solo_mosaic --num_tiles 1 --dir $PWD --mosaic N45_mosaic --tile_file N45_grid.nc --periodx 360
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_solo_mosaic N45"
    exit 1
endif

#make_hgrid and make_solo_mosaic 2-degree tripolar
$tooldir/make_hgrid --grid_type tripolar_grid --nxbnd 2 --nybnd 2 --xbnd -280,80 --ybnd -90,90 --nlon 360 --nlat 180 --grid_name tripolar_grid 
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_hgrid tripolar"
    exit 1
endif
$tooldir/make_solo_mosaic --num_tiles 1 --dir $PWD --mosaic tripolar_mosaic --tile_file tripolar_grid --periodx 360
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_solo_mosaic tripolar"
    exit 1
endif

#make_topog of tripolar grid
$tooldir/make_topog --mosaic  $outdir/tripolar_mosaic.nc --topog_file $indir/OCCAM_p5degree.nc --topog_field TOPO --scale_factor -1 --output tripolar_topog.nc
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_topog"
    exit 1
endif

#make_coupler_mosaic
$tooldir/make_coupler_mosaic --atmos_mosaic  $outdir/C48_mosaic.nc --land_mosaic  $outdir/N45_mosaic.nc --ocean_mosaic  $outdir/tripolar_mosaic.nc --ocean_topog  $outdir/tripolar_topog.nc 

if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_coupler_mosaic"
    exit 1
endif

mkdir pe_10
cd pe_10
mpirun -np 10 $tooldir/make_topog_parallel --mosaic $outdir/tripolar_mosaic.nc --topog_file $indir/OCCAM_p5degree.nc --topog_field TOPO --scale_factor -1 --output tripolar_topog.nc
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_topog_parallel"
    exit 1
endif

mpirun -np 10 $tooldir/make_coupler_mosaic_parallel --atmos_mosaic $outdir/C48_mosaic.nc --land_mosaic $outdir/N45_mosaic.nc --ocean_mosaic $outdir/tripolar_mosaic.nc --ocean_topog $outdir/tripolar_topog.nc 

if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_coupler_mosaic_parallel"
    exit 1
endif

#compare data
foreach ncfile (`ls *.nc`)
  nccmp -md $ncfile ../$ncfile
end
