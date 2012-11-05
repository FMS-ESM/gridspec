#!/bin/csh -f
set echo

set tooldir = /home/z1l/project/tools/Quebec/20090716/bin
set datadir = /home/z1l/project/tools/Quebec/20090716
set outdir  = $datadir/output
set indir   = $datadir/input
if( ! -e $outdir ) mkdir -p $outdir

cd $outdir

#-------------------------------------------------------------------------
#make_vgrid will make a grid file with 30 grid cells.
#-------------------------------------------------------------------------
$tooldir/make_vgrid --nbnds 3 --bnds 10,200,1000 --nz 10,20
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_vgrid"
    exit 1
endif

#-------------------------------------------------------------------------
# make a torus mosaic
#-------------------------------------------------------------------------
$tooldir/make_hgrid --grid_type regular_lonlat_grid --nxbnd 2 --nybnd 2 --xbnd 0,360 --ybnd -90,90 --nlon 160 --nlat 180 --grid_name torus_grid
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_hgrid to generate torus grid"
    exit 1
endif
$tooldir/make_mosaic --num_tiles 1 --tile_file torus_grid.nc --periodx 360 --periody 180 --mosaic_name torus_mosaic
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_mosaic to generate torus mosaic"
    exit 1
endif
#-------------------------------------------------------------------------
# make a simple mosaic with four tiles.
#-------------------------------------------------------------------------

$tooldir/make_hgrid --grid_type regular_lonlat_grid --nxbnd 2 --nybnd 2 --xbnd 0,360 --ybnd -90,90 --nlon 160 --nlat 180 --grid_name four_tile_grid --ndivx 2 --ndivy 2
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_hgrid to generate four tile grid"
    exit 1
endif
$tooldir/make_mosaic --num_tiles 4 --tile_file four_tile_grid --periodx 360 --mosaic_name four_tile_mosaic
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_mosaic to generate four tile mosaic"
    exit 1
endif

#-------------------------------------------------------------------------
# make a coupler mosaic with C48 atmosphere grid, N45 land grid and
# 2 degree tripolar grid for ice and ocean model.
#-------------------------------------------------------------------------

#make_hgrid and make_solo_mosaic C48 atmos grid.
$tooldir/make_hgrid --grid_type gnomonic_ed --nlon 96 --grid_name C48_grid
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_hgrid to generate C48 grid"
    exit 1
endif
$tooldir/make_mosaic --num_tiles 6 --tile_file C48_grid --mosaic_name C48_mosaic 
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_mosaic to generate C48 mosaic"
    exit 1
endif

#make_hgrid and make_solo_mosaic N45 land grid.
$tooldir/make_hgrid --grid_type regular_lonlat_grid --nxbnd 2 --nybnd 2 --xbnd 0,360 --ybnd -90,90 --nlon 288 --nlat 180 --grid_name N45_grid
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_hgrid to generate N45 grid"
    exit 1
endif
$tooldir/make_mosaic --num_tiles 1 --mosaic_name N45_mosaic --tile_file N45_grid.nc --periodx 360
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_mosaic to generate N45 mosaic"
    exit 1
endif

#make_hgrid and make_solo_mosaic 2-degree tripolar
$tooldir/make_hgrid --grid_type tripolar_grid --nxbnd 2 --nybnd 2 --xbnd -280,80 --ybnd -90,90 --nlon 360 --nlat 180 --grid_name tripolar_grid 
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_hgrid to generate tripolar grid"
    exit 1
endif
$tooldir/make_mosaic --num_tiles 1 --mosaic_name tripolar_mosaic --tile_file tripolar_grid --periodx 360
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_mosaic to generate tripolar mosaic"
    exit 1
endif

#make_topog of tripolar grid
$tooldir/make_topog --mosaic  tripolar_mosaic.nc --topog_file $indir/OCCAM_p5degree.nc --topog_field TOPO --scale_factor -1 --topog_mosaic tripolar_topog_mosaic
if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_topog"
    exit 1
endif

#make_coupler_mosaic
$tooldir/make_coupler_mosaic --atmos_mosaic  $outdir/C48_mosaic.nc --land_mosaic  $outdir/N45_mosaic.nc --ice_mosaic  $outdir/tripolar_mosaic.nc --ice_topog_mosaic  $outdir/tripolar_topog_mosaic.nc 

if( $status != 0 ) then
    unset echo
    echo "ERROR: run failed for make_coupler_mosaic"
    exit 1
endif

#------------------------------------------------------------------------------------------
# use fregrid to remap data from C48 onto N45 using first-order conservative interpolation.
#------------------------------------------------------------------------------------------
$tooldir/fregrid --input_mosaic C48_mosaic.nc --input_dir $indir --input_file 19800101.atmos_daily --scalar_field zsurf,temp,t_surf --output_mosaic N45_mosaic.nc --interp_method conserve_order2 --output_file 19800101.atmos_daily.N45.order1 --remap_file C48_to_N45_remap.order1.nc
