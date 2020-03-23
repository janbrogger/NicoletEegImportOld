%function nrveeginstall()
%installs the program utility that does the conversion
%known to work under MATLAB 7.4 and Ubuntu Gutsy Gibbon on a Intel 64-bit
%PC
function returnvalue = nrveeginstall()

    %find out where we are
    try 
        selfdir = fileparts(which('eegplugin_nrveegimport'));                        
    catch
        disp(sprintf('nrveegimport: Could not find my own directory!'));
        disp(sprintf('nrveegimport: aborting...'));                
        return;
    end
    
    if (strcmp(computer,'PCWIN')==1 || strcmp(computer,'PCWIN64')==1)
        installcmd = [ 'msiexec ' selfdir '\installer\nrveegexport.msi'];        
        [status result ] = system(installcmd);
        if status==0 
            disp('nrveegimport: Apparently the install was successfull');
            if nrveegcheckinstall()<0
                disp('nrveegimport: After double-checking, the install was not successful after all');
                returnvalue = -1;
                return;
            else
                disp('nrveegimport: And after double checking, it was apparently successful');
                returnvalue = 0;
                return;
            end
        else
            disp('nrveegimport: Apparently the install was NOT succesfull');
            disp(['nrveegimport: Attempted to execute: ' installcmd]);            
            disp(result);            
            returnvalue = -1;
            return;
        end        
    elseif (strcmp(computer,'GLNX86')==1 || strcmp(computer,'GLNXA64')==1)
        %first we need to create a nrveegimport directory in the users home
        %directory
        status = mkdir([getenv('HOME') '/nrveegimport']);
        if status==0
            disp(['nrveegimport: Could not create directory ' getenv('HOME') '/nrveegimport' ]);
            returnvalue = -1;
            return;
        end    
        %now run the installer script
        installcmd = [ 'cd ' selfdir '/installer;./install.sh ' getenv('HOME') '/nrveegimport/.wine'];        
        [status result] = system(installcmd);
        if status==0 
            disp('nrveegimport: Apparently the install was successfull');
            if nrveegcheckinstall()<0
                disp('nrveegimport: After double-checking, the install was not successful after all');
                returnvalue = -1;
                return;
            else
                disp('nrveegimport: And after double checking, it was apparently successful');
                returnvalue = 0;
                return;
            end
        else
            disp('nrveegimport: Apparently the install was NOT succesfull');
            disp(['nrveegimport: Attempted to execute: ' installcmd]);
            disp(result);
            returnvalue = 0;
            return;
        end        
    else
        disp(['nrveegimport (platform: ' computer '): don''t know how to work on this platform!' ]);
        returnvalue = -1;
        return;
    end
    
end

        