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

%-----Default Parameters----% (Move to .ini file eventually)
RFQreject=.5; %Fractional deviation from average energy to be rejected after RFQ. Note
              %that this is from the average INCLUDING the unaccelerated
              %beam. 
esectors=10; %Number of sectors for electrostatic bending elements
bsectors=10; %Number of sectors for magnetic bending elements
%Default REJECT values
%Energy[MeV] Phase[deg] X[cm] Y[cm] R[cm] - All are 1/2 widths
reject=[1000 4000 100 100 400];

%Define DynacGUI Window, get handles
figtag = 'DynacGUI';
guifig = findobj(allchild(0),'flat','Tag',figtag);
guihand = guidata(guifig);

%Adjust parameters from .ini file
if isfield(guihand.inivals,'RFQreject')
    RFQreject=guihand.inivals.RFQreject;
end
if isfield(guihand.inivals,'Esectors')
    esectors=guihand.inivals.Esectors;
end
if isfield(guihand.inivals,'Bsectors')
    bsectors=guihand.inivals.Bsectors;
end

clearerror(guihand);
runfreq=settings.RF; %Initial Frequency of line
edflectype=checkedflec(guihand); %which version of electrostatic deflector to use
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
    if settings.ZLaw==5 && ~isfield(settings,'Deltae')
        disperror('Error: Law 5 selected with no energy spread specified');
        return;
    end
    if settings.ZLaw<=4
        if ~isfield(settings,'Alphaz') || ~isfield (settings,'Betaz') ||...
            ~isfield(settings,'Epsz')
            disperror('Error: Insufficient Z Twiss Parameters Specified');
            return;
        end
    end
    fprintf(outfile,';%s\r\n',outputfilename); %Beamline Name
    fprintf(outfile,'%s\r\n','GEBEAM');
    fprintf(outfile,'%g %s\r\n',settings.ZLaw,'1'); %Distribution Type
    fprintf(outfile,'%g\r\n',settings.RF); %RF frequency
    fprintf(outfile,'%g\r\n',settings.Npart); %Number of particles
    fprintf(outfile,'%g %g %g %g %g %g\r\n',0,0,0,0,0,0); % Starting offset
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
        case 'BMAGNET' %Bending Magnet
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
            id=find(strcmp(card{1,2},devicetypes));
            %Checks to see if this is a new cavity field type. If it is,
            %issue a FIELD command with the filename.
            if ~strcmp(cavfield,devices{id,1}{1,2})
                cavfield=devices{id,1}{1,2};
                if exist(cavfield,'file')==0 %Throw an error if cavity field not present
                    disperror(['Warning: Cavity file ' cavfield ' not found.'],errorflag)
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
            fprintf(outfile,'%s %g %g %s %s\r\n','0',settings.(card{1,4}),...
                settings.(card{1,3})-100,'8','1');
            unitstruct.(card{1,3})='[%]';
            unitstruct.(card{1,4})='[deg]';
        case 'DRIFT' %Drift space
            fprintf(outfile,'%s\r\n','DRIFT');
            fprintf(outfile,'%s\r\n',card{1,2});
        case 'EDFLEC' %Electrostatic Deflector
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
            id=find(strcmp(card{1,2},devicetypes));
            fprintf(outfile,'%s\r\n','ENVEL');
            fprintf(outfile,'%s\r\n',card{1,3});
            fprintf(outfile,'%s\r\n',devices{id,1}{1,2});
            fprintf(outfile,'%s %s\r\n',devices{id,1}{1,3},...
                devices{id,1}{1,4});
            fprintf(outfile,'%s %s %s %s\r\n','0','0','0','0');
            freqlist=[freqlist runfreq];
            i=i+1;
        case 'NEWF' %New Frequency in Hz
            fprintf(outfile,'%s\r\n','NEWF');
            fprintf(outfile,'%s\r\n',card{1,2});
            runfreq=str2double(card{1,2});
        case 'NREF' %New Reference Particle
            fprintf(outfile,'%s\r\n','NREF');
            fprintf(outfile,'%s %s %s %s\r\n',card{1,2},card{1,3},...
                card{1,4},card{1,5});
        case 'QUADRUPO' %Magnetic Quadrupole
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
        case 'QUAELEC' %Electrostatic Quad
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
            id=find(strcmp(card{1,2},devicetypes));
            fprintf(outfile,'%s\r\n','REJECT');
            fprintf(outfile,'1 %s %s %s %s %s\r\n',devices{id,1}{1,2},...
                devices{id,1}{1,3}, devices{id,1}{1,4},...
                devices{id,1}{1,5},devices{id,1}{1,6});
            reject=[str2double(devices{id,1}{1,2}),...
                str2double(devices{id,1}{1,3}),...
                str2double(devices{id,1}{1,4}),...
                str2double(devices{id,1}{1,5}),...
                str2double(devices{id,1}{1,6})];
        case 'REFCOG'
            fprintf(outfile,'%s\r\n','REFCOG');
            fprintf(outfile,'%s\r\n',card{1,2});
        case 'RFKICK'
            %Note that rf kickers are NOT in the official
            %Dynac release as of 4/20/14.
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
                disperror(['Warning: RFQ file ' rfqfilename ' not found.'],errorflag)
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
            fprintf(outfile,'%s\r\n',rfqfilename);
            fprintf(outfile,'%s\r\n',devices{id,1}{1,3});
            fprintf(outfile,'%g %g %g %s\r\n',settings.(card{1,3})-100,...
                settings.(card{1,3})-100,settings.(card{1,4}),'180');
            fprintf(outfile,'%s\r\n','REJECT');
            fprintf(outfile,'0 %g %g %g %g %g\r\n', RFQreject, reject(2),...
                reject(3), reject(4), reject(5));
            fprintf(outfile,'DRIFT\r\n.00001\r\n');
            fprintf(outfile,'%s\r\n','REJECT');
            fprintf(outfile,'1 %g %g %g %g %g\r\n',reject(1), reject(2),...
                reject(3), reject(4), reject(5));       
            fprintf(outfile,'%s\r\n','REFCOG');
            fprintf(outfile,'%s\r\n','0');
            unitstruct.(card{1,3})='[%]';
            unitstruct.(card{1,4})='[deg]';
        case 'SCDYNAC' %Space Charge
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
        case 'SLIT' %Horizontal or vertical slit
            if ~isfield(settings,card{1,2}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,2}],1);
                continue
            end
            if ~isfield(settings,card{1,3}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end            
            fprintf(outfile,'%s\r\n','REJECT');
            %factor of /2 is because Dynac uses half widths here
            fprintf(outfile,'1 %g %g %g %g %g\r\n',reject(1), reject(2),...
                settings.(card{1,2})/2., settings.(card{1,3})/2., reject(5));
            fprintf(outfile,'DRIFT\r\n.00001\r\n');
            fprintf(outfile,'%s\r\n','REJECT');
            fprintf(outfile,'1 %g %g %g %g %g\r\n',reject(1), reject(2),...
                reject(3), reject(4), reject(5));
            unitstruct.(card{1,2})='[cm]';
            unitstruct.(card{1,3})='[cm]';
        case 'SOLENO' %Solenoid
            id=find(strcmp(card{1,2},devicetypes));
            if ~isfield(settings,card{1,3}) %Check for missing settings
                disperror(['Error: Missing tune setting for ' card{1,3}],1);
                continue
            end            
            fprintf(outfile,'%s\r\n','SOLENO');
            fprintf(outfile,'%s %s %g\r\n','1',devices{id,1}{1,2},...
                settings.(card{1,3}));
            unitstruct.(card{1,3})='[kG]';
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
            fprintf(outfile,'%s\r\n','EMIT'); %Always end with an EMIT card
            fprintf(outfile,'%s\r\n','STOP');
            fclose all;
            return
        case 'WRBEAM' %Write beam file
            fprintf(outfile,'%s\r\n','WRBEAM');
            fprintf(outfile,'%s\r\n',card{1,2});
            fprintf(outfile,'%s %s\r\n','1','2');
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
    disperror(['Deck generated successfully at ' datestr(now)]);
end

fclose all;

function disperror(errortext,varargin)
%Displays errortext in ouput box of DynacGUI window.  If second argument is
%1, append, rather than overrwrite error.
figtag = 'DynacGUI';
guifig = findobj(allchild(0), 'flat','Tag', figtag);
guihand = guidata(guifig);
if (nargin==1 || varargin{1}==0)
    set(guihand.dynac_output_textbox,'String',errortext);
elseif varargin{1}==1
    errortext=[get(guihand.dynac_output_textbox,'String'); {errortext}];
    set(guihand.dynac_output_textbox,'String',errortext);
end

function clearerror(guihand)
set(guihand.dynac_output_textbox,'String',{});

function out=checkedflec(guihand)
if isfield(guihand.inivals,'Edflec')
    out=str2num(guihand.inivals.Edflec);
else
    out=4;
end

