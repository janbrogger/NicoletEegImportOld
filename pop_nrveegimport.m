    % Imports a Nervus(TM)-format EEG file to EEGLAB. Windows only.
% Usage
%  >> [EEG, command] = nrveegimport(eegfilename, channelsselect, evenfilename)
%
% Inputs:
%   eegfilename    : path and filename of the Nervus(TM) EEG file format
%   channelsselect :  one-dimensional array of channels to include
%   eventfilename  : name of text file that contains events
%
% Outputs
%   EEG            : an EEGLAB EEG structure with the imported data
%   command        : a copy of the function call
%
% A external utility (nrveeg_export.exe) is used to export the data to a 
% simple binary  format. This file must be installed first from the 
% "nrveegexport.msi" Windows installer

% This utility exports the data "raw", that is: 
% referenced to the reference electrode and unfiltered. 
% Hence, use pop_reref() and pop_eegfilt to make it look more like an
% ordinary EEG.
%
% BUGS: There is an apparent bug in the event latencies
% Event latencies are imported correctly, and stored correctly in 
% EEG.events. However, pop_editeventvals shows them off by about 3 
% milliseconds.
%
% Author: Jan Brogger, University of Bergen (jan.brogger@nevro.uib.no)

% THIS SOFTWARE IS PROVIDED UNDER THE FOLLOWING LICENSE
% This program is free software; you can redistribute it and/or modify it under the terms
% of the GNU General Public License as published by the Free Software Foundation;
% either version 2 of the License, or (at your option) any later version.
% This program is distributed in the hope that it will be useful, but WITHOUT ANY
% WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
% You should have received a copy of the GNU General Public License along with this
% program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite
% 330, Boston, MA 02111-1307, USA

function [EEG, command] = pop_nrveegimport(setname, filepath, channels); 
    
    EEG = [];
    command = '';
    
    if nargin <2
        % ask user
        if (strcmp(computer,'PCWIN')==1)
            extensions = {'*.e';'*.hcb'};
        elseif (strcmp(computer,'GLNX86')==1 || strcmp(computer,'GLNXA64'))
            %if we have the conversion utility, we can read both .e and
            %.hcb, otherwise only .hcb preconverted files
            if nrveegcheckinstall()<0
                extensions = {'*.hcb'};                
            else
                extensions = {'*.e';'*.hcb'};
            end
        else
            %for other platforms, we can only read pre-converted files
            extensions = {'*.hcb'};
        end
        [setname, filepath] = uigetfile(extensions, 'Choose a Nervus EEG file -- pop_nrveegimport()');         
        drawnow;
        if (setname == 0) 
            return; 
        end;        
    end;

    eegfilename = fullfile(filepath,setname);    
    [pathstr, name, ext, versn] = fileparts(eegfilename);


    %If the file has been pre-converted, then we can pre-read the number of
    %channels and read all of them
    channels = [];
    if (strcmp(ext,'.hcb')==1)
       fid = fopen(eegfilename,'rb');
       if fid>=0
           numchannels=fread(fid,1, 'int32');
           channels = 1:numchannels;
           fclose(fid);
       end       
    end
    
    if nargin < 3 && isempty(channels)
        channelsstr = inputdlg('Enter channels to import','Enter channels to import -- pop_nrveegimport()',1);
        if (isequal(channelsstr,{''}))
            return;
        end
        %convert from returned cell array with one element to a single
        %array
        channelsstr = cell2mat(channelsstr);
        channels = eval(channelsstr);
    end
    

    
    EEG = eeg_emptyset;
    [EEG command] = nrveegimport(eegfilename,channels);
    disp(sprintf('nrveegimport command was: %s',command));
    
    EEG = eeg_checkset(EEG);   
    
    command = sprintf('[EEG command] = pop_nrveegimport(''%s'',[%s]);', eegfilename, num2str(channels)); 
    return;
end