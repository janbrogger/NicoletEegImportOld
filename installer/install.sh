#!/bin/bash 
# check the number of command line arguments
if [[ $# < 1 ]]; then  
	echo Please specify a directory to install the Wine box to
	echo The directory must exist.
	exit -1
fi
#check that Wine is installed
wine --version
if [ $? -ne 0 ]; then
	echo Wine does not appear to be installed\!
	exit -1
fi
NRVEEGCONVERTWINE=$1
export NRVEEGCONVERTWINE
#make our own little windows box to put the program in
rm -rf $NRVEEGCONVERTWINE
#we must use windows 98 and some other modifications to wine
WINEDEBUG=-all WINEPREFIX=$NRVEEGCONVERTWINE wineprefixcreate 2>/dev/null 1>/dev/null
WINEDEBUG=-all WINEPREFIX=$NRVEEGCONVERTWINE wine regedit nativemsi.reg 2>/dev/null
#copy ourselves to the c:\ root of the new windows box
#note that THIS FAILS if the current directory is not the same as the script location!
cp *.* $NRVEEGCONVERTWINE/drive_c
if [ -f $NRVEEGCONVERTWINE/drive_c/jcb.e ]
then
 echo Yes, needed files have been copied to the Wine box >/dev/null
else
 echo Couldn\' copy the needed files to the Wine box\!
 exit -1
fi
echo Setting up the Wine box in it\'s own directory
rm $NRVEEGCONVERTWINE/drive_c/*.hcb 2>/dev/null
rm $NRVEEGCONVERTWINE/drive_c/windows/system32/msiexec.exe
rm $NRVEEGCONVERTWINE/drive_c/windows/system32/msi.dll
cd $NRVEEGCONVERTWINE/drive_c/
echo Installing the Windows MSI installer
#now install the new windows MSI installer
WINEDEBUG=-all WINEPREFIX=$NRVEEGCONVERTWINE wine InstMsiA.exe /q >/dev/null
echo Installing the EEG conversion program...
#install the EEG conversion program
cd $NRVEEGCONVERTWINE/drive_c/windows/Installer/InstMsi0
WINEDEBUG=-all WINEPREFIX=$NRVEEGCONVERTWINE wine c:\\windows\\Installer\\InstMsi0\\msiexec /i c:\\nrveegexport.msi /qn >/dev/null
#now test-convert one EEG
echo Test-convert one EEG
cd $NRVEEGCONVERTWINE/drive_c/Program\ Files/nrveegexport
WINEDEBUG=-all WINEPREFIX=$NRVEEGCONVERTWINE wine nrveeg_export -i c:\\jcb.e -o c:\\jcb.hcb -d 3   >install.log
if [ -f $NRVEEGCONVERTWINE/drive_c/jcb.hcb ]
then
  echo Success\! 
  echo The Nervus EEG conversion program has been
  echo installed in its own WINE box in
  echo $NRVEEGCONVERTWINE
  echo The test file was converted successfully\!
else
  echo Failure \!
  echo The test file was NOT converted succcessfully
  echo Run the install script line by line manually to 
  echo see what went wrong
fi
exit 0
