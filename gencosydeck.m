function [settings,freqlist]=gencosydeck(hObject, ~,varargin)
% COSY Deck Generator for DynacGUI
% Reads in a layout file, device type file, and array of settings,
% and outputs a (hopefully) properly formatted COSY deck.
%
%  COSY is copyright by Berz and Makino, and is not maintained or supported
%   by the author of DynacGUI.
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
%Update Log
% 8/22/14 - Basic version ready
% 9/19/14 - Now uses variables for fields to allow easy addition of
% fitting.

%EDIT THESE PARAMETERS FOR YOUR NEEDS
cosyinclude='COSY8a_9'; %The name of the .bin file with the COSY beam libraries
order=1;                %Order to which calculations are to be carried
                        %Move into .ini file eventually
defaultaperture=.03;    %Default aperture radius in m
%STOP EDITING HERE (Unless you don't want to)

handles=guidata(hObject);
outputfilename=get(handles.outputdeck_inputbox,'String');
settings=handles.settings;
layoutfilename=get(handles.layoutfile_inputbox,'String');
devicefilename=get(handles.devicefile_inputbox,'String');

runfreq=settings.RF; %Initial Frequency of line
freqlist=[];
temp=strrep(outputfilename,'.in','_COSY.fox'); %COSY deck name
[outputfilename,outputfilepath,~]=uiputfile('*.*','Name Saved COSY File',temp);
if isequal(outputfilename,0) %If "cancel" is selected, do not generate deck
    return
end

devicefile=fopen(devicefilename);
i=1;
while ~feof(devicefile)
    line=fgetl(devicefile);
    devices{i,:}=regexp(line,'\t','split');
    i=i+1;
end
devicetypes=cellfun(@(x) x{1},devices,'UniformOutput',false);
fclose(devicefile);

%Open output file for writing
%outfile=fopen('beamline.in','w');
outfilename=fullfile(outputfilepath,outputfilename);
outfile=fopen(outfilename,'w');

%scan layout file
layoutfile=fopen(layoutfilename);
cavfield='';

%Write header information
if ~isfield(settings,'ZLaw')
    settings.ZLaw=5;
end
if settings.ZLaw==5 && ~isfield(settings,'Deltae')
    disperror('Error: Law 5 selected with no energy spread specified');
    return;
end
if settings.ZLaw<=4
    if ~isfield(settings,'Alphaz') || ~isfield (settings,'Betaz') ||...
        ~isfield(settings,'Epsz')
        disperror('Error: Insufficient Z Twiss Parameters Specified');
        return
    end
end

fprintf(outfile,'OV %g 3 0;\r\n',order); 
fprintf(outfile,'RP %g %g %g ;\r\n',settings.Energy,settings.A,...
    settings.Q);

% Use input twiss parameters to set initial rays, as per Portillo
px = sqrt(settings.Betax*settings.Epsx)*.001; %x half width (m)
py = sqrt(settings.Betay*settings.Epsy)*.001; %y half width (m)

gammax = (settings.Alphax^2+1)/settings.Betax; %(rad/m)
gammay = (settings.Alphay^2+1)/settings.Betay; %(rad/m)

pxp = sqrt(gammax*settings.Epsx)*.001; %xp half width (rad)
pyp = sqrt(gammay*settings.Epsy)*.001; %yp half width (rad)

r12 = -settings.Alphax/sqrt(settings.Betax/gammax);
r34 = -settings.Alphay/sqrt(settings.Betay/gammay);

%Energy Parameters
if settings.ZLaw==5
    %Energy width, dummy(x2)
    gammaz = settings.Energy/931.49432+1; %relativistic gamma
    betaz = sqrt(gammaz^2-1)/gammaz;
    lambda = 2.998e10 / settings.RF; %lambda (cm)
    ptime =  betaz*lambda/2; %z half width (cm)
    penergy = .5*settings.Deltae/settings.Energy; %energy half width (dk/k) 
    r56=0;
else
    %Z Twiss Parameters
    ptime=sqrt(settings.Betaz*settings.Epsz);
    gammaz=(settings.Alphaz^2+1)/settings.Betaz; %CS geometric gamma
    penergy = (gammaz*settings.Epsz); %energy half width (keV)
    r56 = -settings.Alphaz/sqrt(settings.Betaz*gammaz);
end
fprintf(outfile,'SB %g %g %g %g %g %g %g %g %g 0 0;\r\n',...
    px, pxp, r12, py, pyp, r34, ptime, penergy, r56);
fprintf(outfile,'UM; CR;\r\n');
fprintf(outfile,'ER 1 3 1 3 1 1 1 1;\r\n');
fprintf(outfile,'BP;\r\n');

%Default REJECT values
%Energy[MeV] Phase[deg] X[cm] Y[cm] R[cm] - All are 1/2 widths
reject=[1000 4000 100 100 400];
variablenames={};
variablevalues={};
runningenergy=settings.Energy;

i=1; %Counts the number of plots
while ~feof(layoutfile)
    line=fgetl(layoutfile);
    card=regexp(line,'\t','split');
    switch card{1,1}
        case 'BMAGNET' %Bending Magnet
            id=find(strcmp(card{1,2},devicetypes));
            bradius=str2num(devices{id,1}{1,3})*.01; %cm -> m
            bangle=devices{id,1}{1,2};
            apertin=str2num(devices{id,1}{1,6})*.01; % cm -> m
            apertout=str2num(devices{id,1}{1,9})*.01; % cm -> m
            apert=(apertin+apertout)/2; %average of entry & exit apertures
            anglein=devices{id,1}{1,4};
            angleout=devices{id,1}{1,7};
            if apert==0
                apert=defaultaperture; %If no aperture specified, use default
                fprintf(outfile,'{No aperture specified: using default}\r\n');
            end
            if str2num(devices{id,1}{1,5})~=0
                curvein=1/(str2num(devices{id,1}{1,5})*.01); % cm -> 1/m
            else
                curvein=0;
            end
            if str2num(devices{id,1}{1,8})~=0
                curveout=1/(str2num(devices{id,1}{1,8})*.01); %cm -> 1/m
            else
                curveout=0;
            end
            fprintf(outfile,'DI %g %s %g %s %g %s %g;\r\n',...
                bradius,bangle,apert,anglein, curvein, angleout, curveout);
        case 'BUNCHER' %Buncher
            fprintf(outfile,'{Buncher in layout not supported by COSY}\r\n');
        case 'CAVNUM' %Accelerating Cavity
            fprintf(outfile,'{Accelerating cavities not properly supported by COSY}\r\n');
        case 'DRIFT' %Drift space
            fprintf(outfile,'DL %g;\r\n',str2double(card{1,2})*.01); % cm -> m
        case 'EDFLEC' %Electrostatic Deflector
            id=find(strcmp(card{1,2},devicetypes));
            bradius=str2num(devices{id,1}{1,2})*.01; % cm -> m
            bangle=str2num(devices{id,1}{1,3})*.01; %cm -> m
            fprintf(outfile,'{Electrostatic deflector assumed cylindrical}\r\n');
            fprintf(outfile,'{ - defualt aperture used}\r\n');
            fprintf(outfile,'ES %g %g %g 1 -1 1 -1 1;\r\n',...
                bradius, bangle, defaultaperture);
        case 'EMIT' %Dump beam data to dynac.short
            fprintf(outfile,'{EMIT}\r\n');
        case 'EMITGR' %Emittance Plot
            fprintf(outfile,'{EMITGR}\r\n');
            freqlist=[freqlist runfreq];
            i=i+1;
        case 'ENVEL' %Envelope Plot
            fprintf(outfile,'{ENVEL}\r\n');
                freqlist=[freqlist runfreq];
                i=i+1;
        case 'NEWF' %New Frequency in Hz
            fprintf(outfile,'{NEWF}\r\n');
            runfreq=str2double(card{1,2});
        case 'NREF' %New Reference Particle
            flag=card{1,5}; % 0 = %, 1 = delta MeV, 2 = abs MeV
            if strcmp(flag,'2')
                runningenergy=str2num(card{1,3});
            elseif strcmp(flag,'0')
                runningenergy=str2num(card{1,3})*runningenergy;
            else strcmp(flag,'1')
                runningenergy=str2num(card{1,3})+runningenergy;
            end                     
            fprintf(outfile,'RP %g %s %s;\r\n',runningenergy, settings.A,...
                settings.Q);
        case 'QUADRUPO' %Magnetic Quadrupole
            id=find(strcmp(card{1,2},devicetypes));
            length=str2num(devices{id,1}{1,2})*.01; % cm -> m
            aradius=str2num(devices{id,1}{1,3})*.01; % cm -> m
            bfield=settings.(card{1,3})*0.1; % kG -> T
            fprintf(outfile,'MQ %g %s %g;\r\n',length, card{1,3}, aradius);
            variablenames=[variablenames card{1,3}];
            variablevalues=[variablevalues bfield];
        case 'QUAELEC' %Electrostatic Quad
            id=find(strcmp(card{1,2},devicetypes));
            length=str2num(devices{id,1}{1,2})*.01; % cm -> m
            aradius=str2num(devices{id,1}{1,3})*.01; % cm -> m
            fprintf(outfile,'EQ %g %s %g;\r\n',length,...
                card{1,3},aradius);
            variablenames=[variablenames card{1,3}];
            variablevalues=[variablevalues settings.(card{1,3})];
        case 'REJECT' %Reject Card (used for apertures, slits, etc.)
            id=find(strcmp(card{1,2},devicetypes));
            fprintf(outfile,'{REJECT}\r\n');
            reject=[str2double(devices{id,1}{1,2}),...
                str2double(devices{id,1}{1,3}),...
                str2double(devices{id,1}{1,4}),...
                str2double(devices{id,1}{1,5}),...
                str2double(devices{id,1}{1,6})];
        case 'REFCOG'
            fprintf(outfile,'%s\r\n','{REFCOG}');
        case 'RFKICK'
            fprintf(outfile,'{RF Kickers not supported by COSY}\r\n');
        case 'RFQPTQ' %RFQ
            fprintf(outfile,'{RFQ not supported by COSY}\r\n');
        case 'SCDYNAC' %Space Charge
            fprintf(outfile,'{Space charge not supported by COSY}\r\n');
        case 'SCDYNEL' %Space charge computation in bending magnets
            fprintf(outfile,'{Space charge not supported by COSY}\r\n');        
        case 'SCPOS' %Space charge position in cavities
            fprintf(outfile,'{Space charge not supported by COSY}\r\n'); 
        case 'SLIT' %Horizontal or vertical slit
            fprintf(outfile,'%s\r\n','{SLIT: Cosy does not track particles}');
        case 'SOLENO' %Solenoid
            id=find(strcmp(card{1,2},devicetypes));
            length=str2num(devices{id,1}{1,2})*.01; % cm -> m
            bfield=settings.(card{1,3})*.1; %kG -> T
            fprintf(outfile,'{Note: Default aperture used for Solenoid}\r\n');
            fprintf(outfile,'CMS %s %g %g;\r\n',card{1,3}, defaultaperture, length);
            variablenames=[variablenames card{1,3}];
            variablevalues=[variablevalues bfield];
        case 'STEER' %Steerer
            fprintf(outfile,'{Steerer not supported by COSY}\r\n');
        case 'WRBEAM' %Write beam file
            fprintf(outfile,'%s\r\n','{WRBEAM}');
        case 'ZROT' %Rotation
            fprintf(outfile,'RA %g;\r\n',-str2num(card{1,2}));
        case '' %empty string - do nothing
        otherwise
            fprintf(outfile,'{Unrecognized device type: %s}\r\n',card{1,1});
            disperror(['Error: unrecognized device type ' card{1,1}]);
    end
end
fprintf(outfile,'EP;\r\n');
fprintf(outfile,'PG -1 -2;\r\n');
fprintf(outfile,'ENDPROCEDURE;\r\n');
fprintf(outfile,'RUN;END;\r\n');
fclose all;

header=sprintf('INCLUDE ''%s'';\r\n',cosyinclude);
header=[header sprintf('{Generated from DynacGUI}\r\n')];
header=[header sprintf('PROCEDURE RUN;\r\n')];
header=[header...
    sprintf('VARIABLE %s 1; VARIABLE %s 1; VARIABLE %s 1; VARIABLE %s 1;\r\n',...
    variablenames{1,:})];
header=regexprep(header,'VARIABLE $','\r\n');
combined=[variablenames;variablevalues];
header=[header sprintf('%s := %g;\r\n',combined{:})];


dlmwrite(outfilename,[header fileread(outfilename)],'delimiter','');



function disperror(errortext)
figtag = 'DynacGUI';
guifig = findobj(allchild(0), 'flat','Tag', figtag);
guihand = guidata(guifig);
set(guihand.dynac_output_textbox,'String',errortext);

