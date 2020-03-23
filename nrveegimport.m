% Imports a Nervus(TM)-format EEG file to EEGLAB.
% Usage: nrveeg_import(eegfilename, channelsselect, evenfilename)
%
% eegfilename    : path and filename of the Nervus(TM) EEG file format
% channelsselect :  one-dimensional array of channels to include
% eventfilename  : name of text file that contains events
%
% A external utility (nrveeg_export.exe) is used to export the data to a 
% simple binary  format. This utility exports the data "raw", that is: 
% referenced to the reference electrode and unfiltered. 
% Hence, use pop_reref() and pop_eegfilt to make it look more like an
% ordinary EEG.
%
% BUGS: There is an apparent bug in the event latencies
% Event latencies are imported correctly, and stored correctly in 
% EEG.events. However, pop_editeventvals shows them off by about 3 
% milliseconds.

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

function [EEG, command] = nrveeg_import(eegfilename, channelsselect)
    EEG = eeg_emptyset;
    command = sprintf('nrveegimport(''%s'',[%s])',eegfilename,num2str(channelsselect));
    disp(sprintf('Command: %s',command));
    
    %disp(sprintf('nrveegimport: calling parameter eegfilename is: %s',eegfilename))
    [pathstr, name, ext, versn] = fileparts(eegfilename);
    
    if (strcmp(ext,'.e')==1) 
        %THE FILE NEEDS TO BE CONVERTED FROM Nervus EEG to Haukeland custom
        %binary format, by the utility.
        %TODO: Make the utility run under WINE under *NIX platform. Done!
        if (nrveegcheckinstall()<0)
            error('nrveegimport: Conversion utility not installed');
        end

        if (strcmp(computer,'GLNXA64')==0 && strcmp(computer,'GLNX86')==0 && strcmp(computer,'PCWIN')==0 && strcmp(computer,'PCWIN64')==0)
            error('nrveegimport: Conversion utility not available on this platform!')
        end
        
        if (strcmp(computer,'GLNXA64')==1 || strcmp(computer,'GLNX86')==1)             
            selfdir = fileparts(which('eegplugin_nrveegimport'));                        
            programpath = [ 'WINEPREFIX=' getenv('HOME') '/nrveegimport/.wine wine C:\\Program\ Files\\nrveegexport\\nrveeg_export.exe'];        
            disp(programpath);
            tempoutput = tempname;
            tempevent = tempname;
            convertcommand = [programpath ' -i Z:' eegfilename ' -o Z:' tempoutput ' -e Z:' tempevent]
        else
            programpath = [ getenv('ProgramFiles') '\nrveegexport\nrveeg_export.exe'];
            tempoutput = tempname;
            tempevent = tempname;
            convertcommand = ['"' programpath '" -i "' eegfilename '" -o "' tempoutput '" -e "' tempevent '"']
        end

        disp(sprintf('Running conversion utility...'));
        system(convertcommand);
        fid = fopen(tempoutput,'rb');
        if (fid<0)
            disp(convertcommand);
            error('nrveegimport:conversion error');
        end
        eventfilename = tempevent;

    elseif (strcmp(ext,'.hcb')==1)
        %FILE IS PRE-CONVERTED
        fid = fopen(eegfilename,'rb');
        if (fid<0)
            error('nrveegimport: Cannot open the specified file with .hcb extension');
        end
        eventfilename = fullfile(pathstr,[name '.evt']);
    else
        %disp(sprintf('Error with EEG file name: %s',eegfilename))
        error('nrveegimport: Don''t know what to do with files with that file extension');
        return;
    end

    channels=fread(fid,1, 'int32');
    disp(sprintf('Channels: %d',channels));
    chaninfolen=fread(fid,1,'int32');
    disp(sprintf('Channel info byte length: %d',chaninfolen));

    disp(sprintf('\nReading EEG channel information...\n'));
    disp(sprintf('Channel   Name    Srate  uV/cm a b c Count'));
    for i=1:channels
        chaninfo(i).channame=native2unicode(fread(fid,32,'uchar')');
        chaninfo(i).samplingrate=fread(fid,1,'double');
        chaninfo(i).resolution=fread(fid,1,'double');
        chaninfo(i).isderived=fread(fid,1,'int8');    
        chaninfo(i).isbipolar=fread(fid,1,'int8');    
        chaninfo(i).isAC=fread(fid,1,'int8');    
        chaninfo(i).samplecount=fread(fid,1,'int32');
        chaninfo(i).pad=fread(fid,2,'uchar');
        dummy = sprintf('%2.0d   %10s   %3.0d   %5.4f   %01.0f %01.0f %01.0f ', ...
            i,chaninfo(i).channame,chaninfo(i).samplingrate, ...
            chaninfo(i).resolution,chaninfo(i).isderived,chaninfo(i).isbipolar,...
            chaninfo(i).isAC,chaninfo(i).samplecount);
        disp(dummy);
    end
    
    %select only channels that have the same sampling rate as the first
    %channel
    wantsamplecount = chaninfo(1).samplecount;
    wantchannels = [];
    for i=channelsselect
        if (chaninfo(i).samplecount == wantsamplecount)
            wantchannels = [wantchannels i];
        end
    end
    
    if (length(wantchannels) ~= length(channelsselect)) 
       disp(sprintf('Some channels DROPPED because of different sample counts'));
       channelsselect = wantchannels;
    end 

    

    disp(sprintf('\nReading EEG data channel by channel...\n'));
    eegdata = [];
    disp(sprintf('Channels %d',channels));
    for i=[channelsselect]
        disp(sprintf('%10s %10d',chaninfo(i).channame,chaninfo(i).samplecount));

        data = fread(fid,chaninfo(i).samplecount,'int16')';
        data = -data*chaninfo(i).resolution;
        eegdata = cat(1,eegdata,data);
    end   
    fclose(fid);

    EEG = eeg_emptyset;
    EEG.nbchan = max(channels);
    EEG.srate = chaninfo(1).samplingrate;
    EEG.data            = eegdata;
    EEG.setname 		= sprintf('Nervus EEG import %s', [name ext]);
    EEG.xmin            = 0; 
    EEG.trials   = 1;
    EEG.pnts     = size(EEG.data,2);
    EEG.chanlocs = struct('labels', cellstr(char(chaninfo(channelsselect).channame)));
    EEG = eeg_checkset(EEG);

    clear chaninfo chaninfolen channels data dummy eegdata i fid
    
    %Import events
    fid = fopen(eventfilename,'r');            
    if (fid<0)
        disp(sprintf('Event file not found, nothing to import. (%s)',eventfilename));
    else
        disp(sprintf(' ')); 
        disp(sprintf('Importing events'));
        [ev_latencies, ev_dur, ev_type, ev_comment] = textread(eventfilename,'%f %f %q %q','delimiter','\t','emptyvalue',NaN);
        j = 0;
        for i=1:size(ev_latencies,1)
            if ((ev_latencies(i)*EEG.srate)<size(EEG.data,2)) 
                j = j+1;
                EEG.event(j).latency = ev_latencies(i)*EEG.srate;
                EEG.event(j).type = char(ev_type(i));
                EEG.event(j).position = char(ev_comment(i));
                if (not(isnan(ev_dur(i))))
                    EEG.event(j).duration = ev_dur(i)*EEG.srate;
                end
                disp(sprintf('Added event number %02d as event number %02d. Latency: %010.4d (secs), %010.0f (data units)',i,j,EEG.event(j).latency,EEG.event(j).latency*EEG.srate))
            else 
                disp(sprintf('Event %d is after end of data!',i))
            end
        end
        clear ev_latencies ev_type ev_dur ev_comment i j 

        disp(sprintf(' '));
        EEG = eeg_checkset(EEG, 'eventconsistency');
    end   
    disp(sprintf(' ')); 
    disp(sprintf('NOTE: There are minor bugs in the event latencies. EEGLAB shows these as off by 3 milliseconds.'));
    disp(sprintf('Some events are removed. This program author does not know why'));
    return;
end

%WINEPREFIX=/usr/local/matlab74/toolbox/eeglab/plugins/nrveegimport/.wine wine C:\\Program\ Files\\nrveegexport\\nrveeg_export.exe -i "Z:\/usr/local/matlab74/toolbox/eeglab/plugins/nrveegimport/installer/jcb.e" -o "/tmp/tp025539" -e "/tmp/tp025540"
