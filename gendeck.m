function [settings,freqlist]=gendeck(outputfilename,settings,layoutfilename,devicefilename,...
    varargin)
% Deck Generator for DynacGUI
%
% Reads in a layout file, device type file, and array of settings,
% and outputs a (hopefully) properly formatted Dynac deck.
% The final, optional argument, is the name of an input distribution file.
%
%Returns the modified list of settings and a list of frequencies at each graph
%position.
%
%  This software is Copyright by the Board of Trustees of Michigan
%  State University (c) Copyright 2015.
%  
%   Contact Information:
%    Facility for Rare Isotope Beam
%    Michigan State University
%    East Lansing, MI 48824-1321
%    http://frib.msu.edu
%  
%  
%
% Update Log
%
%11/18/13 - Updated RFQ card to automatically set the reference particle to
%the design energy given in the device file.
%11/23/13 - Fixed implementation of RFQ that was done incorrectly in last
%update. NOW it should properly handle off-energy particles.
%11/26/13 - Corrects slash directions RFQ and cavity definition file names 
%when generating decks on non-pcs.
%12/3/13 - Further attempts at optimizing RFQ code based on communication
%with ET
%3/20/14 - Added WRBEAM capability
%3/21/14 - Extensive changes to facilitate longer input distributions
%through RFQs
%4/8/14 - Added running frequency (runfreq) distinct from initial 
%frequency. (settings.RF)
%4/16/14 - Added STEER element, including electrostatics
%4/21/14 - Added RFKick element.
%7/7/14 - Modified to allow for arbirary particle distributions
%7/30/14 - Added ability to use Z twiss parameters instead of DC beam
%7/30/14 - Added space charge
%8/5/14 - Fixed bug with SCHEFF 1 mode
%9/11/14 - Added an "EMITL" card everywhere an emittance plot is generated
%9/17/14 - Changes to tau > RFQ routines to accomodate changes in Dynac
%        - Added 'STOP' command
%        - Added ability to comment out lines in the layout file with ';'
%9/18/14 - Added "EMITL" as an option in the layout file
%10/9/14 - Added a rejection of off-energy particles after RFQ
%10/13/14 - Added ability to comment lines in a device file
%10/28/14 - Added support for multi-charge state beams NOT TESTED
%2/12/15 - Displays an error if cavity or RFQ files are missing.
%3/10/15  - Added unit tracking.  Still needs some work.
%3/13/15 - Added the ability to manually set field on dipole magnets
%3/16/15 - Unit tracking converted to structure array, now much more
%robust. Still needs multicharge state support.
%3/19/15 - Added error checking for missing settings in the tune settings
%file
%3/24/15 - Generating a deck with no errors returns a success message.
%3/31/15 - Added unit tracking for multi charge state beams.
%4/6/15 - Updated for new version of EDFLEC with arbitrary field settable
%4/15/15 - Fixed a bug with electrostatic deflectors
%4/22/15 - Made default number of sectors in benders 10, and moved
%parameter to top of file
%4/29/15 - Checking for correct number of sectors and space charge type for
%multi-charge state beam
%        - Now reading default values for sectors and RFQreject from .ini
%        file
%6/3/15  - Added support for SECORD, FIRORD, and SEXTUPO cards.
%6/8/15  - Added support for FDRIFT, QUADSXT, SOQUAD
%6/10/15 - Added support for FSOLE
%6/11/15 - Added suppot for systematic errors in accelerating elements
%                   (MMODE)
%7/8/15 - Added support for ZONES
%7/15/15 - Added some desperately need error checking.  Now fails
%           gracefully if you have a device in your layout
%           thats not in your devices file.
%7/24/15 - Added support for fractional rejection limits rather than
%absolute value.
%10/29/15 - Added support for "ACCEPT" card
%11/3/15 - Removed a specific check for "Edflec" variable in favor of a
%           general check for DynacVersion.
%        - For Dynac r15 and up, WRBEAM now writes reference particle
%        energy
%        - For Dynac r15 and up all REJECT cards now default to rejecting
%        relative to the reference particle, not the center of gravity of
%        the bunch.
%11/13/15 - "Compiled Successfully" message forces output color to black.
%12/23/15 - Made integration steps across a cavity a settable parameter
%3/11/16 - Added support for using distribution widths, rather than CS
%parameters
%3/23/16 - Added optional parameters to SLIT to allow for offsetting the
%center.

%To Do
%       Put some error checking in Zones in case of incorrect numbers of
%       input parameters.

%-----Default Parameters----% (Included for legacy compatibility only - default
%                                   values are now set in main DynacGUI.m)
RFQreject=0.5; %Fractional deviation from average energy to be rejected after RFQ. Note
              %that this is from the average INCLUDING the unaccelerated
              %beam. (Fixed to relative to RP for Dynac v. 15 and up)
esectors=10; %Number of sectors for electrostatic bending elements
bsectors=10; %Number of sectors for magnetic bending elements
csectors=8; %Number of integration steps in cavities
%Default REJECT values
%Energy[Flag] Phase[deg] X[cm] Y[cm] R[cm] Flag - All are 1/2 widths
%Flag=1, Energy is absolute value in MeV from cog.
%Flag=0, Energy is fractional deviation from cog.
%Flag=11, Energy is absolute deviation from RP.
%Flag=10, Energy is fractional deviation from RP.
reject=[1000 4000 100 100 400 11]; 

%Define DynacGUI Window, get handles
figtag = 'DynacGUI';
guifig = findobj(allchild(0),'flat','Tag',figtag);
guihand = guidata(guifig);

%Adjust parameters from .ini file or defaults set in DynacGUI.m
if isfield(guihand.inivals,'RFQreject') %RFQ Rejection threshhold
    RFQreject=str2double(guihand.inivals.RFQreject);
end
if isfield(guihand.inivals,'Esectors') %Number of sectors for E deflectors
    esectors=str2double(guihand.inivals.Esectors);
end
if isfield(guihand.inivals,'Bsectors') %Number of sectors for B deflectors
    bsectors=str2double(guihand.inivals.Bsectors);
end
if isfield(guihand.inivals,'Csectors') %Number of integration steps for cavities
    csectors=str2double(guihand.inivals.Csectors);
end

%Dynac version specific checks
if isfield(guihand,'dynac_version') %Dynac version (default = 14)
    dynac_version=guihand.dynac_version;
else
    dynac_version=14;
end
if dynac_version<=12 %Set E deflector type based on version
    edflectype=3;
else
    edflectype=4;
end
if dynac_version<=14 %For versions without RP referencing, use cog in all cases
    reject(6)=mod(reject(6),10);
end

clearerror(guihand);
runfreq=settings.RF; %Initial Frequency of line
freqlist=[];
unitstruct=structfun(@(x)([]),settings,'UniformOutput',0);
unitstruct.A='[AMU]';
unitstruct.Q='[Q]';
unitstruct.RF='[Hz]';
unitstruct.Betax='[mm/mrad]';
unitstruct.Epsx='[mm.mrad]';
unitstruct.Betay='[mm/mrad]';
unitstruct.Epsy='[mm.mrad]';
unitstruct.Deltae='[MV]';
unitstruct.Energy='[MV]';


errorflag=0; %This flag is set if an error is reported.

%Scan device file for device parameters
devicefile=fopen(devicefilename);
i=1;
while ~feof(devicefile)
    line=fgetl(devicefile);
            if regexp(line,'^;') %Skip comment lines
                continue
            end
    devices{i,:}=regexp(line,'\t','split'); %#ok<AGROW>
    i=i+1;
end
devicetypes=cellfun(@(x) x{1},devices,'UniformOutput',false);
fclose(devicefile);

%Open output file for writing
outfile=fopen(outputfilename,'w');

%scan layout file
layoutfile=fopen(layoutfilename);
cavfield='';

%Write header information
if isfield(settings,'longdist') && settings.longdist==2
    
%---This branch is for the post-RFQ portion of a beamline.---

%Write header information based on input distribution, and scrolls forward
%in input file past RFQ.  
    runfreq=str2double(settings.rfqfreq)*10^6;%Running Frequency should be RFQ freq
    fprintf(outfile,';%s\r\n',outputfilename);%File Title
    fprintf(outfile,'%s\r\n','RDBEAM');%Read Beam Command
    fprintf(outfile,'%s\r\n',varargin{1});%Distribution File Name
    fprintf(outfile,'%s\r\n','2'); %flag for including charge state
    fprintf(outfile,'%s 0\r\n',settings.rfqfreq);%frequency [MHz]/ phase
    fprintf(outfile,'931.494 %g\r\n',settings.A);%AMU / Mass
    fprintf(outfile,'%g %g\r\n',settings.refenergy,settings.Q);%Energy / Charge
    fprintf(outfile,'REFCOG\r\n1\r\n');%REFCOG command
    card{1,1}='';
    %Wind past RFQ in the layout file
    while ~strcmp(card{1,1},'RFQPTQ') && ~feof(layoutfile)
        line=fgetl(layoutfile);
        card=regexp(line,'\t','split');
    end
    
elseif nargin==5;
    
%---This branch used if a particle distribution file has been specified.---
    if length(varargin{1})>80
        distfile=(varargin{1}(length(pwd)+2:end));
    else
        distfile=varargin{1};
    end
    fprintf(outfile,';%s\r\n',outputfilename);%File Title
    fprintf(outfile,'%s\r\n','RDBEAM');%Read Beam Command
    fprintf(outfile,'%s\r\n',distfile);%Distribution File Name
    fprintf(outfile,'%s\r\n','2'); %flag for including charge state
    fprintf(outfile,'%g 0\r\n',settings.RF*10^-6);%frequency[MHz] / phase
    fprintf(outfile,'931.494 %g\r\n',settings.A);%AMU / Mass
    fprintf(outfile,'%g %g\r\n',settings.Energy,settings.Q);%Energy / Charge
else
    
%---This is the default branch (no particle dist, no RFQ)---%    
    
    %Write header information from initial parameters
    if ~isfield(settings,'ZLaw')
        settings.ZLaw=5;
        unitstruct.ZLaw=[];
    end
    itwiss = 1; %default value
    ZLaw = settings.ZLaw;
    
    %Check for missing parameters
    if (settings.ZLaw==5 || settings.ZLaw==6) && ~isfield(settings,'Deltae')
        disperror(['Error: ZLaw ' num2str(setting.ZLaw)...
            ' selected with no energy spread specified']);
        return;
    end
    if settings.ZLaw<=4
        if ~isfield(settings,'Alphaz') || ~isfield (settings,'Betaz') ||...
            ~isfield(settings,'Epsz')
            disperror('Error: Insufficient Z Twiss Parameters Specified');
            return;
        end
    end
    if settings.ZLaw==6 && ~isfield(settings,'Betaz')
        disperror('Error: ZLaw 6 selected with no BetaZ specified.')
        return;
    end
    if settings.ZLaw >= 11
        if ~isfield(settings,'Xmax') || ~isfield(settings,'XPmax') ||...
                ~isfield(settings,'Ymax') || ~isfield(settings,'YPmax') ||...
                ~isfield(settings,'Tmax')
            disperror('Error: Insufficient beam size parameters specified');
            return;
        end
        itwiss=0;
        ZLaw = ZLaw - 10;
    end
    fprintf(outfile,';%s\r\n',outputfilename); %Beamline Name
    fprintf(outfile,'%s\r\n','GEBEAM');
    fprintf(outfile,'%g %g\r\n',ZLaw,itwiss); %Distribution Type
    fprintf(outfile,'%g\r\n',settings.RF); %RF frequency
    fprintf(outfile,'%g\r\n',settings.Npart); %Number of particles
    fprintf(outfile,'%g %g %g %g %g %g\r\n',0,0,0,0,0,0); % Starting offset
    if settings.ZLaw<=6
        %X Twiss parameters:
        fprintf(outfile,'%g %g %g\r\n',settings.Alphax,settings.Betax,settings.Epsx); 
        %Y Twiss parameters:    
        fprintf(outfile,'%g %g %g\r\n',settings.Alphay,settings.Betay,settings.Epsy);    
        %Energy Parameters
        if settings.ZLaw==5
            %Energy width, dummy(x2)
            fprintf(outfile,'%g %g %g\r\n',settings.Deltae,0,0); 
        else
            %Z Twiss Parameters
            fprintf(outfile,'%g %g %g\r\n',settings.Alphaz,settings.Betaz,...
                settings.Epsz);
            unitstruct.Betaz='[deg/keV]';
            unitstruct.Epsz='[deg.keV]';
        end
    end
    if settings.ZLaw >= 11
        %Beam Extent
        fprintf(outfile,'%g %g %g %g %g %g\r\n',...
            settings.Xmax,settings.XPmax,settings.Ymax,settings.YPmax,...
            settings.Deltae,settings.Tmax);
    end
    fprintf(outfile,'%s\r\n','INPUT');
    fprintf(outfile,'%g %g %g\r\n',931.49432,settings.A,settings.Q);
    fprintf(outfile,'%g %g\r\n',settings.Energy,0);
    
%---Multiple Charge State Beam---%
    if isfield(settings,'Nstates')
        if ~isfield(settings,'ZLaw')
            settings.ZLaw=5;
            unitstruct.ZLaw=[];
        end
        nstates=settings.Nstates; %number of charge states
            switch nstates
                case 0 %Update at some point if manual charge state files desired
                    disperror('Error: Reading charge states from file not supported.');
                case 1 %What is the point of specifying ETAC and then just one charge state?
                otherwise
                    if nstates > 20 %Check for too many charge states
                        disperror('Error: No more than 20 charge states allowed.');
                        return;
                    end;
                    fprintf(outfile,'ETAC\r\n');
                    fprintf(outfile,'%g\r\n',nstates);
                    for k=1:nstates
                        try
                        fprintf(outfile,'%g %g %g\r\n',...
                            eval(strcat('settings.cs',num2str(k))),...
                            eval(strcat('settings.cspcent',num2str(k))),...
                            eval(strcat('settings.cseoff',num2str(k))));
                            %Record units
                            unitstruct.(strcat('cs',num2str(k)))='[Q]';
                            unitstruct.(strcat('cspcent',num2str(k)))='[%]';
                            unitstruct.(strcat('cseoff',num2str(k)))='[MeV]';
                        catch %Throw an error if there are missing parameters
                            disperror('Missing Charge State Data');
                        end
                    end
                    %Adjust number of deflector sectors, if needed
                    if esectors == 1;
                        esectors=2;
                    end
                    if bsectors ==1;
                        bsectors=2;
                    end
            end
    end
end



i=1; %Counts the number of plots
while ~feof(layoutfile)
    line=fgetl(layoutfile);
    if regexp(line,'^;')
        fprintf(outfile,'%s\r\n',line);
        continue
    end
    card=regexp(line,'\t','split');
    switch card{1,1}
        case 'ACCEPT' %Acceptance plots
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            xlim=devices{id,1}{1,3};
            xplim=devices{id,1}{1,4};
            zlim=devices{id,1}{1,5};
            zplim=devices{id,1}{1,6};
            fprintf(outfile,'ACCEPT\r\n');
            fprintf(outfile,'%s\r\n',card{1,3});
            fprintf(outfile,'%s %s\r\n','1',devices{id,1}{1,2});
            fprintf(outfile,'%s %s %s %s %s %s %s %s\r\n',...
                xlim,xplim,xlim,xplim,xlim,xlim,zlim,zplim);
            fprintf(outfile,'%s\r\n',card{1,4});
            fprintf(outfile,'%s %s\r\n','1',devices{id,1}{1,2});
            fprintf(outfile,'%s %s %s %s %s %s %s %s\r\n',...
                xlim,xplim,xlim,xplim,xlim,xlim,zlim,zplim);
            freqlist=[freqlist runfreq runfreq];
            i=i+2;
        case 'BMAGNET' %Bending Magnet
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            if (length(card)>=3) && isfield(settings,card{1,3}) && ~isempty(settings.(card{1,3}))
                %If thre is a third parameter
                bfield=num2str(settings.(card{1,3})); %Set magnetic field manually
                unitstruct.(card{1,3})='[kG]';
            else
                bfield='0'; %Bfield is automatic.
                %Note: There is no way to have a magnet defined with exactly 0
                %field, since setting field to 0 makes it automatic.
            end
            fprintf(outfile,'%s\r\n','BMAGNET');
            fprintf(outfile,'%s\r\n',num2str(bsectors));
            fprintf(outfile,'%s %s %s %s %s\r\n',devices{id,1}{1,2},...
                devices{id,1}{1,3},bfield,'0','0');
            fprintf(outfile,'%s %s %s %s %s\r\n',devices{id,1}{1,4},...
                devices{id,1}{1,5},'.45','2.8',devices{id,1}{1,6});
            fprintf(outfile,'%s %s %s %s %s\r\n',devices{id,1}{1,7},...
                devices{id,1}{1,8},'.45','2.8',devices{id,1}{1,9});          
        case 'BUNCHER' %Buncher
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            if ~isfield(settings,card{1,4}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,4}],1);
                continue
            end
            if ~isfield(settings,card{1,5}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,5}],1);
                continue
            end
            fprintf(outfile,'%s\r\n','BUNCHER');
            fprintf(outfile,'%g %g %s %s\r\n',settings.(card{1,4}),...
                settings.(card{1,5}),card{1,3},devices{id,1}{1,2});
            unitstruct.(card{1,4})='[MV]';
            unitstruct.(card{1,5})='[deg]';
        case 'CAVNUM' %Accelerating Cavity
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            %Checks to see if this is a new cavity field type. If it is,
            %issue a FIELD command with the filename.
            if ~strcmp(cavfield,devices{id,1}{1,2})
                cavfield=devices{id,1}{1,2};
                if exist(cavfield,'file')==0 %Throw an error if cavity field not present
                    disperror(['Warning: Cavity file "' cavfield '" not found.'],errorflag)
                    errorflag=1;
                end
                if ~ispc
                    strrep(cavfield,'\','/');
                end
                fprintf(outfile,'%s\r\n','FIELD');
                %If we're writing to the scratch directory, adjust.
                if isfield(settings,'longdist') && settings.longdist>=1
                    fprintf(outfile,'%s\r\n',['..' filesep cavfield]);
                else
                fprintf(outfile,'%s\r\n',cavfield');
                end
                fprintf(outfile,'%s\r\n','1');
            end
            %In either case, define the cavity.
            if ~isfield(settings,card{1,3}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end
            if ~isfield(settings,card{1,4}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,4}],1);
                continue
            end
            fprintf(outfile,'%s\r\n','CAVNUM');
            fprintf(outfile,'%s\r\n','1');%dummy variable
            fprintf(outfile,'%s %g %g %g %s\r\n','0',settings.(card{1,4}),...
                settings.(card{1,3})-100,csectors,'1');
            unitstruct.(card{1,3})='[%]';
            unitstruct.(card{1,4})='[deg]';
        %case 'CAVSC' %Single symmetric accelerating cavity
        %    fprintf(outfile,'CAVSC\r\n');
        %    fprintf(outfile,'0 0 0 %s %s %s 0 0 0 0 %s %s 0 %s %s %s\r\n',...
        %        sclength,scttf,sctp,scefield,scphase,sctpp,scfreqency,...
        %        scefieldatten);
        case 'DRIFT' %Drift space
            fprintf(outfile,'%s\r\n','DRIFT');
            fprintf(outfile,'%s\r\n',card{1,2});
        case 'EDFLEC' %Electrostatic Deflector
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            fprintf(outfile,'%s\r\n','EDFLEC');
            fprintf(outfile,'%s\r\n',num2str(esectors));
            if edflectype==3 %Older versions with only three parameters
                fprintf(outfile,'%s %s %s\r\n', devices{id,1}{1,2},...
                    devices{id,1}{1,3}, devices{id,1}{1,4});
            else
                if length(card)==2
                %If the third parameter name is missing from the layout file
                    efield=-1;
                elseif isfield(settings,(card{1,3})) && ~isempty(settings.(card{1,3}))
                    %If the field is present and not empty, set the efield
                    efield=settings.(card{1,3});
                    unitstruct.(card{1,3})='[kV/cm]';
                else %Otherwise use nominal value
                    efield=-1;
                    unitstruct.(card{1,3})='[kV/cm]';
                end
                fprintf(outfile,'%s %s %s %g\r\n', devices{id,1}{1,2},...
                    devices{id,1}{1,3}, devices{id,1}{1,4}, efield);
            end
        case 'EMIT' %Dump beam data to dynac.short
            fprintf(outfile,'%s\r\n','EMIT');
        case 'EMITL' %Same as "EMIT" with a label
            fprintf(outfile,'EMITL\r\n');
            fprintf(outfile,'%s\r\n',card{1,2});
        case 'EMITGR' %Emittance Plot
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            xlim=devices{id,1}{1,3};
            xplim=devices{id,1}{1,4};
            zlim=devices{id,1}{1,5};
            zplim=devices{id,1}{1,6};
            fprintf(outfile,'%s\r\n','EMITGR');
            fprintf(outfile,'%s\r\n',card{1,3});
            fprintf(outfile,'%s %s\r\n','1',devices{id,1}{1,2});
            fprintf(outfile,'%s %s %s %s %s %s %s %s\r\n',...
                xlim,xplim,xlim,xplim,xlim,xlim,zlim,zplim);
            freqlist=[freqlist runfreq];
            i=i+1;
            fprintf(outfile,'EMITL\r\n'); %Add a parameter dump to dynac.short
            fprintf(outfile,'%s\r\n',card{1,3});
        case 'ENVEL' %Envelope Plot
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            fprintf(outfile,'%s\r\n','ENVEL');
            fprintf(outfile,'%s\r\n',card{1,3});
            fprintf(outfile,'%s\r\n',devices{id,1}{1,2});
            fprintf(outfile,'%s %s\r\n',devices{id,1}{1,3},...
                devices{id,1}{1,4});
            fprintf(outfile,'%s %s %s %s\r\n','0','0','0','0');
            freqlist=[freqlist runfreq];
            i=i+1;
        case 'FDRIFT' %Subdivided Drift
            fprintf(outfile,'%s\r\n','FDRIFT');
            fprintf(outfile,'%s %s 1\r\n',card{1,2},card{1,3});
        case 'FIRORD' %First order calculations for all elements
            fprintf(outfile,'FIRORD\r\n');
        case 'FSOLE' %Solenoid with field specified by external file
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            if ~isfield(settings,card{1,3}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end
            solfile=devices{id,1}{1,2};
            if ~ispc
                strrep(solfile,'\','/');
            end
            if exist(solfile,'file')==0 %Throw a warning if file isn't present
                disperror(['Warning: Solenoid file "' solfile '" not found.'],errorflag)
                errorflag=1;
            end
            nparts=devices{id,1}{1,3};
            fprintf(outfile,'FSOLE\r\n');
            fprintf(outfile,'%s\r\n',solfile);
            fprintf(outfile,'%g %s\r\n',settings.(card{1,3}),nparts);
            unitstruct.(card{1,3})='[kG]';
        case 'MMODE' %Systematic or random errors in cavities
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            fprintf(outfile,'MMODE\r\n');
            fprintf(outfile,'%s %s %s\r\n',devices{id,1}{1,2},...
                devices{id,1}{1,3},devices{id,1}{1,4});
        case 'NEWF' %New Frequency in Hz
            fprintf(outfile,'%s\r\n','NEWF');
            fprintf(outfile,'%s\r\n',card{1,2});
            runfreq=str2double(card{1,2});
        case 'NREF' %New Reference Particle
            fprintf(outfile,'%s\r\n','NREF');
            fprintf(outfile,'%s %s %s %s\r\n',card{1,2},card{1,3},...
                card{1,4},card{1,5});
        case 'QUADRUPO' %Magnetic Quadrupole
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            if ~isfield(settings,card{1,3}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end
            fprintf(outfile,'%s\r\n','QUADRUPO');
            fprintf(outfile,'%s %g %s\r\n',...
                devices{id,1}{1,2}, settings.(card{1,3}),...
                devices{id,1}{1,3});
            unitstruct.(card{1,3})='[kG]';
        case 'QUADSXT' %Combined magnetic quadrupole and sextupole
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            if ~isfield(settings,card{1,3}) %Check for missing sextupole setting
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end
            if ~isfield(settings,card{1,4}) %Check for missing quad setting
                disperror(['Error: Missing tune setting for ' card{1,4}],1);
                continue
            end
            fprintf(outfile,'%s\r\n','QUADSXT');
            fprintf(outfile,'1 %g 1 %g %s %s\r\n',...
                settings.(card{1,3}), settings.(card{1,4}),...
                devices{id,1}{1,2}, devices{id,1}{1,3});
            unitstruct.(card{1,3})='[kG]';
            unitstruct.(card{1,4})='[kG]';
        case 'QUAELEC' %Electrostatic Quad
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            if ~isfield(settings,card{1,3}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end
            fprintf(outfile,'%s\r\n','QUAELEC');            
            fprintf(outfile,'%s %g %s\r\n',...
                devices{id,1}{1,2}, settings.(card{1,3}),...
                devices{id,1}{1,3});
            unitstruct.(card{1,3})='[kV]';
        case 'REJECT' %Reject Card (used for apertures, slits, etc.)
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            for i=2:6
                reject(i-1)=str2double(devices{id,1}{1,i});
            end
            if reject(1)<0 
                %If energy value is negative, interpret as fractional
                %rather than absolute deviation. Use this information to
                %set the reject type flag, which is reject(6).
                reject(6)=0;
                reject(1)=abs(reject(1));
            else
                reject(6)=1;
            end
            if dynac_version>=15
                reject(6)=reject(6)+10;
            end
            fprintf(outfile,'%s\r\n','REJECT');
            fprintf(outfile,'%g %g %g %g %g %g\r\n',reject(6), reject(1),...
                reject(2),reject(3),reject(4),reject(5));
        case 'REFCOG'
            fprintf(outfile,'%s\r\n','REFCOG');
            fprintf(outfile,'%s\r\n',card{1,2});
        case 'RFKICK'
            %Note that rf kickers are NOT in the official
            %Dynac release as of 4/20/14.
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            steertype=devices{id,1}{1,2};
            if ~isfield(settings,card{1,4}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,4}],1);
                continue
            end
            if ~isfield(settings,card{1,5}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,5}],1);
                continue
            end            
            fprintf(outfile,'RFKICK\r\n');
                len=str2num(devices{id,1}{1,3});
                gap=str2num(devices{id,1}{1,4});
                voltage=settings.(card{1,4});
                phase=settings.(card{1,5});
                field=voltage*len/gap;
            fprintf(outfile,'%g %g %s %s\r\n',...
                field,phase,card{1,3},steertype);
            unitstruct.(card{1,4})='[kV]';
            unitstruct.(card{1,5})='[deg]';
        case 'RFQPTQ' %RFQ
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            %This branch is for the first part of the t>RFQ period routine
            %It terminates the deck immediately before the RFQ.
            if isfield(settings,'longdist') && settings.longdist==1
                distfile=strrep(outputfilename,'.in','.dst');
                distfile=regexprep(distfile,'dynacscratch.','');
                fprintf(outfile,'WRBEAM\r\n');
                fprintf(outfile,'%s\r\n',distfile);
                fprintf(outfile,'1 2\r\n');
                fprintf(outfile,'STOP\r\n');
                settings=setfield(settings,'rfqfreq',devices{id,1}{1,5});
                settings=setfield(settings,'rfqenergy',devices{id,1}{1,4});
                settings=setfield(settings,'rfqcells',devices{id,1}{1,3});
                settings=setfield(settings,'rfqfile',devices{id,1}{1,2});
                settings=setfield(settings,'longdist',0);%indicate RFQ encountered
                fclose all;
                return;
            end
            %This is the normal branch
            fprintf(outfile,'%s\r\n','REFCOG');
            fprintf(outfile,'%s\r\n','1');
            fprintf(outfile,'%s\r\n','NREF');
            %Calculate the difference in total energy between the reference
            %particle and the design energy of the RFQ. NOTE: This assumes
            %the reference particle is still at the initial energy. (Fix
            %this? How?)
            rfqenergy=str2double(devices{id,1}{1,4}); %RFQ design input energy [MeV/u]
            param2=(settings.A*rfqenergy)-settings.Energy;
            fprintf(outfile,'%s %g %s %s\r\n','0',param2,'0','1');
            fprintf(outfile,'%s\r\n','RFQPTQ');
            rfqfilename=devices{id,1}{1,2};
                if ~ispc
                    strrep(rfqfilename,'\','/');
                end
            if exist(rfqfilename,'file')==0
                disperror(['Warning: RFQ file "' rfqfilename '" not found.'],errorflag)
                errorflag=1;
            end
            if ~isfield(settings,card{1,3}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end
            if ~isfield(settings,card{1,4}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,4}],1);
                continue
            end
            rfqdegrees=settings.(card{1,4});
            rfqphaseoffset=100*rfqdegrees/360; % degrees - > percentage
            fprintf(outfile,'%s\r\n',rfqfilename);
            fprintf(outfile,'%s\r\n',devices{id,1}{1,3}); %Number of cells
            fprintf(outfile,'%g %g %g %s\r\n',settings.(card{1,3})-100,...
                settings.(card{1,3})-100,rfqphaseoffset,'180');
            fprintf(outfile,'%s\r\n','REJECT');
            if dynac_version>=15
                rflag=10;
            else
                rflag=0;
            end
            fprintf(outfile,'%g %g %g %g %g %g\r\n', rflag, RFQreject, reject(2),...
                reject(3), reject(4), reject(5));
            fprintf(outfile,'DRIFT\r\n.00001\r\n');
            fprintf(outfile,'%s\r\n','REJECT');
            fprintf(outfile,'%g %g %g %g %g %g\r\n',reject(6), reject(1), reject(2),...
                reject(3), reject(4), reject(5));       
            fprintf(outfile,'%s\r\n','REFCOG');
            fprintf(outfile,'%s\r\n','0');
            unitstruct.(card{1,3})='[%]';
            unitstruct.(card{1,4})='[deg]';
        case 'SCDYNAC' %Space Charge
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            sctype=devices{id,1}{1,2};
            if ~isfield(settings,card{1,3}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end
            if exist('nstates','var') && ~strcmp(sctype,'3')
                disperror(['Error: Space charge modes other than SCHEFF not '...
                    'supported for multi-charge state beam']);
            end
            fprintf(outfile,'%s\r\n','SCDYNAC');
            fprintf(outfile,'%s\r\n',sctype);
            fprintf(outfile,'%g %s\r\n',settings.(card{1,3}),devices{id,1}{1,3});
            switch sctype %Consult Dynac docs for more info
                case '1' %HERSC - Hermite series, default value
                    fprintf(outfile,'%s\r\n',devices{id,1}{1,4});
                case '-1' %HERSC - Hermite series, specified parameters
                    fprintf(outfile,'%s %s %s\r\n',devices{id,1}{1,4},...
                        devices{id,1}{1,5},devices{id,1}{1,6});
                    fprintf(outfile,'%s %s %s\r\n',devices{id,1}{1,7},...
                        devices{id,1}{1,8},devices{id,1}{1,9});
                    fprintf(outfile,'%s\r\n',devices{id,1}{1,10});
                case '2' %SCHERM - Modified Hermite, no parameters
                    fprintf(outfile,'0\r\n');
                case '3' %SCHEFF - LANL potential ring model
                    schefftype=devices{id,1}{1,4};
                    fprintf(outfile,'%s\r\n',schefftype);
                    if schefftype=='1'
                        fprintf(outfile,'%s %s %s %s %s %s %s\r\n',...
                        devices{id,1}{1,5},devices{id,1}{1,6},...
                        devices{id,1}{1,7},devices{id,1}{1,8},...
                        devices{id,1}{1,9},devices{id,1}{1,10},...
                        devices{id,1}{1,11});
                    end
            end
            if mod(bsectors,2)~=0 %make sure number of bsectors is even
                bsectors=bsectors+1;
            end
        case 'SCDYNEL' %Space charge computation in bending magnets
            fprintf(outfile,'%s\r\n','SCDYNEL');
            fprintf(outfile,'%s\r\n',card{1,2});        
        case 'SCPOS' %Space charge position in cavities
            fprintf(outfile,'%s\r\n','SCPOS');
            fprintf(outfile,'%s\r\n',card{1,2});
        case 'SECORD' %Second order computations for elemeents that support them
            fprintf(outfile,'SECORD\r\n');
        case 'SEXTUPO' %Magnetic Sextupole
            %Note: if SECORD is not enabled, will act as a drift
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            if ~isfield(settings,card{1,3}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end
            fprintf(outfile,'%s\r\n','SEXTUPO');
            fprintf(outfile,'1 %g %s %s\r\n',...
                settings.(card{1,3}), devices{id,1}{1,2},...
                devices{id,1}{1,3});
            unitstruct.(card{1,3})='[kG]';            
        case 'SLIT' %Horizontal or vertical slit
            if ~isfield(settings,card{1,2}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,2}],1);
                continue
            end
            if ~isfield(settings,card{1,3}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end
            if length(card) >=4 && isfield(settings,card{1,4}) %Check for X offset
                xoff = settings.(card{1,4});
                unitstruct.card{1,4}='[cm]';
            else
                xoff = 0;
            end
            if length(card) >=5 && isfield(settings,card{1,5}) %Check for Y offset
                yoff = settings.(card{1,5});
                unitstruct.card{1,5}='[cm]';
            else
                yoff = 0;
            end
            fprintf(outfile,'ALINER\r\n');
            fprintf(outfile,'%g %g 0 0\r\n',-xoff,-yoff);
            fprintf(outfile,'%s\r\n','REJECT');
            %factor of /2 is because Dynac uses half widths here
            fprintf(outfile,'%g %g %g %g %g %g\r\n',reject(6), reject(1), reject(2),...
                settings.(card{1,2})/2., settings.(card{1,3})/2., reject(5));
            fprintf(outfile,'DRIFT\r\n.00001\r\n');
            fprintf(outfile,'%s\r\n','REJECT');
            fprintf(outfile,'%g %g %g %g %g %g\r\n',reject(6), reject(1), reject(2),...
                reject(3), reject(4), reject(5));
            fprintf(outfile,'ALINER\r\n');
            fprintf(outfile,'%g %g 0 0\r\n',xoff,yoff);
            xoff = 0;
            yoff = 0;
            unitstruct.(card{1,2})='[cm]';
            unitstruct.(card{1,3})='[cm]';
        case 'SOLENO' %Solenoid
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            if ~isfield(settings,card{1,3}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end            
            fprintf(outfile,'%s\r\n','SOLENO');
            fprintf(outfile,'%s %s %g\r\n','1',devices{id,1}{1,2},...
                settings.(card{1,3}));
            unitstruct.(card{1,3})='[kG]';
        case 'SOQUAD' %Combined magnetic quadrupole and solenoid
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes));
            if ~isfield(settings,card{1,3}) %Check for missing solenoid setting
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end
            if ~isfield(settings,card{1,4}) %Check for missing quad setting
                disperror(['Error: Missing tune setting for ' card{1,4}],1);
                continue
            end
            fprintf(outfile,'%s\r\n','SOQUAD');
            fprintf(outfile,'1 %g 1 %g %s %s\r\n',...
                settings.(card{1,3}), settings.(card{1,4}),...
                devices{id,1}{1,2}, devices{id,1}{1,3});
            unitstruct.(card{1,3})='[kG]';
            unitstruct.(card{1,4})='[kG]';            
        case 'STEER' %Steerer
            %Note that electrostatic steerers are NOT in the official
            %Dynac release as of 4/16/14.
            id=find(strcmp(card{1,2},devicetypes));
            if ~isfield(settings,card{1,3}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end            
            steertype=devices{id,1}{1,2};
            fprintf(outfile,'STEER\r\n');
            if strcmp(steertype,'2')||strcmp(steertype,'3')
                len=str2num(devices{id,1}{1,3});
                gap=str2num(devices{id,1}{1,4});
                voltage=settings.(card{1,3});
                field=voltage*len/gap;
                unitstruct.(card{1,3})='[kV]';
            else
                field=settings.card{1,3};
                unitstruct.(card{1,3})='[kG]';
            end
            fprintf(outfile,'%g %s\r\n',field,steertype);
        case 'STOP' %Break layout here
            %Useful if you want to temporarily comment out part of a
            %beamline
            break
        case 'WRBEAM' %Write beam file
            fprintf(outfile,'%s\r\n','WRBEAM');
            fprintf(outfile,'%s\r\n',card{1,2});
            if dynac_version<=14
                fprintf(outfile,'1 2\r\n');
            else %For Dynac versions >15 write the RP energy
                fprintf(outfile,'1 102\r\n');
            end
        case 'ZONES' %Start tracking RMS zones
            if ~checkdevice(card{1,2},devicetypes); continue; end;
            id=find(strcmp(card{1,2},devicetypes)); %Get zone type
            nzones=length(devices{id,1})-1; 
            ztype=devices{id,1}{1,2};
            fprintf(outfile,'ZONES\r\n');
            if strcmp(ztype,'-1')
                fprintf(outfile,'1 0\r\n');
                fprintf(outfile,'0\r\n');
            else
                fprintf(outfile,'%s %g\r\n',ztype,nzones);
                zonestr='';
                for k=1:(nzones-1)
                    zonestr=[zonestr devices{id,1}{1,2+k} ' '];
                end
                fprintf(outfile,'%s\r\n',zonestr);                
            end
        case 'ZROT' %Rotation
            fprintf(outfile,'%s\r\n','ZROT');
            fprintf(outfile,'%s\r\n',card{1,2});
        case '' %empty string - do nothing
        otherwise
            fprintf(outfile,'%s\r\n',';Error: unrecognized device type');
            disperror(['Error: unrecognized device type ' card{1,1}]);
    end
end
fprintf(outfile,'EMITL\r\nEnd of Line\r\n'); %Always end with an EMITL card
fprintf(outfile,'%s\r\n','STOP');
errorflag=0;

%Store unit list in user data field of edit tune button.
set(guihand.showsettings_button,'UserData',unitstruct);
if isempty(get(guihand.dynac_output_textbox,'String'))
    disperror(['Deck generated successfully at ' datestr(now)],1,'k');
end

fclose all;

function disperror(errortext,varargin)
%Displays errortext in ouput box of DynacGUI window.  If second argument is
%1, append, rather than overrwrite error.
figtag = 'DynacGUI';
guifig = findobj(allchild(0), 'flat','Tag', figtag);
guihand = guidata(guifig);
if (nargin>=1 || varargin{1}==0)
    set(guihand.dynac_output_textbox,'String',errortext);
elseif varargin{1}==1
    errortext=[get(guihand.dynac_output_textbox,'String'); {errortext}];
    set(guihand.dynac_output_textbox,'String',errortext);
end
if (nargin>=2)
    set(guihand.dynac_output_textbox,'ForegroundColor',varargin{2})
end

function clearerror(guihand)
set(guihand.dynac_output_textbox,'String',{});

function cd=checkdevice(deviceid,devicelist)
%checks a device list for the presence of the given device.  Throws an
%error if not found and sets cd = 0

cd=any(ismember(devicelist,deviceid));
if ~cd
    disperror(['Error: Device ' deviceid ' not found in devices file.'],1);
end