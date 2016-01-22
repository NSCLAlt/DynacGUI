function loadcs(hObject,~)
% Dynac GUI Module to load parameters from a Control System saveset.
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
%   4/10/15 - Initial release.  Much to do.
%   4/13/15 - Cosmetic fixes. Error checking. Success message.

%To do - throw messages for settings not in control system file.

dghandles=guidata(hObject); %Retrieve DynacGUI handles
%Retrieve default values from .ini file.
if isfield(dghandles.inivals,'Calfile')
    calfile=dghandles.inivals.Calfile;
end
if isfield(dghandles.inivals,'CSsetdir')
    setdir=dghandles.inivals.CSsetdir;
else
    setdir='';
end

%Draw the window
scrsz = get(0,'ScreenSize');
figheight = 230;
figwidth = 700;
loadcsfigure=figure('Name','Load Control System Parameters','NumberTitle','Off',...
    'Units','pixels','Position',[100 scrsz(4)-100-figheight figwidth figheight],...
    'MenuBar','none','Color',[.9412 .9412 .9412]);

handles=guidata(loadcsfigure); %set up local handles
handles.settings=dghandles.settings; %Put settings into local handles structure
handles.dg=hObject; %Set a pointer in the local handles back to the DG window

%Draw everything IN the window
uicontrol(loadcsfigure,'Style','Text','String','Load Control System Settings',...
    'FontSize',14,'Position',[0 figheight-45 figwidth 40]);
handles.csfile_inputbox=uicontrol(loadcsfigure,'Style','edit',...
    'Position',[140 figheight-80 550 30],'BackgroundColor','white',...
    'HorizontalAlignment','Left');
uicontrol(loadcsfigure,'Style','Pushbutton','String','CS Setings File',...
    'Position',[20 figheight-80 100 30],'Callback',{@getfile,handles.csfile_inputbox,setdir});
handles.calfile_inputbox=uicontrol(loadcsfigure,'Style','edit',...
    'Position',[140 figheight-120 550 30],...
    'BackgroundColor','white','String',calfile,...
    'HorizontalAlignment','Left');
uicontrol(loadcsfigure,'Style','Pushbutton','String','Calibration File',...
    'Position',[20 figheight-120 100 30],'Callback',{@getfile,handles.calfile_inputbox});
uicontrol(loadcsfigure,'Style','Pushbutton','String','Load Settings',...
    'Position',[figwidth/2-50 figheight-170 100 30],...
    'Callback',{@loadsettings});
handles.error_textbox=uicontrol(loadcsfigure,'Style','text',...
    'Position',[10 figheight-210 figwidth-20 30],'HorizontalAlignment','Left');

guidata(loadcsfigure,handles); %Update the GUI handles



function loadsettings(hObject,~)
%Load the information from a CS file into the settings array for DynacGUI.

handles=guidata(hObject); %Retrieve the handles for the loadcs panel
dghandles=guidata(handles.dg); %Retrieve the pointer to the DynacGUI handles

%Load calibration settings from file.
calfile=get(handles.calfile_inputbox,'String');

cf=fopen(calfile);

if cf==-1
    disperror(hObject,'Calibration File Not Found - settings imported unchanged.');
    calstruct=([]);
elseif ~cf==0
    i=1;
    while ~feof(cf)
        newline=fgetl(cf);
        if ~isempty(regexp(newline,'^;','once')) || isempty(regexp(newline,'\S','once'))
            continue; %Comment or completely blank lines get ignored.
        else
            caldata{i,1}=regexp(newline,'\s+|\t+','split'); 
            if length(caldata{i,1})<3
                caldata{i,1}{1,3}='0';
            end
            i=i+1;
        end
    end
    fclose(cf);
    %Convert calibration settings to a structure - calstruct
    fnames=cellfun(@(v) v(1),caldata(:,1));
    fieldvalues=cellfun(@(v) {v{2},v{3}},caldata(:,1),'UniformOutput',0);
    calstruct=cell2struct(fieldvalues,fnames,1);
    calstruct=structfun(@(x) str2double(x),calstruct,'UniformOutput',0);
end
     
%Load parameters from control system file
csfilename=get(handles.csfile_inputbox,'String');

csfile=fopen(csfilename);

if csfile==-1
    disperror(hObject,'Error: Unable to open settings file');
    return
end
if isfield(dghandles.inivals,'CSsetcol') %Set column of settings file to read
    setcol=str2double(dghandles.inivals.CSsetcol);
else
    setcol=5; %Default is 5.
end

newline=fgetl(csfile);
%Only good for CS Studio files
%while isempty(regexp(newline,'----','once'))
%    newline=fgetl(csfile);
%end

i=1;
while ~feof(csfile)
    newline=fgetl(csfile);
    if regexp(newline,'^(--|#|;)')
        continue;
    else
        csdata{i,1}=regexp(newline,'\s+','split'); 
        i=i+1;
    end
end
fclose(csfile);

%Convert CS data to a structure - csstruct
fnames=cellfun(@(v) v(1),csdata(:,1));
fieldvalues=cellfun(@(v) v(setcol),csdata(:,1));
fnames=strrep(fnames,'.',''); %Strip periods from channel names.
fnames=strrep(fnames,':',''); %Strip colons from channel names.
fnames=strrep(fnames,'-',''); %Strip hyphens from channel names.
csstruct=cell2struct(fieldvalues,fnames,1);
csstruct=structfun(@(x) str2double(x),csstruct,'UniformOutput',0);

%Load tune settings into a structure
settings=handles.settings;

%Now you have three structures - caldata with the calibration data,
%csstruct with the control system data, and settings with the initial
%simulation settings.

%If the value is in both the settings file and the control system data,
%load it. If it is also in the calibration data, calibrate it.

%Find the values in both the control system and settings file.
scmatches=intersect(fieldnames(csstruct),fieldnames(settings));

if isempty(scmatches)
    disperror(hObject,'No matching parameters found in CS file.');
    return
end

for eachfield=1:length(scmatches)
    if isfield(calstruct,(scmatches{eachfield})) 
        %If the field is present in the calibration file, multiply by the
        %first number and add the second.  This can be used to manually set
        %values by setting the first value to 0.
        settings.(scmatches{eachfield})=...
            calstruct.(scmatches{eachfield})(1)*csstruct.(scmatches{eachfield})+...
            calstruct.(scmatches{eachfield})(2);
    else %Import without alteration - this should eventually get a warning
        settings.(scmatches{eachfield})=csstruct.(scmatches{eachfield});
    end
end

%Update the original DynacGUI settings field
dghandles.settings=settings;
set(dghandles.gendeck_checkbox,'Value',0.0);
set(dghandles.viewdeck_button,'Enable','off');
set(dghandles.rundeck_checkbox,'Value',0);
set(dghandles.longdist_checkbox,'Value',0.0);
guidata(handles.dg,dghandles);
disperror(hObject,['Loaded settings from ' csfilename '.']);


function getfile(~,~,filebox,varargin)
%Select file from which to load parameters
temp=get(filebox,'String');
if nargin==4
    default=([varargin{1} filesep '*.*']);
else
    default='*.*';
end
[filename,filepath,~]=uigetfile(default);
fullname=[filepath filename];
if isequal(filename,0) %If user cancels out of selection
    fullname=temp;
end
set(filebox,'String',fullname);

function disperror(hObject,errortext)
handles=guidata(hObject);
set(handles.error_textbox,'String',errortext);


