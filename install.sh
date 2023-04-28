#!/usr/bin/env bash

rel_SCRIPTPATH=$( dirname -- ${BASH_SOURCE[0]}; );
source $rel_SCRIPTPATH/utils/utils.sh

ROOT=$(abspath $rel_SCRIPTPATH);

if ! echo $PATH | tr ":" "\n" | grep "OME_Zarr_Tools" &> /dev/null;
then
	echo PATH="$ROOT:$PATH" >> $HOME/.bashrc;
  source ~/.bashrc
fi;

chmod -R 777 $ROOT;

source ~/.bashrc
mkdir -p ~/Applications;
cd ~/Applications;

# Make sure FIJI is installed and the MoBIE plugin exists 
if ! ls | grep Fiji.app &> /dev/null;
then
	wget https://downloads.imagej.net/fiji/latest/fiji-linux64.zip;
	unzip fiji-linux64.zip;
	rm fiji-linux64.zip;
	Fiji.app/ImageJ-linux64 --headless --update add-update-site MoBIE https://sites.imagej.net/MoBIE/;
	Fiji.app/ImageJ-linux64 --headless --update update;
	chmod -R a+rwx Fiji.app;
	echo 'alias fiji=$HOME/Applications/Fiji.app/ImageJ-linux64' >> ~/.bashrc;
fi;

# if miniconda3 is not in the path, add it there:
if ! echo $PATH | tr ":" "\n" | grep "conda" &> /dev/null;
then
	echo PATH="$HOME/miniconda3/bin:$PATH" >> $HOME/.bashrc;
fi;

# check if conda Miniconda3 already exists, otherwise download it
if ! ls | grep Miniconda3 &> /dev/null;
then
	wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh;
else
	echo "Miniconda3 is already downloaded."
fi;

# grant permission for miniconda envs file and install miniconda
if ! command -v conda &> /dev/null; 
then
	chmod +x Miniconda3-latest-Linux-x86_64.sh;
	./Miniconda3-latest-Linux-x86_64.sh -b -u;
else
	echo "Miniconda3 is already installed."
fi;

cd ~

# Now create the environments from the yml files

source ~/.bashrc
if ! ls ~/miniconda3/envs | grep minio &> /dev/null;
then 	
	conda env create -f $ROOT/minio_env.yml;
	echo 'alias mc=$HOME/OME_Zarr_Tools/apps/mc.sh' >> ~/.bashrc;
fi;

source ~/.bashrc
if ! ls ~/miniconda3/envs | grep bf2raw &> /dev/null;
then 	
	conda env create -f $ROOT/bf2raw_env.yml;
	echo 'alias bioformats2raw=$HOME/OME_Zarr_Tools/apps/bioformats2raw.sh' >> ~/.bashrc;
	echo 'alias tree=$HOME/OME_Zarr_Tools/apps/tree.sh' >> ~/.bashrc
fi;

source ~/.bashrc
if ! ls ~/miniconda3/envs | grep ZarrSeg &> /dev/null;
then 	
	conda env create -f $ROOT/ZarrSeg.yml;
	echo 'alias napari=$HOME/OME_Zarr_Tools/apps/napari.sh' >> ~/.bashrc;
	echo 'alias ome_zarr=$HOME/OME_Zarr_Tools/apps/ome_zarr.sh' >> ~/.bashrc
#	echo 'alias ome_zarr=$HOME/OME_Zarr_Tools/apps/zseg.sh' >> ~/.bashrc
fi;

source ~/.bashrc
if ! ls ~/miniconda3/envs | grep nflow &> /dev/null;
then
	conda env create -f $ROOT/nextflow_env.yml;
	echo 'alias nextflow=$HOME/OME_Zarr_Tools/apps/nextflow.sh' >> ~/.bashrc;
fi;

source ~/.bashrc
if ! cat ~/.bashrc | grep batchonvert;
then
  echo 'alias batchconvert=$HOME/OME_Zarr_Tools/BatchConvert/batchconvert.sh' >> ~/.bashrc;
fi;
source ~/.bashrc;


source ~/.bashrc
if ! cat ~/.bashrc | grep zseg;
then
  echo 'alias zseg=$HOME/OME_Zarr_Tools/ZarrSeg/zseg' >> ~/.bashrc;
  chmod 777 $HOME/OME_Zarr_Tools/ZarrSeg/main.py;
  chmod 777 $HOME/OME_Zarr_Tools/ZarrSeg/zseg;
fi;
source ~/.bashrc;

#### configure mc
if ! cat $HOME/.bashrc | grep ACCESSKEY &> /dev/null;
then
	echo ACCESSKEY=$1 >> $HOME/.bashrc;
fi;

if ! cat $HOME/.bashrc | grep SECRETKEY &> /dev/null;
then
	echo SECRETKEY=$2 >> $HOME/.bashrc;
fi;

source $HOME/.bashrc;

chmod -R a+rwx $ROOT/../apps;
mc alias set s3minio https://s3.embl.de $ACCESSKEY $SECRETKEY;

source $HOME/.bashrc;

### Make sure the correct python is used in the batchconvert script
v_info=$( python --version )
VP=${v_info:7:1}

if [[ $VP == 3 ]];
  then
    printf "The following python will be used to execute python commands in batchconvert script: $( which python ) \n"
    if ! [ -f $ROOT/..BatchConvert/pythonexe ];then
	    ln -s $( which python ) $ROOT/../BatchConvert/pythonexe;
    fi
elif ! [[ $VP == 3 ]];
  then
    printf "Python command refers to the following python: $( which python ), which cannot be used in the batchconvert script \nWill search the system for python3 \n";
    if command -v python3 &> /dev/null;
      then
	      printf "python3 was found at $( which python3 ) \n";
	      printf "This python will be used in the batchconvert script \n";
        if ! [ -f $ROOT/..BatchConvert/pythonexe ];then
	        ln -s $( which python3 ) $ROOT/..BatchConvert/pythonexe;
        fi
      else
        printf "Looks like python3 does not exist on your system or is not on the path. Please make sure python3 exists and on the path. \n"
        exit
    fi
fi
# configure batchconvert s3
batchconvert configure_s3_remote --remote s3minio --url https://s3.embl.de --access $ACCESSKEY --secret $SECRETKEY --bucket ome-zarr-course

