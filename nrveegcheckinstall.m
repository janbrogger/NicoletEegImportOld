%function nrveegcheckinstall()
%checks that the program file for the conversion utility is in place
% under Linux/Wine or Intel/Windows - doesn't work with other utilities
function returnvalue = nrveegcheckinstall()

    %find out where we are
    try 
        selfdir = fileparts(which('eegplugin_nrveegimport'));                        
    catch
        disp(sprintf('nrveegimport: Could not find my own directory!'));
        disp(sprintf('nrveegimport: aborting...'));                
        return;
    end

    if (strcmp(computer,'PCWIN')==1 || strcmp(computer,'PCWIN64')==1)
        programpath = [ getenv('ProgramFiles') '\nrveegexport\nrveeg_export.exe'];        
    elseif (strcmp(computer,'GLNX86')==1 || strcmp(computer,'GLNXA64')==1)
        programpath = [ getenv('HOME') '/nrveegimport/.wine/drive_c/Program Files/nrveegexport/nrveeg_export.exe'];        
    else
        disp(['nrveegimport (platform: ' computer '): don''t know how to work on this platform!' ]);
        returnvalue = -1;
        return;
    end
    
    fid = fopen(programpath,'rb');
    if fid<0
        disp(['nrveegimport (platform: ' computer '): cannot find the conversion utility! It should be at:' ]);
        disp(programpath);
        returnvalue = -1;
        return;
    else
        fclose(fid);
        disp(['nrveegimport (platform: ' computer '): the conversion utility appears to be in place.' ]);        
        returnvalue = programpath;
        return;
    end    
end

        