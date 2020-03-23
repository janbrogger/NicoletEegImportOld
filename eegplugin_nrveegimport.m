%function [EEG, command] = nrveegimport(eegfilename, channelsselect)
function eegplugin_nrveegimport( fig, try_strings, catch_strings);

    %find out where we are
    try 
        selfdir = fileparts(which('eegplugin_nrveegimport'));                        
    catch
        disp(sprintf('nrveegimport: Could not find my own directory!'));
        disp(sprintf('nrveegimport: aborting...'));                
        return;
    end

    %find the file import menu
    fileimportmenu = findobj(fig, 'tag', 'import data');
    
    % import command
    % build command for menu callback
    importcmd =  '[EEG LASTCOM] = pop_nrveegimport();';
    
    finalimportcmd = [ try_strings.no_check importcmd];
    finalimportcmd = [ finalimportcmd 'LASTCOM = ''' importcmd ''';' ];
    finalimportcmd = [ finalimportcmd catch_strings.store_and_hist ];
    
   
    %add new submenu
    submenu = uimenu(fileimportmenu,'label','From Nervus EEG file...');
    uimenu(submenu, 'label','From Nervus EEG file', 'callback' , finalimportcmd);
    uimenu(submenu, 'label','Check that conversion utility is installed', 'callback' , 'nrveegcheckinstall();');    
    uimenu(submenu, 'label','Install conversion utility (Windows/Wine)', 'callback' , 'nrveeginstall();');        
end     
