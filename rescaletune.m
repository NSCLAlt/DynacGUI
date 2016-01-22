function [settings]=rescaletune(settings,layoutfilename,devicefilename,...
    escale,bscale,cavscale,startline,endline)
% Tune Rescaling Utility for DynacGUI
%
% Reads in a layout file, device type file, and array of settings,
% and rescales the settings based on an E and B scaling factor.  
% Returns the array of settings.
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
%8/25/14 Created with gendeck.m as a starting point.
%10/14/14 Added separate cavity scaling factor
%7/29/15 Can now rescale partial beamlines.
%        Added a bunch of new devices.
%
%To Do: allow scaling for benders with manually set fields.
%To Do: add all the new devices

devicefile=fopen(devicefilename);
i=1;
while ~feof(devicefile)
    line=fgetl(devicefile);
    devices{i,:}=regexp(line,'\t','split');
    i=i+1;
end
devicetypes=cellfun(@(x) x{1},devices,'UniformOutput',false);
fclose(devicefile);

%scan layout file
layoutfile=fopen(layoutfilename);

i=1;
while ~feof(layoutfile)
    if i < startline %If we haven't reached the starting line yet, skip.
        i=i+1;
        continue
    end
    line=fgetl(layoutfile);
    card=regexp(line,'\t','split');
    switch card{1,1}
        case 'BMAGNET' %Bending Magnet
            %Rescale bending magnet.  Note: automatic fields remain
            %automatic. If there is no parameter in the layout file, or it
            %is missing in the tune file, field cannot be scaled.
            if (length(card)>=3) && isfield(settings,card{1,3}) && ~isempty(settings.(card{1,3}))
                %If there is a third parameter, scale the field
                settings.(card{1,3})=settings.(card{1,3})*bscale; 
            end
        case 'BUNCHER' %Buncher
            %Rescale buncher voltage
            settings.(card{1,4})=settings.(card{1,4})*escale;
        case 'CAVNUM' %Accelerating Cavity
            %Rescale cavity voltage
            settings.(card{1,3})=settings.(card{1,3})*cavscale;
        case 'DRIFT' %Drift space
            %Do nothing
        case 'EDFLEC' %Electrostatic Deflector
            %Cannot rescale electrostatic deflectors that do not have a
            %parameter defined, or where the parameter is not present in
            %the tune file.
            if length(card)==2
            %If there is no field parameter name in the layout file, do nothing.
            elseif isfield(settings,(card{1,3})) && ~isempty(settings.(card{1,3}))
                %If the field is present and not empty, scale the efield
                settings.(card{1,3})=settings.(card{1,3})*cavscale;
            end
        case 'EMIT' %Dump beam data to dynac.short
            %Do nothing
        case 'EMITGR' %Emittance Plot
            %Do nothing
        case 'ENVEL' %Envelope Plot
            %Do nothing
        case 'FSOLE' %Solenoid with extenal field
            settings.(card{1,3})=settings.(card{1,3})*bscale;
        case 'NEWF' %New Frequency in Hz
            %Do nothing
        case 'NREF' %New Reference Particle
            %Do nothing
        case 'QUADRUPO' %Magnetic Quadrupole
            %Rescale Quadrupole Field
            settings.(card{1,3})=settings.(card{1,3})*bscale;
        case 'QUADSXT' %Combined magnetic Quad and Sextupole
            settings.(card{1,3})=settings.(card{1,3})*bscale;
            settings.(card{1,4})=settings.(card{1,4})*bscale;
        case 'QUAELEC' %Electrostatic Quad
            %Rescale Electric Quadruple Field
            settings.(card{1,3})=settings.(card{1,3})*escale;
        case 'REJECT' %Reject Card (used for apertures, slits, etc.)
            %Do nothing
        case 'REFCOG'
            %Do nothing
        case 'RFKICK'
            %Rescale kicker voltage
            settings.(card{1,4})=settings.(card{1,4})*escale;
        case 'RFQPTQ' %RFQ
            %Rescale RFQ voltage
            settings.(card{1,3})=settings.(card{1,3})*escale;
        case 'SCDYNAC' %Space Charge
            %Do nothing
        case 'SCDYNEL' %Space charge computation in bending magnets
            %Do nothing        
        case 'SCPOS' %Space charge position in cavities
            %Do nothing
        case 'SEXTUPO' %Magnetic Sextupole
            settings.(card{1,3})=settings.(card{1,3})*bscale;
        case 'SLIT' %Horizontal or vertical slit
            %Do nothing
        case 'SOLENO' %Solenoid
            %Rescale Solenoid field
            settings.(card{1,3})=settings.(card{1,3})*bscale;
        case 'SOQUAD' %Combined magnetic solenoid and quadrupole
            settings.(card{1,3})=settings.(card{1,3})*bscale;
            settings.(card{1,4})=settings.(card{1,4})*bscale;
        case 'STEER' %Steerer            
            %Note that electrostatic steerers are NOT in the official
            %Dynac release as of 4/16/14.
            id=find(strcmp(card{1,2},devicetypes));
            steertype=devices{id,1}{1,2};
            if strcmp(steertype,'2')||strcmp(steertype,'3') %Electrostatic
                settings.(card{1,3})=settings.(card{1.3})*escale;
            else %Magnetic
                settings.card{1,3}=settings.(card{1,3})*bscale;
            end
        case 'WRBEAM' %Write beam file
            %Do nothing
        case 'ZROT' %Rotation
            %Do nothing
        case '' %empty string - do nothing
        otherwise
            %Other device type - do nothing.  Will this cause problems?
            %disperror(['Error: unrecognized device type ' card{1,1}]);
    end
    i=i+1;
    if i==endline+1 %if we are now past the ending line, quit.
        break;
    end
end

fclose all;

function disperror(errortext)
figtag = 'DynacGUI';
guifig = findobj(allchild(0), 'flat','Tag', figtag);
guihand = guidata(guifig);
set(guihand.dynac_output_textbox,'String',errortext);

