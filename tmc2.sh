#!/bin/bash

## This script will run encoder only if the reconstructed point cloud does not exist. 
## Usage ./tmc2.sh [StartFrameNumber] [Rate] 
## 
## Before running, you might want to check whether SEQ and FRAMECOUNT has been set correctly.s

# Path to main directory
MAINDIR=$HOME/fyp/mpeg-pcc-tmc2
# Path to external dependencies, e.g. HDRTools, HM, JM
EXTERNAL=$MAINDIR/external/;
# Path to folder that will contain the reconstructed point cloud
RECONSTRUCT=$HOME/fyp/mpeg_datasets/ori-640;

mkdir -p $RECONSTRUCT
# pass in the start frame number, which is different for each dataset
STARTFRAMENUM="$1"

#echo $MAINDIR
#echo $EXTERNAL
echo $STARTFRAMENUM

## Input parameters
# Path to your dataset
SRCDIR=$HOME/fyp/mpeg_datasets/
CFGDIR=${MAINDIR}/cfg/
# Sequence (referring to dataset)
SEQ=26;       # in [22;26]
# Condition (C2AI: lossy all intra, C2RA: lossy random access, CWAI: lossless all intra, CWLD: lossless low delay?)
COND='C2AI';       # in [C2AI, C2RA, CWAI, CWLD]
# Compression quality
RATE="$2";       # in [1;5]
# Total frames to be encoded/decoded.
FRAMECOUNT=1;
THREAD=8;
GOF_SIZE=32; # default: 32

## Set external tool paths
ENCODER=${MAINDIR}/bin/PccAppEncoder;
DECODER=${MAINDIR}/bin/PccAppDecoder;
METRIC=${MAINDIR}/bin/PccAppMetrics;
HDRCONVERT=${EXTERNAL}HDRTools/build/bin/HDRConvert;
HMENCODER=${EXTERNAL}HM/bin/TAppEncoderStatic;
HMDECODER=${EXTERNAL}HM/bin/TAppDecoderStatic;

# 0: JMAPP (p4), 1: HMAPP (p3), 2: SHMAPP (p5), 3: JMLIB (p1), 4: HMLIB (p0: default), 5: VTMLIB (p2)
# see PCCVirtualVideoEncoder.cpp
# CODEC=0;

# 0: AVC (h.264: JMAPP/JMLIB), 1: HEVCMAIN10 (default), 2: HEVCMAIN444, 3: CODEC_GROUP_VVC_MAIN10
# see PCCBitstreamCommon.h
CODEC_GROUP=1;


## Set Configuration based on sequence, condition and rate
if [ $COND == "C2AI" -o $COND == "C2RA" ]
then
  case $SEQ in
      22) CFGSEQUENCE="sequence/queen.cfg";;
      23) CFGSEQUENCE="sequence/loot_vox10.cfg";;
      24) CFGSEQUENCE="sequence/redandblack_vox10.cfg";;
      25) CFGSEQUENCE="sequence/soldier_vox10.cfg";;
      26) CFGSEQUENCE="sequence/longdress_vox10.cfg";;
      27) CFGSEQUENCE="sequence/basketball_player_vox11.cfg";;
      28) CFGSEQUENCE="sequence/dancer_vox11.cfg";;
      29) CFGSEQUENCE="sequence/thaidancer_viewdep_vox12.cfg";;
      *) echo "sequence not correct ($SEQ)";   exit -1;;
  esac
  case $RATE in
      6) CFGRATE="rate/ctc-r5-lossless.cfg";;
      5) CFGRATE="rate/ctc-r5.cfg";;
      4) CFGRATE="rate/ctc-r4.cfg";;
      3) CFGRATE="rate/ctc-r3.cfg";;
      2) CFGRATE="rate/ctc-r2.cfg";;
      1) CFGRATE="rate/ctc-r1.cfg";;
      0) CFGRATE="rate/ctc-r0.cfg";;
      -1) CFGRATE="rate/ctc-r-1.cfg";;
      *) echo "rate not correct ($RATE)";   exit -1;;
  esac
  #BIN=$RECONSTRUCT/S${SEQ}${COND}R0${RATE}_F${FRAMECOUNT}.bin
  BIN=$RECONSTRUCT/S${SEQ}${COND}R0${RATE}_F${FRAMECOUNT}_${STARTFRAMENUM}.bin
else
   case $SEQ in
      22) CFGSEQUENCE="sequence/queen-lossless.cfg";;
      23) CFGSEQUENCE="sequence/loot_vox10-lossless.cfg";;
      24) CFGSEQUENCE="sequence/redandblack_vox10-lossless.cfg";;
      25) CFGSEQUENCE="sequence/soldier_vox10-lossless.cfg";;
      26) CFGSEQUENCE="sequence/longdress_vox10-lossless.cfg";;
      27) CFGSEQUENCE="sequence/basketball_player_vox11-lossless.cfg";;
      28) CFGSEQUENCE="sequence/dancer_vox11-lossless.cfg";;
      *) echo "sequence not correct ($SEQ)";   exit -1;;
  esac
  CFGRATE="rate/ctc-r5.cfg"
  BIN=$RECONSTRUCT/S${SEQ}${COND}_F${FRAMECOUNT}.bin
fi

case $COND in
  CWAI) CFGCOMMON="common/ctc-common-lossless-geometry-attribute.cfg";;
  CWLD) CFGCOMMON="common/ctc-common-lossless-geometry-attribute.cfg";;
  C2AI) CFGCOMMON="common/ctc-common.cfg";;
  C2RA) CFGCOMMON="common/ctc-common.cfg";;
  *) echo "Condition not correct ($COND)";   exit -1;;
esac

case $COND in
  CWAI) CFGCONDITION="condition/ctc-all-intra-lossless-geometry-attribute.cfg";;
  CWLD) CFGCONDITION="condition/ctc-low-delay-lossless-geometry-attribute.cfg";;
  C2AI) CFGCONDITION="condition/ctc-all-intra.cfg";;
  C2RA) CFGCONDITION="condition/ctc-random-access.cfg";;
  *) echo "Condition not correct ($COND)";   exit -1;;
esac

## Encoder
echo $BIN
if [ ! -f $BIN ]
then
  echo "starting encoder ..."
  echo $CFGDIR $CFGCOMMON $CFGSEQUENCE $CFGRATE $SRCDIR $HDRCONVERT $THREAD
  echo $GOF_SIZE $HMENCODER $BIN $CODEC_GROUP $STARTFRAMENUM
  $ENCODER \
    --config=${CFGDIR}${CFGCOMMON} \
    --config=${CFGDIR}${CFGSEQUENCE} \
    --config=${CFGDIR}${CFGCONDITION} \
    --config=${CFGDIR}${CFGRATE} \
    --configurationFolder=${CFGDIR} \
    --uncompressedDataFolder=${SRCDIR} \
    --colorSpaceConversionPath=$HDRCONVERT \
    --nbThread=$THREAD \
    --frameCount=$FRAMECOUNT \
    --groupOfFramesSize=$GOF_SIZE \
    --keepIntermediateFiles=1 \
    --compressedStreamPath=${BIN} \
    --videoEncoderOccupancyPath=$HMENCODER \
    --videoEncoderGeometryPath=$HMENCODER \
    --videoEncoderAttributePath=$HMENCODER \
    --startFrameNumber=$STARTFRAMENUM \
    --minimumImageWidth=1280 \
    --minimumImageHeight=1280 \
    --occupancyPrecision=1 \
    --profileCodecGroupIdc=$CODEC_GROUP
    # if reconstructedDataPath is not provided, the ply files will not be
      # written
    #--reconstructedDataPath=${BIN%.???}_rec_%04d.ply \
else
## Decoder
## 
## If you don't pass in the reconstructed data path, it will not writeout the final ply file. 
## This might be useful since writing out 10MB worth of data can be slow.
  echo "Starting decoder ..."
$DECODER \
  --compressedStreamPath=$BIN \
  --colorSpaceConversionPath=${HDRCONVERT} \
  --inverseColorSpaceConversionConfig=${CFGDIR}hdrconvert/yuv420torgb444.cfg \
  --nbThread=$THREAD \
  --videoDecoderOccupancyPath=$HMDECODER \
  --videoDecoderGeometryPath=$HMDECODER \
  --videoDecoderAttributePath=$HMDECODER
  # --keepIntermediateFiles=1 \
  # --reconstructedDataPath=${BIN%.???}_dec_%04d.ply \
fi


# ## Compute Metrics
# $METRIC \
#   --uncompressedDataPath=${SRCDIR}8iVFBv2/soldier/Ply/soldier_vox10_%04d.ply \
#   --startFrameNumber=536 \
#   --nbThread=$THREAD \
#   --reconstructedDataPath=${BIN%.???}_dec_%04d.ply \
#   --frameCount=2

