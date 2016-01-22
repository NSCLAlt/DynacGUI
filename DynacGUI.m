function varargout = DynacGUI(varargin)
% DynacGUI MATLAB code for DynacGUI.fig
%
%   DynacGUI is a graphical frontend to the beam dynamics code Dynac.  It
%   allows for simplified creation of Dynac input decks, on-the-fly tune
%   adjustment, results viewing, and other features.  It is still a work in
%   progress, and is not guaranteed to function properly at any time.
%
%   For more information on DynacGUI, contact Daniel Alt (alt@nscl.msu.edu).
%
%   Dynac itself is by Tanke, Valero, and LaPostolle, available from:
%       http://dynac.web.cern.ch.
%
%   
%
%  This software is Copyright by the Board of Trustees of Michigan
%  State University (c) Copyright 2015.
%  
%   Contact Information:
%    Daniel Alt (alt@nscl.msu.edu)
%    Facility for Rare Isotope Beams
%    Michigan State University
%    East Lansing, MI 48824-1321
%    http://frib.msu.edu
%  
%  


% Edit the above text to modify the response to help figure1

%   UPDATE LOG:
%
%Version 1.6 - Added ability to display beta functions 10/30/13
%Version 1.6a - Added ability to add offset to plot of box locations 11/5/13
%Version 1.6b - Added REFCOG and NREF functions
%Version 1.6c - Changed RFQ model to force correct reference energy
%Version 1.6d - Fixed a small bug in the location of box L044
%             - Modified emitplot to produce histograms in dt/dE
%             - Now sends handles.settings to emitplot
%Version 1.6e - Minor bugfixes
%             - Added dotted zero line to z-axis plot
%Version 1.7 - Added ability to save tune files. Cue unintended
%               consequences
%Version 2.0 - Added ability to transport distributions longer than one
%               RFQ period
%Version 2.1 - Added .ini file for initial settings 7/2/14
%            - Added code so nothing breaks if you try to run DynacGUI
%              while it's already open. 7/2/14
%            - Ability to start with arbitary particle distribution.7/7/14
%Version 2.1a- Corrected typo in default executable. 7/10/14
%Version 2.2 - Added "View Deck" and "Clear Output" buttons 7/29/14
%Version 2.3 - Added error checking for blank lines in tune files
%Version 2.4 - Space charge added to gendeck.m
%               Fixed "Plot All" button, which has apparently been broken
%                for months. 7/31/14
%Version 2.4a - Fixed bug when attempting to edit tune settings without
%               an energy spread in the tune file
%Version 2.4b - Added disperror function to send errors to output box.
%             - Reconfigured envelope plot
%Version 2.5  - Added ability to generate a COSY deck for a limited subset
%                   of Dynac cards.
%Version 2.6  - Added ability to generate rescaled tunes by Q/A.  Note that
%               there is no allowance for energy changing along the line.
%Version 2.6a - Added names of plots to ud structure.  Turns out not to be
%               useful right now, but will leave in, in case it's useful
%               later.
%             - Added z locations of plots to ud structure.
%Version 2.6b - Changes to tau>RFQ routine to accomodate changes in Dynac.
%                   9/17/14
%Version 2.6c - Will now show locations of all emittance plots on energy /
%                   envelope graph. - 9/18/14
%Version 2.6d - Doesn't throw an error if you try to generate an envelope
%                   plot before running a deck. - 9/24/14
%             - "Particles Left at End" is now a fraction - 10/8/14
%             - Can now comment lines in tune settings files with ";"
%Version 2.6e - Fixed "Rescale Tune" routine for (hopefully) correct
%               magnetic and cavity scaling factors.
%Version 2.7  - Added ability to save result files
%Version 3.0  - Added results viewer to view saved files. - 10/23/14
%             - Added graphic display of element locations to Z plot -
%             10/24/14
%             - Various bug fixes and error catching
%             2/19/15
%             - Changed element location lines to black. (whoop de doo)
%Version 3.1  - Removed ReA hard coded box positions by default, but left
%               them as an option which can be selected in the .ini file.
%               2/19/15
%             - Disabled "Import ReA3 Tune" button by default, added as 
%               selectable option in .ini file. - 3/5/15
%             - Disable "Envelope / Energy Plots" button until a deck is
%             run.
%Version 4.0  - Modified 'gendeck' and this file to add units to tune edit
%             window.  Still needs some work. 3/10/15
%             - Modifications to account for changes in Dynac r13
%             - Fitting tool added
%             - Added Files menu to quickly open dynac files.
%             - Units display in "modify settings" box is now much more
%             robust - 3/16/15
%             - Saving a tune now changes the output deck name.
%             - More robust error handling when Dynac terminates for <10
%             particles - 3/19/15
%             - Added an option for a third executable
%             - Cleaned up "Edit Tune Settings" Box.
%             - Added an option to the .ini file to account for changes to
%             EDFLEC in r13. - 4/6/15
%             - Fixed broken check for missing .ini file.
%             - loadcs.m module added for importing control system data.
%Version 4.1 - Vitally important semicolon. Oh, fine. Tiny OCD semicolon. 4/20/15
%            - Added current output deck to view files menu 4/29/15
%            - Made cavity scaling factor visible in rescale tune box
%            4/30/15
%            - Added X, Y, time, and delta E / E envelopes to z-axis plots.
%            (Thanks, Eugene!) - 5/1/15
%            - Made plot type list in Z axis box dynamic depending on Dynac
%            version
%            - Added 'DynacGUI' to view files menu.
%            - Added x, y envelopes to x, y dispersion plots.
%Version 4.2 - Made "Edit Tune" window non resizable.
%            - Fixed a bug if you run without the Optimization Toolbox
%            available
%            - Fixed a bug which arose if no emittance plots were defined
%            - Added support for zone plots
%            - Will ignore duplicate plot names rather than crashing
%            - Forced text editor calls into the background, which was
%            causing issues.
%Version 4.3 - Changed profile plot axis label to "half width".
%            - Made some tweaks to the envelope plots - added RMS line.
%            - Modified rescale utility to allow for scaling of partial
%            lines
%            - Rescale Tune button now refreshes settings window if open.
%            - Refuse to open a second settings window if one is already
%            open - 8/10/15
%            - Refresh the "tune settings" window if a new tune file is
%            loaded. - 8/10/15
%            - Quadrupole markers on z plots now offset depending on sign -
%            10/21/15
%            - Added .dst file viewer - 10/26/15 (in progress)
%            - Added DynacVersion variable to .ini file, replaced Edflec
%            check with generalized version check. 11/3/15
%            - Modified *.dst viewer to use RP enegy as reference if it is
%            included in the .dst file. 11/3/15
%            - "Statistics too low" message now displays in red, and
%            changes plot list to red to warn that plots are outdated.
%            11/13/15
%            - Modified *.dst viewer to also display relative energy in MeV
%            - Added basic overplotting functionality, needs tweaking
%            (11/16/16)
%            - Overplotting now allows axis unit changes for both plots.
%            - Cleaned up axis rescaling in pe plots in *.dst viewer
%            (11/25/15)
%            - Added "Settings" window to allow changing integration steps
%            without restarting. (12/23/15)
%
%       Wishlist:
%         - Ability to run COSY decks
%         - Programmatically deterimine box location lines (DONE)
%               -Do this for EMITL, not just EMITGR cards
%         - Make "Edit Tune Settings" box well behaved under resizing.
%               Cheated for now - made it non resizable.
%         - Better error handling of duplicate plot names.
%         - Display arbitrary .dst file - In progress
%              - Implement sub menus.
%              - Overlay still needs text and histograms to work in all
%              axis configurations.
%              - Move this out of main function
%              - Multi charge state files
%         - Dialogue box to adjust .ini settings from within program
%

% Last Modified by GUIDE v2.5 29-Jul-2014 11:48:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DynacGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @DynacGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

end

% --- Executes just before figure1 is made visible.
function DynacGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to figure1 (see VARARGIN)
handles.output = hObject;

%VERSION NUMBER
handles.dgversion='4.3';

%Check for open window and refuse to fire again if there is one.
figtag = 'DynacGUI';
oldFig = findobj(allchild(0), 'flat','Tag', figtag);
if ishandle(oldFig); 
    return; 
end

%Set tag for new window
guihandle=findobj('Tag','figure1');
set(guihandle,'Tag','DynacGUI');

%Default Settings - will be overriden if .INI file is present
defaultversion=14; %Default Dynac version
handles.executable='dynacv6_0';
handles.dynac_version=defaultversion; 
handles.inivals.Esectors='10';
handles.inivals.Bsectors='10';
handles.inivals.Csectors='8';
handles.inivals.RFQreject='0.5';

%Open INI file and read initialization parameters:
inifile=fopen('DynacGUI.ini');

if inifile==-1
    set(handles.dynac_output_textbox,...
        'String','Note: No .INI file found, default parameters used');
end

%Assuming an .INI file was present, run through it and deal with 
%the contents. Lines in the .INI file starting with ; are comments.
if inifile>=1
    %Create a structure called "inivals" containing values from the .ini
    %file.  For example, for "Layout  Machine Data\layout.txt": 
    %inivals.layout='Machine Data\layout.txt'
    inivars={'DynacGUI.ini:'};
    i=1;
    while ~feof(inifile)
        line=fgetl(inifile);
        if regexp(line,'^;'); continue; end; %Ignore lines starting with ;
        inivars=[inivars {line}];
        iniarray{i,1}=regexp(line,'\t','split');
        i=i+1;
    end
    tmp=cellfun(@(v) v(1),iniarray(:,1));
    tmp2=cellfun(@(v) v(2),iniarray(:,1));
    handles.inivals=cell2struct(tmp2,tmp,1);
    fclose(inifile);
    
    %Deal with the values present in the .ini file
    if isfield(handles.inivals,'DynacVersion')
        handles.dynac_version=str2num(handles.inivals.DynacVersion);
    else
        inivars=[{'No Dynac version specified in DynacGUI.ini!'}...
            {['Assuming version ' num2str(defaultversion)]}...
            {' '} inivars];
        handles.inivals.DynacVersion=num2str(defaultversion);
    end
    if isfield(handles.inivals,'Tune')
        set(handles.settingsfile_inputbox,'String',handles.inivals.Tune);    
        outputfile=regexprep(handles.inivals.Tune,'\.[^.]+$','.in');
        outputfile=regexprep(outputfile,'^.*\\','');
        set(handles.outputdeck_inputbox,'String',outputfile);
    end
    if isfield(handles.inivals,'Devices')
        set(handles.devicefile_inputbox,'String',handles.inivals.Devices);
    end
    if isfield(handles.inivals,'Layout')
        set(handles.layoutfile_inputbox,'String',handles.inivals.Layout);
    end
    if isfield(handles.inivals,'Executable')
        handles.executable=handles.inivals.Executable;
        if isfield(handles.inivals,'Executable2') %If there is a second executable...
            %check for a version specifier, set a value if missing
            if ~isfield(handles.inivals,'DynacVersion2')
                handles.inivals.DynacVersion2=defaultversion;
            end
            %setup executable choice
            exmenu=uimenu(hObject,'Label','Executable');
            handles.inivals.exm1=uimenu(exmenu,'Label',...
                handles.inivals.Executable,'Callback',...
                {@change_executable,1},'Checked','on');
            handles.inivals.exm2=uimenu(exmenu,'Label',...
                handles.inivals.Executable2,'Callback',...
                {@change_executable,2});
            if isfield(handles.inivals,'Executable3') %If there is ALSO a third
                if ~isfield(handles.inivals,'DynacVersion3')
                    handles.inivals.DynacVersion3=defaultversion;
                end
                handles.inivals.exm3=uimenu(exmenu,'Label',...
                    handles.inivals.Executable3,'callback',...
                    {@change_executable,3});
            end
        end
    end
    if isfield(handles.inivals,'Mingw')
        set(handles.mingw_checkbox,'Value',str2double(handles.inivals.Mingw));
    end
    if isfield(handles.inivals,'ReABoxes')        
        handles.reaboxes=str2double(handles.inivals.ReABoxes);
    else
        handles.reaboxes=0;
    end
    if isfield(handles.inivals,'ReAImport') && (handles.inivals.ReAImport=='1')
        set(handles.machinetune_button,'Visible','on');
    else
        set(handles.machinetune_button,'Visible','off');
    end
    if isfield(handles.inivals,'Edflec')
        inivars=[{'Edflec parameter in DynacGUI.ini is no longer used.'}...
            {'DynacVersion will be used to set E Deflector type'}...
            {' '} inivars];
    end
    %Display .ini values
    set(handles.dynac_output_textbox,'String',inivars);
end



guidata(hObject,handles);

if ~ispc %correct default file names for non-pcs.
        settingsfile=get(handles.settingsfile_inputbox,'String');
        settingsfile=strrep(settingsfile,'\','/');
        set(handles.settingsfile_inputbox,'String',settingsfile);
        devicefile=get(handles.devicefile_inputbox,'String');
        devicefile=strrep(devicefile,'\','/');
        set(handles.devicefile_inputbox,'String',devicefile);
        layoutfile=get(handles.layoutfile_inputbox,'String');
        layoutfile=strrep(layoutfile,'\','/');
        set(handles.layoutfile_inputbox,'String',layoutfile);
        set(handles.mingw_checkbox,'Value',0); %assume NOT mingw
end

%No initial particle distribution
set(handles.pdfile_inputbox,'Userdata',0);

%Populate initial data
set(handles.title_textbox,'String',['DynacGUI v. ' handles.dgversion]);
populate_data(hObject,eventdata,handles);
handles.outfile=get(handles.outputdeck_inputbox,'String');

%Set up Tools Menu
toolsmenu=uimenu(hObject,'Label','Tools');
%If the 'gencosydeck.m' routine is present, add COSY menu
if exist('gencosydeck.m','file') 
    uimenu(toolsmenu,'Label','Generate COSY Deck',...
        'Callback',{'gencosydeck'});
end
%If the 'rescaletune.m' routine is present, add menu item
if exist('rescaletune.m','file')
    uimenu(toolsmenu,'Label','Generate Scaled Tune',...
        'Callback',@scaled_tune);
end
%Add "Save and View Results" options to tools menu
handles=guidata(handles.output);
handles.sr_menu=uimenu(toolsmenu,'Label','Save Results','Callback',@save_results,...
    'Separator','on','Enable','off');
if exist('DG_viewresults.m','file')
    uimenu(toolsmenu,'Label','View Results','Callback',@DG_viewresults);
end
%Add fitting to tools menu
if exist('DynacGUIFit.m','file') && license('test','optimization_toolbox')
    handles.fitmenu=uimenu(toolsmenu,'Label','Fitting Tool',...
        'Callback',@call_dgf,'Enable','off','separator','on');
end
%If the 'loadcs.m' routine is present, add loadcs tool.
if exist('loadcs.m','file');
    uimenu(toolsmenu,'Label','Load CS Tune',...
        'Callback',{'loadcs'});
end
%Add Settings Dialog
uimenu(toolsmenu,'Label','Settings','Callback',@change_dynacgui_settings,...
    'separator','on');
%If no tools are present, hide tools menu
if isempty(get(toolsmenu,'Children'))
    set(toolsmenu,'Visible','off');
end


%Start with Energy / Envelope plots disabled
set(handles.zplots_button,'Enable','off');


%Choose default text editor/viewer
if ispc
    handles.texteditor='notepad ';
elseif ismac
    handles.texteditor='TextEdit ';
else
    handles.texteditor='cat ';
end

%Set up "View Files" menu
handles.filesmenu=uimenu(hObject,'Label','View Files');
uimenu(handles.filesmenu,'Label','dynac.short','Callback',...
    ['system(''' handles.texteditor 'dynac.short &'');']);
uimenu(handles.filesmenu,'Label','dynac.long','Callback',...
    ['system(''' handles.texteditor 'dynac.long &'');']);
uimenu(handles.filesmenu,'Label','dynac.print','Callback',...
    ['system(''' handles.texteditor 'dynac.print &'');']);
uimenu(handles.filesmenu,'Label','emit.plot','Callback',...
    ['system(''' handles.texteditor 'emit.plot &'');']);
uimenu(handles.filesmenu,'Label','Current Layout File','Callback',...
    {@viewcurrent,'layout'},'Separator','on');
uimenu(handles.filesmenu,'Label','Current Devices File','Callback',...
    {@viewcurrent,'devices'});
uimenu(handles.filesmenu,'Label','Current Tune File','Callback',...
    {@viewcurrent,'tune'});
uimenu(handles.filesmenu,'Label','Current Output Deck','Callback',...
    {@viewcurrent,'deck'});
uimenu(handles.filesmenu,'Label','DynacGUI.ini','Callback',...
    ['system(''' handles.texteditor 'DynacGUI.ini &'');'],...
    'Separator','on');
uimenu(handles.filesmenu,'Label','Plot .dst file...','Callback',...
    {@plotdst},'Separator','on');

guidata(hObject,handles);
end

function viewcurrent(hObject,~,type)
%Call text viewer for specified file
handles=guidata(hObject);
switch type
    case 'layout'    
        filename=get(handles.layoutfile_inputbox,'String');
    case 'devices'
        filename=get(handles.devicefile_inputbox,'String');
    case 'tune'
        filename=get(handles.settingsfile_inputbox,'String');
    case 'deck'
        filename=get(handles.outputdeck_inputbox,'String');
    otherwise
        return
end
system([handles.texteditor filename ' &']);
end

function call_dgf(hObject,~)
%Call DynacGUI fitting window
handles=guidata(hObject);
filename=get(handles.outputdeck_inputbox,'String');
DynacGUIFit(filename);
end

function save_results(hObject, ~)
%Save output files
handles=guidata(hObject);

%Create 'Results' directory if none exists
    if ~isdir('Results')
        try mkdir('Results');
        catch
            disperror('Unable to create Results directory');
            return
        end
    end
    
%Get subdirectory to save current results - default to deck name
    defaultsrdir=strrep(get(handles.outputdeck_inputbox,'String'),'.in','');
    srdir=inputdlg('Save results to folder:','Save Location',1,...
        {defaultsrdir},'on');
    if isequal(srdir,{}) %End if cancelled
        return;
    end
    srdir=fullfile('Results',srdir);
    srdir=srdir{1};
    
%Create output directory if none exists
    if ~isdir(srdir)
        try mkdir(srdir);
        catch
            disperror(['Unable to create directory: ' srdir])
            return
        end
    end
    
%Files to copy
resultfiles={'dynac.long',...
             'dynac.short',...
             'dynac.dmp',...
             'dynac.print',...
             'emit.plot',...
             get(handles.outputdeck_inputbox,'String')}; %Dynac deck
%remove any files that may be missing from list
resultfiles=resultfiles(cellfun(@exist,resultfiles)~=0);

%copy selected files
for i=1:length(resultfiles)
    copyfile(resultfiles{i}, srdir);
end

%write a tune file
writetune('tune.txt',[srdir filesep],handles.settings);

%write a file with needed variables
ud=get(handles.generatedgraphs_listbox,'Userdata'); %#ok<NASGU>
set=handles.settings; %#ok<NASGU>
save([srdir filesep 'data.mat'],'ud','set');

outputstring=(['Results Saved to:' srdir 'Files: ' resultfiles...
    'tune.txt' 'data.mat']);
         
disperror(outputstring);
end

function scaled_tune(hObject,~)
%Generate a tune scaled for different Q/A or final energy values
    hobj=hObject;
    %Opens window to generate scaled tunes.
    escale=1;
    bscale=1;
    cavscale=1;
    swheight=400;
    scalewin=figure('Name','Generate Scaled Tune','Color',[0.941 0.941 0.941],...
        'Position',[50 500 560 swheight],'NumberTitle','Off');
    handles=guidata(hObject);
    uicontrol('Style','Text','String','Current Settings:',...
        'Position',[10 swheight-20 100 20],'FontSize',10);
    uicontrol('Style','Text',...
        'String','Q:','HorizontalAlignment','Right',...
        'Position',[10 swheight-50 70 20]);
    input_initialq=uicontrol('Style','text','Position',[90 swheight-50 60 20],...
        'String',num2str(handles.settings.Q),'HorizontalAlignment','Left');
    uicontrol('Style','Text',...
        'String','A:','HorizontalAlignment','Right',...
        'Position',[10 swheight-70 70 20]);
    input_initiala=uicontrol('Style','text','Position',[90 swheight-70 60 20],...
        'String',num2str(handles.settings.A),'HorizontalAlignment','Left');
    uicontrol('Style','text','String','Energy (MeV): ',...
        'Position',[10 swheight-90 70 20]);
    input_initiale=uicontrol('Style','edit','Position',[90 swheight-90 60 20],...
        'BackgroundColor','white','String',num2str(handles.settings.Energy),...
        'Callback',@enter_scale,'HorizontalAlignment','Left');
    uicontrol('Style','Text','String','Scale To:',...
        'Position',[200 swheight-20 100 20],'FontSize',10,...
        'HorizontalAlignment','Center');
    uicontrol('Style','Text','HorizontalAlignment','Right',...
        'String','Q:','Position',[200,swheight-50,70,20]);
    uicontrol('Style','Text','HorizontalAlignment','Right',...
        'String','A:','Position',[200,swheight-70,70,20]);
    uicontrol('Style','Text','HorizontalAlignment','Right',...
        'String','Energy (MeV):','Position',[200,swheight-90,70,20]);
    input_finalq=uicontrol('Style','edit','Position',[280,swheight-50,70,20],...
        'HorizontalAlignment','Left','String',num2str(handles.settings.Q),...
        'BackgroundColor','White','Callback',@enter_scale);
    input_finala=uicontrol('Style','edit','Position',[280,swheight-70,70,20],...
        'HorizontalAlignment','Left','String',num2str(handles.settings.A),...
        'BackgroundColor','White','Callback',@enter_scale);
    input_finale=uicontrol('Style','edit','Position',[280,swheight-90,70,20],...
        'HorizontalAlignment','Left','String',num2str(handles.settings.Energy),...
        'BackgroundColor','White','Callback',@enter_scale);
    uicontrol('Style','Text','HorizontalAlignment','Center',...
        'FontSize',10,'String','Scaling Factors',...
        'Position',[400 swheight-20 100 20]);
    uicontrol('Style','Text','HorizontalAlignment','Right',...
        'String','E:','Position',[400 swheight-50 50 20]);
    uicontrol('Style','Text','HorizontalAlignment','Right',...
        'String','B:','Position',[400 swheight-70 50 20]);
    uicontrol('Style','Text','HorizontalAlignment','Right',...
        'String','Cav:','Position',[400 swheight-90 50 20]);
    escalebox=uicontrol('Style','Text','HorizontalAlignment','Left',...
        'String',num2str(escale,3),'Position',[460 swheight-50 50 20]);
    bscalebox=uicontrol('Style','Text','HorizontalAlignment','Left',...
        'String',num2str(bscale,3),'Position',[460 swheight-70 50 20]);
    cavscalebox=uicontrol('Style','Text','HorizontalAlignment','Left',...
        'String',num2str(cavscale,3),'Position',[460 swheight-90 50 20]);
    uicontrol('style','pushbutton','FontSize',10,...
        'String','Rescale Tune','Position',[440 swheight-130 100 20],...
        'Callback',{@rescale_button_callback,hobj});
    startpointbox=uicontrol('Style','listbox','Position',[20 20 180 swheight-160],...
        'BackgroundColor','white');
    endpointbox=uicontrol('Style','listbox','Position',[240 20 180 swheight-160],...
        'BackgroundColor','white');
    uicontrol('style','text','String','Start Point:',...
        'Position',[20 swheight-140 180 20],'HorizontalAlignment','Left');
    uicontrol('style','text','String','End Point:',...
        'Position',[240 swheight-140 180 20],'HorizontalAlignment','Left');
    
    %Populate start and end point boxes
    layoutfilename=get(handles.layoutfile_inputbox,'String');
    rsdevlist={};
    layoutfile=fopen(layoutfilename);
        while ~feof(layoutfile)
            linein=regexprep(fgetl(layoutfile),'\t',' ');
            rsdevlist=[rsdevlist linein];
        end
    fclose(layoutfile);
    set(startpointbox,'String',rsdevlist);
    set(endpointbox,'String',rsdevlist,'Value',length(rsdevlist));
    
    function rescale_button_callback(~, ~, hObject)
        %Callback for "Rescale Tune" button.
        handles.settings.A=str2num(get(input_finala,'String'));
        handles.settings.Q=str2num(get(input_finalq,'String'));
        layoutfilename=get(handles.layoutfile_inputbox,'String');
        devicefilename=get(handles.devicefile_inputbox,'String');
        outputfilename=get(handles.outputdeck_inputbox,'String');
        
        [handles.settings]=rescaletune(handles.settings,layoutfilename,...
            devicefilename,escale,bscale,cavscale,get(startpointbox,'Value'),...
            get(endpointbox,'Value'));
        
        %Set "Run" box to off.
        set(handles.gendeck_checkbox,'Value',0);
        set(handles.viewdeck_button,'Enable','on');
        set(handles.rundeck_checkbox,'Value',0);
        set(handles.longdist_checkbox,'Value',0.0);
        set(handles.sr_menu,'Enable','off');
        settingsfile=get(handles.settingsfile_inputbox,'String');
        if(isempty(regexp(settingsfile,'\*+$','start')))
            set(handles.settingsfile_inputbox,'String',[settingsfile '*']);
        end
        if(isempty(regexp(outputfilename,'_scaled+$','start')))
            newoutfilename=strrep(outputfilename,'.in','_scaled.in');
            set(handles.outputdeck_inputbox,'String',newoutfilename);
        end
        set(handles.a_textbox,'String',get(input_finala,'String'));
        set(handles.q_textbox,'String',get(input_finalq,'String'));
        set(input_initialq,'String',get(input_finalq,'String'));
        set(input_initiala,'String',get(input_finala,'String')); 
        set(input_initiale,'String',get(input_finale,'String'));
        guidata(hObject,handles);
        
        setwin=findobj(allchild(0),'Tag','DGSettings');
        if ishandle(setwin)
            close(setwin);
            showsettings_button_Callback(hObject,[],handles);
        end            
    end
    
    function enter_scale(~, ~)
    %Recalculate scaling parameters when new values entered
        initiale=str2double(get(input_initiale,'String'));
        finale=str2double(get(input_finale,'String'));
        initialq=str2double(get(input_initialq,'String'));
        initiala=str2double(get(input_initiala,'String'));
        finalq=str2double(get(input_finalq,'String'));
        finala=str2double(get(input_finala,'String'));
        escale=(initialq/initiala)/(finalq/finala); %Electric Field Scaling (just q/a)
        bscale=escale*sqrt(finale/finala)*sqrt(initiala/initiale); %Magnetic Field Scaling
        cavscale=escale*(finale/finala)*(initiala/initiale); %Cavity Amplitude
        set(escalebox,'String',num2str(escale,3));
        set(bscalebox,'String',num2str(bscale,3));
        set(cavscalebox,'String',num2str(cavscale,3));
    end
end


function change_executable(hObject, ~, exnumber)
    %Changes the active executable to the exnumber.  Performs
    %NO sanity checks.
    handles=guidata(hObject);
    if exnumber==1
        handles.executable=handles.inivals.Executable;
        handles.dynac_version=str2num(handles.inivals.DynacVersion);
        set(handles.inivals.exm1,'Checked','On');
        set(handles.inivals.exm2,'Checked','Off');
        if isfield(handles.inivals,'exm3');
            set(handles.inivals.exm3,'Checked','Off');
        end
    elseif exnumber==2
        handles.executable=handles.inivals.Executable2;
        handles.dynac_version=str2num(handles.inivals.DynacVersion2);
        set(handles.inivals.exm1,'Checked','Off');
        set(handles.inivals.exm2,'Checked','On');
        if isfield(handles.inivals,'exm3')
            set(handles.inivals.exm3,'Checked','Off');
        end
    elseif exnumber==3
        handles.executable=handles.inivals.Executable3;
        handles.dynac_version=handles.inivals.DynacVersion3;
        set(handles.inivals.exm1,'Checked','Off');
        set(handles.inivals.exm2,'Checked','Off');
        set(handles.inivals.exm3,'Checked','On');
    else
        disperror('Error! Executable not found in .ini file');
    end
    guidata(hObject,handles);
end


% --- Outputs from this function are returned to the command line.
function varargout = DynacGUI_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
try
    varargout{1} = handles.output;
catch
    varargout{1} = 'Error in initialization';
end
end


function outputdeck_inputbox_Callback(hObject, ~, handles) %#ok<DEFNU>
%Sets name of output deck.  If nothing is selected, use "Default.in"
input = get(hObject,'String');

if (isempty(input))
    set(hObject,'String',handles.outfile);
else
    handles.outfile=input;
end
uicontrol(handles.gendeck_button);

%Clear checkboxes
set(handles.gendeck_checkbox,'Value',0.0);
set(handles.viewdeck_button,'Enable','off');
set(handles.sr_menu,'Enable','off');
set(handles.rundeck_checkbox,'Value',0.0);
guidata(hObject, handles)
end

% --- Executes during object creation, after setting all properties.
function outputdeck_inputbox_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function settingsfile_inputbox_Callback(hObject, ~, handles)
%Shouldn't fire - this box is read-only.
input = get(hObject,'String');

if (isempty(input))
    set(hObject,'String','tunesettings.txt')
end
guidata(hObject, handles)
end

% --- Executes during object creation, after setting all properties.
function settingsfile_inputbox_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white'); 
end
end


function layoutfile_inputbox_Callback(hObject, ~, handles)
%Shouldn't fire - box is read only.

input = get(hObject,'String');

if (isempty(input))
    set(hObject,'String','layout.txt')
end
guidata(hObject, handles)
end

% --- Executes during object creation, after setting all properties.
function layoutfile_inputbox_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function devicefile_inputbox_Callback(hObject, ~, handles)
%Shouldn't fire - box is read only
input = get(hObject,'String');

if (isempty(input))
    set(hObject,'String','devices.txt')
end
guidata(hObject, handles)
end

% --- Executes during object creation, after setting all properties.
function devicefile_inputbox_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in gendeck_button.
function gendeck_button_Callback(hObject, ~, handles) %#ok<DEFNU>
%Calls gendeck.m to build output deck
outputfilename = get(handles.outputdeck_inputbox,'String');
tunefilename=get(handles.settingsfile_inputbox,'String');
if isempty(get(handles.a_textbox,'String'))
    populate_data(hObject, eventdata,handles);
    handles=guidata(handles.output);
end
layoutfilename = get(handles.layoutfile_inputbox,'String');
devicefilename = get(handles.devicefile_inputbox,'String');
%plots = get(handles.graphs_listbox,'Value');

if get(handles.pdfile_checkbox,'Value') && ...
            get(handles.pdfile_inputbox,'Userdata')==1
    pdfilename = get(handles.pdfile_inputbox,'String');
    [handles.settings,freqlist]=gendeck(outputfilename,...
        handles.settings,layoutfilename,devicefilename,pdfilename);
elseif get(handles.pdfile_checkbox,'Value') && ...
            get(handles.pdfile_inputbox,'Userdata')==0
    disperror('Error: No particle distribution selected');
    return
else
    [handles.settings,freqlist]=gendeck(outputfilename,...
        handles.settings,layoutfilename,devicefilename); 
end
ud=get(handles.generatedgraphs_listbox,'UserData');
ud.freqlist=freqlist;
set(handles.generatedgraphs_listbox,'UserData',ud);

%Set "Generated" box to on and "Run" box to off.
set(handles.gendeck_checkbox,'Value',1.0);
set(handles.viewdeck_button,'Enable','on');
set(handles.sr_menu,'Enable','off');
set(handles.rundeck_checkbox,'Value',0);
set(handles.longdist_checkbox,'Value',0.0);
if isfield(handles,'fitmenu') %Only if there IS a fit menu item
    set(handles.fitmenu,'Enable','on');
end
handles.genfilename=outputfilename;
guidata(hObject, handles);
end

% --- Executes on button press in settingsfile_button.
function settingsfile_button_Callback(hObject, eventdata, handles) %#ok<DEFNU>
%Select settings file - return to previous value if cancelled
temp=get(handles.settingsfile_inputbox,'String');
if ispc
    [settingsfile,settingsfilepath,~]=uigetfile('Tune Settings\*.*');
else
    [settingsfile,settingsfilepath,~]=uigetfile('Tune Settings/*.*');
end
if isequal(settingsfile,0) %Return to status quo if user hits cancel.
    settingsfile=temp;
    set(handles.settingsfile_inputbox,'String',settingsfile);
else
    %load data from settings file using "populate data"
    set(handles.settingsfile_inputbox,'String',[settingsfilepath settingsfile]);
    populate_data(hObject,eventdata,handles)
    handles=guidata(handles.output);
    %name output file after input file with *.in extension
    outputfile=regexprep(settingsfile,'\.[^.]+$','.in');
    set (handles.outputdeck_inputbox,'String',outputfile);
    %reset checkboxes
    set(handles.gendeck_checkbox,'Value',0.0);
    set(handles.viewdeck_button,'Enable','off');
    set(handles.sr_menu,'Enable','off');
    set(handles.rundeck_checkbox,'Value',0.0);
    set(handles.longdist_checkbox,'Value',0.0);
end
guidata(hObject, handles)

    %If the "edit tune settings" window is open, regenerate it.
        setwin=findobj(allchild(0),'Tag','DGSettings');
        if ishandle(setwin)
            close(setwin);
            showsettings_button_Callback(hObject,[],handles);
        end 
end

function populate_data(hObject,~,handles)
% Load settings from tune file and populate the tune data boxes
% This routine opens the settings file, and converts a tab or
% space separated list to a structure of the form
% Settings.parameter = parameter value
settingsfile=get(handles.settingsfile_inputbox,'String');

    try
        sf=fopen(settingsfile);
        if sf== -1
            disperror('Error: Settings File Not Found');
            return;
        end
    catch
        disperror('Error: Unable to open file');
        return;
    end
    
i=1;
while ~feof(sf)
    line=fgetl(sf);
    if regexp(line,'^;') %Skip comment lines
        continue
    end
    testsets{i,1}=regexp(line,'\s+','split');
    i=i+1;
end
%Clear any blank lines or lines without at least two items
testsets=testsets(cellfun('length',testsets)>1);

names=cellfun(@(v) v(1),testsets(:,1));
values=cellfun(@(v) v(2),testsets(:,1));

settings=cell2struct(values,names,1);
settings=structfun(@(x) str2num(x),settings,'UniformOutput',0);
fclose(sf);

handles.settings=settings;

%set display boxes for global variables
set(handles.a_textbox,'String',num2str(settings.A));
set(handles.q_textbox,'String',num2str(settings.Q));
set(handles.energy_textbox,'String',num2str(settings.Energy));
if isfield(settings,'Deltae')
    set(handles.deltae_textbox,'String',num2str(settings.Deltae));
end
set(handles.npart_textbox,'String',num2str(settings.Npart));

guidata(hObject, handles)
end


% --- Executes on button press in layoutfile_button.
function layoutfile_button_Callback(hObject, ~, handles) %#ok<DEFNU>
%Loads layout file.  If "Cancel" is selected, resets previous value

temp=get(handles.layoutfile_inputbox,'String');
if ispc
    [layoutfile,lfpath,~]=uigetfile('Machine Data\*.*');
else
    [layoutfile,lfpath,~]=uigetfile('Machine Data/*.*');
end
if isequal(layoutfile,0)
    layoutfile=temp;
    set (handles.layoutfile_inputbox,'String',layoutfile);
else
    %reset checkboxes
    set(handles.gendeck_checkbox,'Value',0.0); 
    set(handles.viewdeck_button,'Enable','off');
    set(handles.sr_menu,'Enable','off');
    set(handles.rundeck_checkbox,'Value',0);
    set(handles.longdist_checkbox,'Value',0.0);
    set (handles.layoutfile_inputbox,'String',[lfpath layoutfile]);
    %load graphs from layout file and populate list box
    %populate_graphlist(hObject,eventdata,handles);
end
guidata(hObject, handles)
end

% --- Executes on button press in devicefile_button.
function devicefile_button_Callback(hObject, ~, handles) %#ok<DEFNU>

temp=get(handles.devicefile_inputbox,'String');
if ispc
    [devicefile,dfpath,~]=uigetfile('Machine Data\*.*');
else
    [devicefile,dfpath,~]=uigetfile('Machine Data/*.*');
end
if isequal(devicefile,0)
    %devicefile=temp;
    set (handles.devicefile_inputbox,'String',temp)
else
    set(handles.gendeck_checkbox,'Value',0.0);
    set(handles.viewdeck_button,'Enable','off');
    set(handles.sr_menu,'Enable','off');
    set(handles.rundeck_checkbox,'Value',0.0);
    set(handles.longdist_checkbox,'Value',0.0);
    set (handles.devicefile_inputbox,'String',[dfpath devicefile]);
end
guidata(hObject, handles)
end

% --- Executes on button press in outputfile_button.
function outputfile_button_Callback(hObject, ~, handles) %#ok<DEFNU>

temp=get(handles.outputdeck_inputbox,'String');
outputfile=uigetfile('*.*');
if isequal(outputfile,0)
    outputfile=temp;
    set(handles.outputdeck_inputbox,'String',outputfile);
else
    set (handles.outputdeck_inputbox,'String',outputfile);
    set(handles.gendeck_checkbox,'Value',0.0);
    set(handles.viewdeck_button,'Enable','off');
    set(handles.sr_menu,'Enable','off');
    set(handles.rundeck_checkbox,'Value',0.0);
    set(handles.longdist_checkbox,'Value',0.0);
end
guidata(hObject, handles)
end

% --- Executes on button press in gendeck_checkbox.
function gendeck_checkbox_Callback(~, ~, ~) %#ok<DEFNU>
end
% Hint: get(hObject,'Value') returns toggle state of gendeck_checkbox


% --- Executes on button press in rundeck_button.
function rundeck_button_Callback(hObject, ~, handles) %#ok<DEFNU>

if isfield(handles,'genfilename') %If the specified deck really exists
    if (get(handles.mingw_checkbox,'Value')==1) %Build executable command
        command=['"' handles.executable '" -mingw ' handles.genfilename];
    else
        command=['"' handles.executable '" ' handles.genfilename];
    end
%     if exist('emit.plot', 'file')==2
%         delete('emit.plot');
%     end
    set(handles.rundeck_button,'ForegroundColor',[1 0 0],'String','Running');
    
    %Execute Dynac
    [~,dynacoutput]=system(command); 
    set(handles.dynac_output_textbox,'String',dynacoutput,'ForegroundColor','k');
    guidata(hObject,handles);
    
    %Set checkboxes
    set(handles.rundeck_button,'ForegroundColor',[0 0 0],'String','Run Deck');
    set(handles.rundeck_checkbox,'Value',1);
    set(handles.longdist_checkbox,'Value',0.0);
    if regexp(dynacoutput,'statistics too low')
        dynacoutput={'Execution Failed, less than ten particles remaining.',...
            'Check dynac.long for more information.',...
            'Note: any plots displayed at left are from last successful run.'};
        set(handles.dynac_output_textbox,'String',dynacoutput,'ForegroundColor','r');
        set(handles.zplots_button,'Enable','off');
        set(handles.generatedgraphs_listbox,'ForegroundColor','r');
        return
    end
    set(handles.sr_menu,'Enable','on');
    %Retrieve frequency list generated by 'gendeck'
    ud=get(handles.generatedgraphs_listbox,'UserData');
    %Scan 'emit.plot' for plots, generate list of starting points and names
    %[ud.plotlist,ud.plotloc,ud.names,ud.plotzpos]=
    scanemitplot(ud.freqlist,handles);
    %Retrieve updated plot list
    ud=get(handles.generatedgraphs_listbox,'UserData');
    if isfield(ud,'plotlist')
        set(handles.generatedgraphs_listbox,'String',ud.plotlist,...
            'ForegroundColor','k');
    end
    set(handles.generatedgraphs_listbox,'Value',1);
    %Store ud, now containing plot locations as well as frequencies
    %set(handles.generatedgraphs_listbox,'UserData',ud);
    
    %Enable Z Plots
    set(handles.zplots_button,'Enable','on');
else
    disperror('Error: Input Deck Not Found');
end

end


% --- Executes on button press in plotgraphs_buton.
function plotgraphs_buton_Callback(~, ~, handles) %#ok<DEFNU>
if exist('emit.plot', 'file')==2
    ud=get(handles.generatedgraphs_listbox,'UserData');
    emitplot(ud.freqlist);
else
  disperror('Error: No Plots Generated');
end

end

% --- Executes on button press in rundeck_checkbox.
function rundeck_checkbox_Callback(~, ~, ~) %#ok<DEFNU>
end
% Hint: get(hObject,'Value') returns toggle state of rundeck_checkbox


function mingw_checkbox_Callback(~, ~, ~) %#ok<DEFNU>
end

% --- Executes on button press in showsettings_button.
function showsettings_button_Callback(hObject, ~, handles) %#ok<DEFNU>

%Check to see if the window is already open, and if it is, refuse to open
%another one
setwin=findobj(allchild(0),'Tag','DGSettings');
        if ishandle(setwin)
            return
        end 

%Retrieve list of units
if ~isempty(get(hObject,'UserData'))
    unitstruct=get(hObject,'UserData');
end

%Generate dialog box with tune settings
fields=fieldnames(handles.settings);
nfields=size(fields,1);
parent=hObject;
scrsz = get(0,'ScreenSize');

%Setup box with scrollable list
%Generate actual figure, sized relative to screen size.
settingsfigure=figure('Name','Tune Settings','NumberTitle','Off',...
    'Position',[.1*scrsz(3) .02*scrsz(4) scrsz(3)/2 scrsz(4)*.9],...
    'Resize','off','Tag','DGSettings');
%Generate the backgound panel with the title of the tune.
panel1 = uipanel('Parent',settingsfigure,'Title',...
    get(handles.settingsfile_inputbox,'String'),...
    'FontSize',14);
set(panel1,'Position',[0 0 0.95 1]); %Parent panel occupies all of height and 95% of width
%Generate the child panel
panel2 = uipanel('Parent',panel1);
%Set up child panel to be as long as it needs to be, with padding at the
%top.
set(panel1,'Units','points');
p1pos=get(panel1,'Position');
cellheight=20; %Cell height, in points
toppad=30; %Top padding, in points
set(panel2,'Units','points','Position',...
    [0 p1pos(4)-cellheight*nfields-toppad p1pos(3) cellheight*nfields]);
set(panel2,'Units','normalized');

%Set up grid container.  It occupies 80% of the child panel in both
%directions.
hc=uigridcontainer('v0','Units','norm','Position',[.1 .1 .9 .9],...
    'Parent',panel2);
%Grid size is set here so that it's 2 fields wide and as long as it needs
%to be.
set(hc, 'GridSize',[size(fields,1),2]);
set(hc,'EliminateEmptySpace','off')

%populate list with tune settings
for i=1:nfields; 
    if exist('unitstruct') 
        label=[fields{i} ' ' unitstruct.(fields{i})];
    else
        label=fields(i);
    end
    h(i,1) = uicontrol('Style','text','string',label,'parent',hc,...
        'HorizontalAlignment','right');
    h(i,2) = uicontrol('Style','edit','string',...
        getfield(handles.settings,fields{i}),'parent',hc,...
        'Callback',{@setting_callback,i,fields},'BackgroundColor','white');
end

s=uicontrol('Style','Slider','Parent',settingsfigure,...
    'Units','normalized','Position',[.95 0 0.05 1],...
    'Value',.5,'Callback',{@slider_callback1,panel1,panel2});

slider_callback1(s,'',panel1,panel2);
set(s,'Value',1)
slider_callback1(s,'',panel1,panel2);

function slider_callback1(src,~,panel1,panel2)
    val=get(src,'Value');
    set(panel1,'Units','Points');
    set(panel2,'Units','Points');
    p1pos=get(panel1,'Position');
    p2pos=get(panel2,'Position');
    set(panel2,'Position',[0 val*(p1pos(4)-p2pos(4))-toppad p1pos(3) p2pos(4)]);
end 

function setting_callback(hObject,~,i,fields)
    %change setting value when textbox is edited
    val=get(hObject,'String');
    handles.settings.(fields{i})=str2num(val);
    set(handles.a_textbox,'String',num2str(handles.settings.A));
    set(handles.q_textbox,'String',num2str(handles.settings.Q));
    set(handles.energy_textbox,'String',handles.settings.Energy);
    if isfield(handles.settings,'Deltae')
        set(handles.deltae_textbox,'String',handles.settings.Deltae);
    end
    set(handles.npart_textbox,'String',handles.settings.Npart);
    set(handles.gendeck_checkbox,'Value',0.0);
    set(handles.viewdeck_button,'Enable','off');
    set(handles.sr_menu,'Enable','off');
    set(handles.rundeck_checkbox,'Value',0.0);
    set(handles.longdist_checkbox,'Value',0.0);
    settingsfile=get(handles.settingsfile_inputbox,'String');
    if(isempty(regexp(settingsfile,'\*+$','start')))
        set(handles.settingsfile_inputbox,'String',[settingsfile '*']);
    end
    guidata(parent,handles);
end

end


function dynac_output_textbox_Callback(~, ~, ~) %#ok<DEFNU>
%Q/A test maybe?  Should something happen if someone enter a new value?
end

function dynac_output_textbox_CreateFcn(hObject, ~, ~) %#ok<DEFNU>

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function machinetune_button_Callback(hObject, ~, handles) %#ok<DEFNU>
%Creates a dialogue box to load in ROCS output files for
%ReA3.  Disabled by default unless enabled in .ini file.

%Create box
tunemenu=figure('Name','Machine Settings','NumberTitle','Off',...
    'MenuBar','none','Position',[65 570 560 420],...
    'Color',[.9412 .9412 .9412]);

%Populate dialogue box
uicontrol(tunemenu,'Style','text','Position',[150 390 250 30],...
    'String','ReA3 Machine Tune','FontSize',14);
qalinacfile_inputbox=uicontrol(tunemenu,'Style','text','Position',[10 350 250 35],...
    'BackgroundColor',[1 1 1]);
uicontrol(tunemenu,'Style','pushbutton',...
    'Position',[270 350 250 35],'String',...
    'Select QA/Linac Machine File','HorizontalAlignment','Left',...
    'Callback',@setqafile);
llinefile_inputbox=uicontrol(tunemenu,'Style','text','Position',[10 300 250 35],...
    'BackgroundColor',[1 1 1]);
uicontrol(tunemenu,'Style','pushbutton','Position',[270 300 250 35],...
    'String','Select L-Line and Extension Machine File',...
    'HorizontalAlignment','Left','Callback',@setlfile);

uicontrol(tunemenu,'Style','pushbutton','Position',[10 200 250 20],...
    'String','Load Tune Files','Callback',@loadtunes);
loadtunes_checkbox=uicontrol(tunemenu,'Style','checkbox','Position',[270 200 150 20],...
    'String','Tunes Loaded','Value',0);

messagebox_textbox=uicontrol(tunemenu,'Style','text','Position',[10,50,500,20],...
    'HorizontalAlignment','Left');

    function loadtunes(~,~)
    %This function loads the two tune files, combines them into
    %one structure, and converts from machine units to code
    %units where applicable.  For now, the conversions are hard-
    %coded - they should probably be moved to external files at
    %some point.
        qafilename=get(qalinacfile_inputbox,'String');
        lfilename=get(llinefile_inputbox,'String');
        
        if isempty(qafilename) || isempty(lfilename)
            set(messagebox_textbox,'String',...
                'Error: User must select two files');
            return
        else
            set(messagebox_textbox,'String','');
        end
        
        qf=fopen(qafilename);
        %Scan QA/LEBT/LINAC file, discarding comments 
        %Also toss everything after the "read only" line.
        i=1;
        while ~feof(qf)
            line=fgetl(qf);
            if ~isempty(regexp(line,'NOT RESTORED','match'))
                break;                         
            elseif ~isempty(regexp(line,'(^\#|PULS)','match'))
                continue;
            elseif ~isempty(regexp(line,'(-R)','match'))
                line=regexprep(line,'-R','');
            end
            machinedata{i,1}=regexp(line,'\s+','split');
            i=i+1;
        end
        fclose(qf);
        
        lf=fopen(lfilename);
        %Scan L-line/extension file, discarding comments,
        %and everything in the "read only" section.
        while ~feof(lf)
            line=fgetl(lf);
            if ~isempty(regexp(line,'NOT RESTORED','match'))
                break;
            elseif ~isempty(regexp(line,'^\#','match'))
                continue;
            end
                       
            machinedata{i,1}=regexp(line,'\s+','split');
            i=i+1;
        end
        fclose(lf);
        
        %Convert to a structure array       
        tmp=cellfun(@(v) regexprep(v(1),'(\.[^.]+$|:\w*_CSET|\REA_BTS\d*:)',''),machinedata(:,1));
        tmp2=cellfun(@(v) v(2),machinedata(:,1));
        machinedata=cell2struct(tmp2,tmp,1);       
        machinedata=structfun(@(x) str2num(x),machinedata,...
            'UniformOutput',0);
        
        %Set global parameters
        scanfilename(qafilename);                
        handles.settings.Deltae=.0042*handles.settings.Energy;
        set(handles.deltae_textbox,'String',handles.settings.Deltae);
        handles.settings.Npart=1000;
        set(handles.npart_textbox,'String',handles.settings.Npart);
        handles.settings.Alphax=0;
        handles.settings.Betax=.4;
        handles.settings.Epsx=10.;
        handles.settings.Alphay=0;
        handles.settings.Betay=.4;
        handles.settings.Epsy=10.;
        qovera=handles.settings.Q/handles.settings.A;
        
        %Q/A and LEBT parameters
        handles.settings.L018TAE=machinedata.L018TAE*.001;
        handles.settings.L018TBE=machinedata.L018TBE*.001;
        handles.settings.L018TCE=machinedata.L018TCE*.001;
        handles.settings.L024TA=machinedata.L024TA*.001;
        handles.settings.L024TB=machinedata.L024TB*.001;
        handles.settings.L024TC=machinedata.L024TC*.001;
        handles.settings.L030QS=machinedata.L030QS*.001;
        handles.settings.L035QA=machinedata.L035QA*.001;
        handles.settings.L035QB=machinedata.L035QB*.001;
        handles.settings.L042QA=machinedata.L042QA*.001;
        handles.settings.L042QB=machinedata.L042QB*.001;
        handles.settings.L045QA=machinedata.L045QA*.001;
        handles.settings.L045QB=machinedata.L045QB*.001;
        handles.settings.L048QA=machinedata.L048QA*.001;
        handles.settings.L048QB=machinedata.L048QB*.001;     
        handles.settings.L054QA=machinedata.L054QA*.001;
        handles.settings.L054QB=machinedata.L054QB*.001;
        handles.settings.L057QA=machinedata.L057QA*.001;
        handles.settings.L057QB=machinedata.L057QB*.001;
        
        %MHB Parameters
        %Note: These are NOT loaded from the machine tune - 
        %for now the phase is simply set, and the amplitude is 
        %scaled based on the energy from the reference He value
        handles.settings.L059RF_F1_PHASE=-90;
        handles.settings.L059RF_F2_PHASE=90;
        handles.settings.L059RF_F1_AMPL=(.0007)*(.25/qovera);
        handles.settings.L059RF_F2_AMPL=(.000245)*(.25/qovera);
        
        %L060 Solenoid
        %Scaling from I to kG taken from reference spreadsheet
        handles.settings.L060SN=10*(.0019*machinedata.L060SN-.0035);
        
        %RFQ Parameters
        %Note: Like the MHB, these are NOT loaded from the machine
        %tune - the phase is set, and the amplitude scaled based
        %on the energy.
        handles.settings.RFQA=(.2/qovera)*100;
        handles.settings.RFQP=0.;
        
        %Linac Parameters
        %Once again, phases are not loaded.  However, cavity
        %amplitudes ARE loaded from the machine data. Will need
        %to be revisted when CM3 is installed.
        %Cavity Phases
        handles.settings.L077RF_PHASE=-90;
        handles.settings.L082RF_PHASE=-20;
        handles.settings.L084RF_PHASE=-20;
        handles.settings.L085RF_PHASE=-20;
        handles.settings.L088RF_PHASE=-20;
        handles.settings.L089RF_PHASE=-20;
        handles.settings.L091RF_PHASE=-20;
        handles.settings.L094RF_PHASE=-15;
        handles.settings.L097RF_PHASE=-15;
        handles.settings.L098RF_PHASE=-15;
        handles.settings.L100RF_PHASE=-15;
        handles.settings.L102RF_PHASE=-15;
        handles.settings.L104RF_PHASE=-15;
        handles.settings.L105RF_PHASE=-90;
        handles.settings.L108RF_PHASE=-90;
        %Cavity Amplitudes
        handles.settings.L077_AMPL=2.785*machinedata.L077RF_AMPL;
        handles.settings.L082_AMPL=4.31*machinedata.L082RF_AMPL;
        handles.settings.L084_AMPL=3.914*machinedata.L084RF_AMPL;
        handles.settings.L085_AMPL=4.607*machinedata.L085RF_AMPL;
        handles.settings.L088_AMPL=3.566*machinedata.L088RF_AMPL;
        handles.settings.L089_AMPL=3.376*machinedata.L089RF_AMPL;
        handles.settings.L091_AMPL=4.568*machinedata.L091RF_AMPL;
        handles.settings.L094_AMPL=2.18*machinedata.L094RF_AMPL;
        handles.settings.L097_AMPL=2.27*machinedata.L097_AMPL;
        handles.settings.L098_AMPL=1.675*machinedata.L098_AMPL;
        handles.settings.L100_AMPL=1.602*machinedata.L100_AMPL;
        handles.settings.L102_AMPL=1.829*machinedata.L102_AMPL;
        handles.settings.L104_AMPL=2.825*machinedata.L104_AMPL;
        handles.settings.L105_AMPL=1.445*machinedata.L105_AMPL;
        handles.settings.L108_AMPL=1.588*machinedata.L108_AMPL;
        %Solenoids
        handles.settings.L076SN=machinedata.L076SN/1.0541;
        handles.settings.L078SN=machinedata.L078SN/1.0541;
        handles.settings.L083SN=machinedata.L083SN/1.0541;
        handles.settings.L087SN=machinedata.L087SN/1.0541;
        handles.settings.L090SN=machinedata.L090SN/1.0541;
        handles.settings.L096SN=machinedata.L096SN/1.0541;
        handles.settings.L101SN=machinedata.L096SN/1.0541;
        handles.settings.L106SN=machinedata.L096SN/1.0541;
        
        %L-Line extension to target
        %Factor of -1 is to correct for an idiosyncracy of the control
        %system.
        handles.settings.Q_D1164=-1*danby(machinedata.PSQ_D1164);
        handles.settings.Q_D1169=danby(machinedata.PSQ_D1169);
        handles.settings.Q_D1174=-1*danby(machinedata.PSQ_D1174);
        handles.settings.Q_D1181=-1*danby(machinedata.PSQ_D1181);
        handles.settings.Q_D1186=danby(machinedata.PSQ_D1186);
        handles.settings.Q_D1192=-1*danby(machinedata.PSQ_D1192);
        handles.settings.Q_D1221=danby(machinedata.PSQ_D1221);
        handles.settings.Q_D1228=danby(machinedata.PSQ_D1228);
        handles.settings.Q_D1245=danby(machinedata.PSQ_D1245);
        handles.settings.Q_D1252=danby(machinedata.PSQ_D1252);
        handles.settings.Q_D1272=danby(machinedata.PSQ_D1272);
        handles.settings.Q_D1275=danby(machinedata.PSQ_D1275);
        handles.settings.Q_D1281=danby(machinedata.PSQ_D1281);
        handles.settings.Q_D1285=danby(machinedata.PSQ_D1285);
        handles.settings.Q_D1307=hebt(machinedata.PSQ_D1307);
        handles.settings.Q_D1310=hebt(machinedata.PSQ_D1310);
        handles.settings.Q_D1323=hebt(machinedata.PSQ_D1323);
        handles.settings.Q_D1327=hebt(machinedata.PSQ_D1327);
        handles.settings.Q_D1346=hebt(machinedata.PSQ_D1346);
        handles.settings.Q_D1351=hebt(machinedata.PSQ_D1351);
        handles.settings.Q_D1369=hebt(machinedata.PSQ_D1369);
        handles.settings.Q_D1388=hebt(machinedata.PSQ_D1388);
        handles.settings.Q_D1395=hebt(machinedata.PSQ_D1395);
        handles.settings.Q_D1411=hebt(machinedata.PSQ_D1411);
        handles.settings.Q_D1415=hebt(machinedata.PSQ_D1415);
        
        %Slits
        %Data in ROCS file is full width in mm.
        %Factor of 10 is for mm->cm
        handles.settings.L034XG=machinedata.L034XG/20.;
        handles.settings.L034YG=1000.; %Horizontal Slit Only
        handles.settings.L044XG=machinedata.L044XG/20.;
        handles.settings.L044YG=1000.;%Horizontal Slit Only
        handles.settings.L072XG=machinedata.L072XG/20.;
        handles.settings.L072YG=machinedata.L072YG/20.;
        handles.settings.SLHGAP_D1166=1000.; %Vertical Slit Only
        handles.settings.SLVGAP_D1166=machinedata.SLVGAP_D1166/10.;
        handles.settings.SLHGAP_D1256=machinedata.SLHGAP_D1256/10.;
        handles.settings.SLVGAP_D1256=machinedata.SLVGAP_D1256/10.;
        handles.settings.SLHGAP_D1316=machinedata.SLHGAP_D1316/10.;
        handles.settings.SLVGAP_D1316=1000.; %Horizontal Slit Only
        
        
        %Reset checkboxes to reflect tune has been loaded and 
        %generate new output file name.
        guidata(hObject,handles);
        set(loadtunes_checkbox,'Value',1);
        set(handles.gendeck_checkbox,'Value',0.0);
        set(handles.viewdeck_button,'Enable','off');
        set(handles.sr_menu,'Enable','off');
        set(handles.rundeck_checkbox,'Value',0.0);
        set(handles.longdist_checkbox,'Value',0.0);
        set(handles.settingsfile_inputbox,'String',handles.tunename);
        set(handles.outputdeck_inputbox,'String',[handles.tunename '.in']);
    end

    function setqafile(~,~)
        %Callback for first file dialogue.
        temp=get(qalinacfile_inputbox,'String');
        [qafilename,qapath,~]=uigetfile('ROCS Output\*.*');
        if isequal(qafilename,0)
            set(qalinacfile_inputbox,'String',temp)
        else
            set(qalinacfile_inputbox,'String',[qapath qafilename]);
            set(loadtunes_checkbox,'Value',0);
        end
    end

    function setlfile(~,~)
        %Callback for second file dialogue.
        temp=get(llinefile_inputbox,'String');
        [lfilename,lpath]=uigetfile('ROCS Output\*.*');
        if isequal(lfilename,0)
            set(llinefile_inputbox,'String',temp);
        else
            set(llinefile_inputbox,'String',[lpath lfilename]);
            set(loadtunes_checkbox,'Value',0);
        end
    end

    function scanfilename(filename)
        nameparts=regexp(filename,'_','split');
        handles.settings.A=str2double(nameparts{7}(1:3));
        set(handles.a_textbox,'String',handles.settings.A);
        handles.settings.Q=str2double(nameparts{7}(5:7));
        set(handles.q_textbox,'String',handles.settings.Q);
        handles.settings.Energy=handles.settings.A*.012;
        set(handles.energy_textbox,'String',handles.settings.Energy);
        handles.tunename=[nameparts{7} '_' nameparts{3} nameparts{4} nameparts{5}];
    end

    function field=danby(current)
        %Converts a current in amps to a field in kG for a 
        %Danby type quad
        field=.034958*(current)-3.264e-3;
    end

    function field=hebt(current)
        %Converts a current in amps to a field in kG for an
        %HEBT type quad
        field=.02842*(current)+.03591;
    end
end


function zplots_button_Callback(~, ~, handles) %#ok<DEFNU>
    %Plots data from the "dynac.print" file, consisting of envelope
    %and energy data.
    try    
        zdata=importdata('dynac.print');
    catch
        disperror('Error: Most likely missing dynac.print');
        return;
    end
    %Plot X envelope
    scrsz = get(0,'ScreenSize');
    plot_window=figure('Name','Z-Axis Plots','NumberTitle','Off',...
        'MenuBar','figure',...
        'Position',[scrsz(3)*.05 scrsz(4)*.30 scrsz(3)*.9 scrsz(4)*.60]);
    transaxes=axes('ActivePositionProperty','outerposition','Color','None');
    backgroundcolor=get(plot_window,'color');
    set(transaxes,'Position',[.05 .2 .9 .75]);
    xline=plot(transaxes,zdata.data(:,1),zdata.data(:,2),'Color','r');
    ylabel(transaxes,'1 RMS Half Width (mm)');
    set(transaxes,'color','none');
    box(transaxes,'off');
    
    %Plot Y envelope
    hold on;
    yline=plot(transaxes,zdata.data(:,1),-zdata.data(:,3),'Color','g');
    
    %Plot dashed line at x/y = 0
    plot(transaxes,[0,max(zdata.data(:,1))],[0,0],':k','LineWidth',.1);
    
    %Plot X beta function
    hold on;
    gamma=zdata.data(1,9)/handles.settings.A/931.494+1;
    relbeta=sqrt(1-1/gamma^2);
    xbeta=relbeta*zdata.data(:,2).*zdata.data(:,2)./zdata.data(:,6);
    xbetaline=plot(transaxes,zdata.data(:,1),xbeta,'Color','r');
    set(xbetaline,'Visible','off');
    
    %Plot Y beta function
    hold on;
    ybeta=relbeta*zdata.data(:,3).*zdata.data(:,3)./zdata.data(:,7);
    ybetaline=plot(transaxes,zdata.data(:,1),-ybeta,'Color','g');
    set(ybetaline,'Visible','off');
    
    %Plot X emittance
    hold on;
    xemitline=plot(transaxes,zdata.data(:,1),zdata.data(:,6),'Color','r');
    set(xemitline,'Visible','off');
    
    %Plot Y emittance
    hold on;
    yemitline=plot(transaxes,zdata.data(:,1),-zdata.data(:,7),'Color','g');
    set(yemitline,'Visible','off');
    
    %Plot Z emittance
    hold on;
    zemitline=plot(transaxes,zdata.data(:,1),zdata.data(:,8),'Color','k');
    set(zemitline,'Visible','off');

    if (size(zdata.data,2)>=10) %Fails for very old versions of dynac
    %Plot X Envelope
    hold on;
    xenvelopeline1=plot(transaxes,zdata.data(:,1),zdata.data(:,11),'Color','r');
    xenvelopeline2=plot(transaxes,zdata.data(:,1),zdata.data(:,12),'Color','r');
    set(xenvelopeline1,'Visible','off');
    set(xenvelopeline2,'Visible','off');
    
    %Plot Y Envelope
    hold on;
    yenvelopeline1=plot(transaxes,zdata.data(:,1),zdata.data(:,13),'Color','g');
    yenvelopeline2=plot(transaxes,zdata.data(:,1),zdata.data(:,14),'Color','g');
    set(yenvelopeline1,'Visible','off');
    set(yenvelopeline2,'Visible','off');
    
    %Plot Time Spread
    hold on;
    tspread=1e9*(zdata.data(:,16)-zdata.data(:,15));
    tspreadline=plot(transaxes,zdata.data(:,1),tspread,'Color','k');
    set(tspreadline,'Visible','off');
    
    %Plot Energy Spread
    hold on;
    maxdeltae=max(abs(zdata.data(:,19)),abs(zdata.data(:,20)));
    espread=100*(maxdeltae./zdata.data(:,9)); %Energy spread as a percentage
    espreadline=plot(transaxes,zdata.data(:,1),espread,'Color','k');
    set(espreadline,'Visible','off');
        
    else %Trap old versions of Dynac with less data in "dynac.print"
        nlines=4;
        nullline=zeros(length(zdata.data(:,1)));
        xenvelopeline1=plot(transaxes,zdata.data(:,1),nullline,'Color','k');
        xenvelopeline2=plot(transaxes,zdata.data(:,1),nullline,'Color','k');
        yenvelopeline1=plot(transaxes,zdata.data(:,1),nullline,'Color','k');
        yenvelopeline2=plot(transaxes,zdata.data(:,1),nullline,'Color','k');
        tspreadline=plot(transaxes,zdata.data(:,1),nullline,'Color','k');
        espreadline=plot(transaxes,zdata.data(:,1),nullline,'Color','k');
    end
        
    %Plot Dispersion
    if (size(zdata.data,2)>=21) %Only works with beta version that includes D
        hold on;
        xdispline=plot(transaxes,zdata.data(:,1),zdata.data(:,21),'Color','r');
        ydispline=plot(transaxes,zdata.data(:,1),zdata.data(:,22),'Color','g');
        set(xdispline,'Visible','off');      
        set(ydispline,'Visible','off');
        nlines=10;
    else %Fail gracefully
        nlines=8;
        nullline=zeros(length(zdata.data(:,1)));
        xdispline=plot(transaxes,zdata.data(:,1),nullline,'Color','r');
        ydispline=plot(transaxes,zdata.data(:,1),nullline,'Color','g');
    end
    
    %Plot energy on 2nd axis
    energyaxes=axes('Position',get(transaxes,'Position'),...
        'XaxisLocation','bottom','YAxisLocation','right',...
        'Color','none');
    eline=line(zdata.data(:,1),zdata.data(:,9),'Color','magenta',...
        'Parent',energyaxes);
    ylabel(energyaxes,'Energy [MeV]');
    
    %Set up axes for box labels.  This is the bottom axes, and contains
    %the global properties for the graph, such as background color and 
    %graph title.
    zmax=max(get(transaxes,'Xlim'));
    zmin=min(get(transaxes,'Xlim'));
    boxaxes=axes('Position',get(transaxes,'Position'),...
        'XaxisLocation','bottom','YAxisLocation','right',...
        'Visible','on','Xlim',[zmin zmax],...
        'Color','white','Ytick',[]);
    uistack(boxaxes,'bottom');
    box(boxaxes,'off');
    xlabel(boxaxes,'Z(m)');
    graphtitle=[strrep(get(handles.outputdeck_inputbox,'String'),'_','\_') ...
        ': A = ' num2str(handles.settings.A) ...
        ' Q = ' num2str(handles.settings.Q) ...
        ' N = ' num2str(handles.settings.Npart)];
    title(graphtitle,'FontSize',14);
    
    if handles.reaboxes==1
            %Plot Box Locations
            %These are hardcoded locations on the ReA line.  This code is
            %here for legacy support only.  Unless this is really needed,
            %better bet is to just use the built in functionality for
            %emittance plots.  To activate this option, put this line in the
            %dynacgui.inifile:
            % ReABoxes<tab>1
            %If ZOffset is defined in the tune file, that's the distance along the
            %beamline from L016 to the start of the plot.  Only needed for box
            %locations.
            try
                offset=handles.settings.ZOffset;
            catch
                offset=0;
            end
            Bbox(3)=13.531;
            Bbox(4)=17.338;
            Bbox(5)=19.487;
            Bbox(6)=23.008;
            Bbox(7)=28.204;
            Bbox(10)=31.393;
            Bbox(11)=34.341;
            Bbox(13)=39.444;
            Bbox(14)=42.486;
            Bbox(15)=45.585;
            Bbox(16)=49.119;
            %Uncomment for ANASEN line
            Bbox(17)=54.414; 
            Bbox(18)=55.778;
            %Uncomment for ATTPC line
            %Bbox(19)=56.310; 
            %Bbox(20)=57.460; %use 57.675 for second half of 20
            Bbox(23)=0;
            boxlinehandles=[];
            boxlabelhandles=[];
            h=line([8.314-offset 8.314-offset],ylim);
            boxlinehandles=[boxlinehandles h];
            h=text(8.314-offset,max(ylim),'L044 ','Rotation',90,...
                    'VerticalAlignment','Bottom','HorizontalAlignment','Right');
            boxlabelhandles=[boxlabelhandles h];
            for i=1:23
                if (Bbox(i) ~= 0)
                    h=line([Bbox(i)-offset Bbox(i)-offset],ylim);
                    boxlinehandles=[boxlinehandles h];
                    h=text(Bbox(i)-offset,max(ylim),['Box' num2str(i) ' '],...
                        'Rotation',90,'VerticalAlignment',...
                        'Bottom','HorizontalAlignment','Right');
                    boxlabelhandles=[boxlabelhandles h];
                end
            end

            %Edit "tposition" depending on beamline. Set to 0 for no target.
            %59.61 = ATTPC Target location
            %57.71 = ANASEN Target location
            tposition = 57.71;
            if (tposition ~= 0)
                h=line([tposition tposition],ylim);
                boxlinehandles=[boxlinehandles h];
                h=text(tposition,max(ylim),'Target ','Rotation',90,...
                    'VerticalAlignment','Bottom','HorizontalAlignment','Right');
                boxlabelhandles=[boxlabelhandles h];
            end
    end
            
    %Add lines for emittance plots
    %(Perhaps add to the list any EMITL cards?)
    ud=get(handles.generatedgraphs_listbox,'Userdata');
    plotlinehandles=[];
    plotlabelhandles=[];
    if isstruct(ud) && isfield(ud,'plotzpos') && ~isempty(ud.plotzpos)
        for i=1:length(ud.plotzpos);
            if ~isempty(ud.plotzpos{i})
                h=line([ud.plotzpos{i} ud.plotzpos{i}],ylim,'Color','k');
                plotlinehandles=[plotlinehandles h];
                h=text(ud.plotzpos{i},max(ylim),ud.names{i},...
                    'Rotation',90,'VerticalAlignment',...
                    'Bottom','HorizontalAlignment','Right');
                plotlabelhandles=[plotlabelhandles h];
            end
        end
    end

    %Plot element type graphics along axis
    for j=1:length(ud.devarray.end);
        devlinewidth=5;
        line([ud.devarray.end(j)-ud.devarray.length(j) ud.devarray.end(j)],...
            [ud.devarray.offset(j)/devlinewidth,ud.devarray.offset(j)/devlinewidth],...
            'Color',ud.devarray.color(j),'LineWidth',devlinewidth,'Parent',transaxes);
    end
    
    %setup axes for particle number counts
    if (size(zdata.data,2)>=10) %Fails on very old versions of Dynac
        particleaxes=axes('Position',get(transaxes,'Position'),...
        'XaxisLocation','bottom','YAxisLocation','right',...
        'Visible','off','Xlim',[zmin zmax],'Ylim',[0 1],...
        'Color','none','Ytick',[]);
         pline=line(zdata.data(:,1),zdata.data(:,10)/max(zdata.data(:,10)),...
            'Color','blue','Parent',particleaxes);
        %Displays particle count
        % This line is the particle count at the end of the line
        % and should be properly general.
        pcount=sprintf('Particles left at end: %g / %g\r\n',...
            zdata.data(length(zdata.data(:,1)),10),zdata.data(1,10));
        text(0,0,pcount);
        particles_checkbox=uicontrol(plot_window,...
            'Style','checkbox','String','Particle Count',...
            'Position',[375 20 150 30],'BackgroundColor',backgroundcolor,...
            'FontSize',12,'Max',1,'Value',1,'callback',@toggle_particles);
    end
    
    %setup check boxes    
    energy_checkbox=uicontrol(plot_window,...
        'Style','checkbox','String','Energy Plot',...
        'Position',[250 20 100 30],'BackgroundColor',backgroundcolor,...
        'FontSize',12,'Max',1,'Value',1,'callback',@toggle_energy);
    
    plotlabel_checkbox=uicontrol(plot_window,...
        'Style','checkbox','String','Emit. Plots',...
        'Position',[525 20 100 30],'BackgroundColor',backgroundcolor,...
        'FontSize',12,'Max',1,'Value',0,'callback',@toggle_plotlabel);
    if isempty(plotlinehandles) 
        set(plotlabel_checkbox,'Visible','off');
    else
        set(plotlabel_checkbox,'Visible','on');
    end
    toggle_plotlabel;
    
    if handles.reaboxes==1;
    boxlabel_checkbox=uicontrol(plot_window,...
        'Style','checkbox','String','ReA3 Boxes',...
        'Position',[1060 20 200 30],'BackgroundColor',backgroundcolor,...
        'FontSize',12,'Max',1,'Value',0,'callback',@toggle_boxlabel);
    toggle_boxlabel;
    end
    
%    beta_checkbox=uicontrol(plot_window,...
%        'Style','checkbox','String','Beta Functions',...
%        'Position',[960 20 200 30],'BackgroundColor',backgroundcolor,...
%        'FontSize',12,'Max',1,'Value',0,'callback',@toggle_beta);
%    toggle_beta;

    if nlines==10
        zplotnames={'X/Y Profile',...
        'X/Y Emittance','Z Emittance','X/Y Beta Functions','X Envelope',...
        'Y Envelope','Time Spread','Energy Spread','X Dispersion','Y Dispersion',...
        'None'};
    elseif nlines==8
        zplotnames={'X/Y Profile',...
        'X/Y Emittance','Z Emittance','X/Y Beta Functions','X Envelope',...
        'Y Envelope','Time Spread','Energy Spread','None'};
    else
        zplotnames={'X/Y Profile','X/Y Emittance','Z Emittance',...
            'X/Y Beta Functions','None'};
    end
    
    uicontrol(plot_window,...
        'Style','popupmenu','String',zplotnames,...
        'Position',[20 20 200 30],'BackgroundColor','white',...
        'FontSize',12,'Value',1,'callback',@dropdown_callback);
    
    %setup limit text boxes
    uicontrol(plot_window,...
        'Style','edit','String',num2str(zmin),'Position',[650 25 50 20],...
        'FontSize',10,'callback',@change_min);
    uicontrol(plot_window,'Style','text','String','Start Position (m)',...
        'Position',[690 25 150 20],'FontSize',12,...
        'BackgroundColor',backgroundcolor);
    uicontrol(plot_window,...
        'Style','edit','String',num2str(zmax),...
        'Position',[850 25 50 20],'FontSize',10,...
        'callback',@change_max);
    uicontrol(plot_window,'Style','text','String','End Position (m)',...
        'Position',[890 25 150 20],'FontSize',12,...
        'BackgroundColor',backgroundcolor);
    
    %Graph Legend
    leg=legend([xline yline zemitline eline pline],...
        'X','Y','Z','Energy','Particle Count','Location','Southeast');
    set(leg,'Color','none');
    
    function dropdown_callback(src,~)
        graphtype=get(src,'Value');
        if graphtype>nlines
            graphtype=99;
        end
        yaxislabel=get(transaxes,'ylabel');
        set(xline,'Visible','off')
        set(yline,'Visible','off')
        set(xbetaline,'Visible','off')
        set(ybetaline,'Visible','off')
        set(xemitline,'Visible','off')
        set(yemitline,'Visible','off')
        set(zemitline,'Visible','off')
        set(xenvelopeline1,'Visible','off');
        set(xenvelopeline2,'Visible','off');
        set(yenvelopeline1,'Visible','off');
        set(yenvelopeline2,'Visible','off');
        set(tspreadline,'Visible','off');
        set(espreadline,'Visible','off');
        set(xdispline,'Visible','off');
        set(ydispline,'Visible','off');
        set(transaxes,'YTickMode','auto')
        switch graphtype
            case 1 %X/Y Envelope Plot
                set(xline,'LineStyle','-');
                set(yline,'LineStyle','-');
                set(xline,'Visible','on');
                set(yline,'Visible','on');
                set(yaxislabel,'String','1 RMS Half Width [mm]');
            case 2 %X/Y Emittance Plot
                set(xemitline,'Visible','on');
                set(yemitline,'Visible','on');
                set(yaxislabel,'String',...
                    'X/Y Emittance [mm.mrad - 1 RMS Normalized]')
            case 3 %Z Emittance Plot
                set(zemitline,'Visible','on');
                set(yaxislabel,'String','Z Emittance [keV.ns - 4 RMS]')
            case 4 %Beta Function Plot
                set(xbetaline,'Visible','on');
                set(ybetaline,'Visible','on');
                set(yaxislabel,'String','X/Y Beta Function [mm/mrad]');
            case 5 % X Envelope Plot
                set(xenvelopeline1,'Visible','on');
                set(xenvelopeline2,'Visible','on');
                set(xline,'Visible','on');
                set(xline,'LineStyle',':');
                set(yaxislabel,'String','X Envelope [mm]');
            case 6 % Y Envelope Plot
                set(yenvelopeline1,'Visible','on');
                set(yenvelopeline2,'Visible','on');
                set(yline,'Visible','on');
                set(yline,'LineStyle',':');
                set(yaxislabel,'String','Y Envelope [mm]');                
            case 7 % Time Spread
                set(tspreadline,'Visible','on');
                set(yaxislabel,'String','Time Spread [ns]');
            case 8 % Energy Spread
                set(espreadline,'Visible','on');
                set(yaxislabel,'String','Delta E / E [%]');
            case 9 % X Dispersion
                set(xline,'Visible','on');
                set(xline,'LineStyle',':');
                set(xdispline,'Visible','on');
                set(yaxislabel,'String','x / (dp / p) [m]');
            case 10
                set(yline,'Visible','on');
                set(yline,'LineStyle',':');
                set(ydispline,'Visible','on');
                set(yaxislabel,'String','y / (dp / p) [m]'); 
            case 99 %None of the above
                set(yaxislabel,'String','');
                set(transaxes,'Ytick',[]);
        end
    end
    function toggle_energy(~,~)
        %Toggles Display of energy plot
        if (get(energy_checkbox,'Value')==0)
            set(eline,'Visible','off');
            set(energyaxes,'Visible','off');
        else
            set(eline,'Visible','on');
            set(energyaxes,'Visible','on');
        end
    end
    function toggle_xyplot(~,~) %#ok<DEFNU>
        %Toggles display of profile graph
        if (get(xy_checkbox,'Value')==0)
            set(xline,'Visible','off');
            set(yline,'Visible','off');
            set(transaxes,'Visible','off');
        else
            set(xline,'Visible','on');
            set(yline,'Visible','on');
            set(transaxes,'Visible','on');
        end
    end
    function toggle_boxlabel(~,~)
        %Toggles dipslay of box positions
        if (get(boxlabel_checkbox,'Value')==0)
            set(boxlinehandles,'Visible','off');
            set(boxlabelhandles,'Visible','off');
        else
            set(boxlinehandles,'Visible','on');
            set(boxlabelhandles,'Visible','on');
        end
    end
    function toggle_plotlabel(~,~)
        %Toggles display of plot positions
        if (get(plotlabel_checkbox,'Value')==0)
            set(plotlabelhandles,'Visible','off');
            set(plotlinehandles,'Visible','off');
        else
            set(plotlabelhandles,'Visible','on');
            set(plotlinehandles,'Visible','on');
        end
    end
    function toggle_particles(~,~)
        %Toggles dipslay of particle count
        if (get(particles_checkbox,'Value')==0)
            set(pline,'Visible','off');
        else
            set(pline,'Visible','on');
        end
    end
    function toggle_beta(~,~) %#ok<DEFNU>
        %Toggles display of beta functions
        if(get(beta_checkbox,'Value')==0)
            set(xbetaline,'Visible','off');
            set(ybetaline,'Visible','off');
        else
            set(xbetaline,'Visible','on');
            set(ybetaline,'Visible','on');
        end
    end
    function change_max(src,~)
        %changes max of z axis
        val=str2double(get(src,'String'));
        if (val<min(xlim(transaxes)))
            set(src,'String',num2str(max(xlim(transaxes)))); 
        elseif (val<zmax)
            xlim(transaxes,[min(xlim(transaxes)) val]);
            xlim(energyaxes,[min(xlim(energyaxes)) val]);
            xlim(boxaxes,[min(xlim(boxaxes)) val]);
            xlim(particleaxes,[min(xlim(particleaxes)) val]);
        else
            set(src,'String',num2str(zmax));
            xlim(transaxes,[min(xlim(transaxes)) zmax]);
            xlim(energyaxes,[min(xlim(energyaxes)) zmax]);
            xlim(boxaxes,[min(xlim(boxaxes)) zmax]);
            xlim(particleaxes,[min(xlim(particleaxes)) zmax]);
        end           
    end
    function change_min(src,~)
        %changes min of z axis
        val=str2double(get(src,'String'));
        if (val>max(xlim(transaxes)))
            set(src,'String',num2str(min(xlim(transaxes)))); 
        elseif (val>zmin)
            xlim(transaxes,[val max(xlim(transaxes))]);
            xlim(energyaxes,[val max(xlim(energyaxes))]);
            xlim(boxaxes,[val max(xlim(boxaxes))]);
            xlim(particleaxes,[val max(xlim(particleaxes))]);
        else
            set(src,'String',num2str(zmin));
            xlim(transaxes,[zmin max(xlim(transaxes))]);
            xlim(energyaxes,[zmin max(xlim(energyaxes))]);
            xlim(boxaxes,[zmin max(xlim(boxaxes))]);
            xlim(particleaxes,[zmin max(xlim(particleaxes))]);
        end           
     end

end


function figure1_DeleteFcn(~, ~, ~) %#ok<DEFNU>
    close(get(0,'children'));
end


function generatedgraphs_listbox_Callback(hObject, ~, handles) %#ok<DEFNU>
    selection=get(hObject,'Value');
    ud=get(handles.generatedgraphs_listbox,'UserData');    
    %plotlist=cellstr(get(hObject,'String'));     
    plotloc=ud.plotloc;
    emitplot(ud.freqlist,plotloc(selection),selection);  
end

function generatedgraphs_listbox_CreateFcn(hObject, ~, ~) %#ok<DEFNU>

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function writetune_button_Callback(~, ~, handles) %#ok<DEFNU>
%Calls writetune.m to build output deck
temp=get(handles.settingsfile_inputbox,'String');
[settingsfile,settingsfilepath,~]=uiputfile(['Tune Settings' filesep '*.*'],...
    'Name Saved Tune File',temp);

if isequal(settingsfile,0)
    %If cancelled, do nothing
else
    writetune(settingsfile,settingsfilepath,handles.settings);
    set(handles.settingsfile_inputbox,'String',[settingsfilepath settingsfile]);
    %name output file after input file with *.in extension
    outputfile=regexprep(settingsfile,'\.[^.]+$','.in');
    set (handles.outputdeck_inputbox,'String',outputfile);
end

end

function writetune(settingsfile,settingsfilepath,settings)
% Writes the current tune settings to a file readable by DynacGUI

outfile=fopen([settingsfilepath settingsfile],'w');

%extract values from settings structure
fields = repmat(fieldnames(settings), numel(settings), 1);
values = struct2cell(settings);

%Convert numerical values to strings
idx = cellfun(@isnumeric, values); 
values(idx) = cellfun(@num2str, values(idx), 'UniformOutput', 0);

%Combine field names and values in the same array
C = {fields{:}; values{:}};

%Write fields to file
for row=1:size(C,2)
    fprintf(outfile, '%s\t%s\r\n', C{1,row}, C{2,row});
end

fclose all;
end


function runlongdist_button_Callback(hObject, eventdata, handles) %#ok<DEFNU>
%Transports a distribution longer than one RF period through a beamline
%containing an RFQ.  Since this involves chopping up the distribution at
%the RFQ entrance and running each slice through, the output files will be
%a bit screwed up.  The emittance plots and overall envelope should be OK.

set(handles.runlongdist_button,'ForegroundColor',[1 0 0],'String','Running');

%Check for scratch directory, create it if it doesn't exist.
if ~isdir('dynacscratch')
    try
        mkdir('dynacscratch');
    catch
        disp('Unable to create scratch directory');
        return;
    end
end
if ispc
    sdir=('dynacscratch\');
else
    sdir=('dynacscratch/');
end

%Build output deck up to RFQ, if present
outputfilename = get(handles.outputdeck_inputbox,'String');
fileroot = strrep(outputfilename,'.in','');
outputfilename1= [sdir fileroot '_1.in'];
%tunefilename=get(handles.settingsfile_inputbox,'String');
if isempty(get(handles.a_textbox,'String'))
    populate_data(hObject, eventdata,handles);
    handles=guidata(handles.output);
end
layoutfilename = get(handles.layoutfile_inputbox,'String');
devicefilename = get(handles.devicefile_inputbox,'String');

%Longdist = 1 signals to gendeck.m that this is going to be broken
%up through the RFQ.
handles.settings=setfield(handles.settings,'longdist',1);

%Generate the first part of the deck
[handles.settings,freqlist]=gendeck(outputfilename1,handles.settings,...
    layoutfilename,devicefilename);
ud=get(handles.generatedgraphs_listbox,'UserData');
ud.freqlist=freqlist;
set(handles.generatedgraphs_listbox,'UserData',ud);
%If gendeck encounters an RFQ, longdist will be reset to 0
if handles.settings.longdist==1;
    disp('No RFQ Present!')%eventually, replace with running the deck
    set(handles.runlongdist_button,'ForegroundColor',[0 0 0],'String','Gen/Run for t>tRFQ');
    return
end

%Run part 1 & dump dist
    cd(sdir);
    
    if (get(handles.mingw_checkbox,'Value')==1)
        command=['dynacv6_0 -mingw ' [fileroot '_1.in']];
    else
        command=['dynacv6_0 ' [fileroot '_1.in']];
    end
    [~,dynacoutput]=system(command);
    set(handles.dynac_output_textbox,'String',dynacoutput);
    movefile('dynac.print','dynac.print_1'); %save first dynac.print
    movefile('emit.plot','emit.plot_1');
    cd ('..');
    
%Generate rfq decks and distribution files 

%Get starting parameters
dstfile=[sdir fileroot '_1.dst'];
rfqfreq=str2double(handles.settings.rfqfreq);
rfqenergy=str2double(handles.settings.rfqenergy);
rfqcells=handles.settings.rfqcells;
rfqfilename=handles.settings.rfqfile;
if ispc
    rfqfilename=['..\' rfqfilename];
else
    rfqfilename=['../' rfqfilename];
end

%Split the input file into RFQ periods. Nfiles = number of files
[nfiles,~,refcharge]=splitdst(dstfile,rfqfreq); 
qovera=refcharge/handles.settings.A;

%Generate and run RFQ decks
cd(sdir);
for i=1:nfiles
    %Setup parameters and create the Dynac deck for each file
    distfilename=[fileroot '_1_' num2str(i) '.dst'];
    deckfilename=[fileroot '_2_' num2str(i) '.in'];
    outdistname=[fileroot '_2_' num2str(i) '.dst'];
    deckfile=fopen(deckfilename,'w');
    %Dynac deck sections
    %Name
    fprintf(deckfile,';RFQ deck for %s\r\n',distfilename);
    %Read Distribution
    fprintf(deckfile,'%s\r\n','RDBEAM');%Read Beam Command
    fprintf(deckfile,'%s\r\n',distfilename);%Distribution File Name
    fprintf(deckfile,'%s\r\n','2'); %flag for including charge state
    fprintf(deckfile,'%s 0\r\n',num2str(rfqfreq));%frequency / phase
    fprintf(deckfile,'931.494 %g\r\n',handles.settings.A);%AMU / Mass
    fprintf(deckfile,'%g %g\r\n',handles.settings.Energy,refcharge);%Energy / Charge
    %Pre RFQ Silliness
    fprintf(deckfile,'%s\r\n','REFCOG');
    fprintf(deckfile,'1\r\n');
    fprintf(deckfile,'NREF\r\n');
    param2=(handles.settings.A*rfqenergy-handles.settings.Energy);
    fprintf(deckfile,'%s %g %s %s\r\n','0',param2,'0','1');
    %The RFQ itself
    fprintf(deckfile,'RFQPTQ\r\n');
    fprintf(deckfile,'%s\r\n',rfqfilename);
    fprintf(deckfile,'%s\r\n',rfqcells);
    rfqamp=(.2/qovera)*100;
    fprintf(deckfile,'%g %g %g %s\r\n',rfqamp-100,rfqamp-100,0,'180');
    %Post RFQ Silliness
    fprintf(deckfile,'REFCOG\r\n');
    fprintf(deckfile,'0\r\n');
    %Write output distribution
    fprintf(deckfile,'WRBEAM\r\n');
    fprintf(deckfile,'%s\r\n',outdistname);
    fprintf(deckfile,'1 2\r\n');
    fprintf(deckfile,'STOP');
    %Close deck file
    fclose(deckfile);
    
    %Run each Dynac deck
    if (get(handles.mingw_checkbox,'Value')==1)
        command=['dynacv6_0 -mingw ' deckfilename];
    else
        command=['dynacv6_0 ' deckfilename];
    end
    [~,dynacoutput]=system(command);
    set(handles.dynac_output_textbox,'String',dynacoutput);
    
    try
        pcount=dlmread('dynac.print','',1,9);
    catch
        pcount=0;
    end
    
    if exist('rfqptotal','var')
        rfqptotal=rfqptotal+pcount;
    else
        rfqptotal=pcount;
    end
    
    if i==(ceil(nfiles/2)) %Save the dynac.print for the middle file
        movefile('dynac.print','dynac.print_2');
    end
end
cd('..');

%join distributions, store the mean energy of the final distribution
refenergy=joindst([fileroot '_2'],nfiles);
handles.settings=setfield(handles.settings,'refenergy',refenergy);

%Generate and run post RFQ deck
%signal to gendeck that we are post-rfq
handles.settings.longdist=2;
outputfilename2= [sdir fileroot '_3.in'];
distfilename=[fileroot '_2.dst'];

%Generate part 3 deck
[handles.settings,freqlist]=gendeck(outputfilename2,handles.settings,...
    layoutfilename,devicefilename,distfilename);
ud=get(handles.generatedgraphs_listbox,'UserData');
ud.freqlist=[ud.freqlist freqlist];
set(handles.generatedgraphs_listbox,'UserData',ud);

%Run part 3
cd(sdir);    
    if (get(handles.mingw_checkbox,'Value')==1)
        command=['dynacv6_0 -mingw ' [fileroot '_3.in']];
    else
        command=['dynacv6_0 ' [fileroot '_3.in']];
    end
    [~,dynacoutput]=system(command);
    set(handles.dynac_output_textbox,'String',dynacoutput);
    movefile('dynac.print','dynac.print_3');
    movefile('emit.plot','emit.plot_3');
    
cd ('..');

%Deal with dynac.print files
print1=dlmread('dynacscratch\dynac.print_1','',1,0);
print2=dlmread('dynacscratch\dynac.print_2','',1,0);
print2(:,10)=rfqptotal-nfiles; %total pcount from all files
print3=dlmread('dynacscratch\dynac.print_3','',1,0);
z1=print1(length(print1(:,1)),1);
z2=print2(length(print2(:,1)),1);
print1(length(print1(:,1)),:)=[];%remove last row from file 1
print2(length(print2(:,1)),:)=[];%remove last row from file 2
print2(:,1)=print2(:,1)+z1;
print3(:,1)=print3(:,1)+z1+z2;
print1=[print1;print2;print3];
printfile=fopen('dynac.print','w');%remove the dir soon
fprintf(printfile,'%s%s%s%s\r\n','       l(m)         x(mm)    ',...
    '     y(mm)          z(deg)        z(mm)  ',...
    '    emx(mm.mrd)  emy(mm.mrd)   ',...
    'emz(KeV.ns)   energy(MeV)    #particles');
fmtstr=[repmat('  %12.5E',1,10) '\r\n'];
fprintf(printfile,fmtstr,print1');
fclose(printfile);

%Deal with plots
if ispc
    system('type dynacscratch\emit.plot_1 dynacscratch\emit.plot_3 >emit.plot');
else
    system('cat dynacscratch/emit.plot_1 dynacscratch/emit.plot_3 >emit.plot');
end
ud=get(handles.generatedgraphs_listbox,'UserData');
[plotlist,ud.plotloc,ud.names,ud.plotzpos]=scanemitplot(ud.freqlist,handles);
set(handles.generatedgraphs_listbox,'String',plotlist);
set(handles.generatedgraphs_listbox,'UserData',ud);

clear rfqptotal;
handles.settings=setfield(handles.settings,'longdist',0);
set(handles.runlongdist_button,'ForegroundColor',[0 0 0],'String','Gen/Run for t>tRFQ');
set(handles.rundeck_checkbox,'Value',0.0);
set(handles.longdist_checkbox,'Value',1.0);
set(handles.sr_menu,'Enable','on');
set(handles.zplots_button,'Enable','on');
guidata(hObject,handles);
end

function [plotlist,plotloc,shortnames,plotzpos]=scanemitplot(freqlist,handles)
%Scans through the emit.plot file and returns the list of available
%plots,their locations in the file, short names, and z positions

    plotlist=[];
    plotloc=[];
    plotzpos={};
    shortnames=[]; %List of short names for emittance plots
    if isempty(freqlist)
    else
        try
           plotfile=fopen('emit.plot');
        catch
           disperror('Error: Unable to open emit.plot');
           return;
        end


        i=1;
        while ~feof(plotfile) %For each line in the emit.plot file
            line=fgetl(plotfile); %retrieve the line
            if (line==-1) %If it's a -1, quit
                break;
            end
            if regexp(line,'^\s{10,11}\d{1,2}')==1 
                %If column eleven or twelve is one or two digits
                plottype=str2num(line(11:12)); %Set the plot type to the value
                if plottype==6 %Multi charge state plot (Always an emittance plot)
                    temp=ftell(plotfile)-14;
                    dummy=fgetl(plotfile);
                    dummy=fgetl(plotfile);
                    plotname=fgetl(plotfile);
                    if(regexp(plotname,'\d{15}'))
                        continue
                    end
                    plotloc=[plotloc temp]; %Add the plot location to the list
                    sname=plotname;
                    plotname=[' Emittance Plot: ' strtrim(plotname)...
                        ' - ' num2str(freqlist(i)*10^-6) 'MHz'];
                    i=i+1;
                elseif plottype==11 %Zone Plot
                    temp=ftell(plotfile)-14;
                    dummy=fgetl(plotfile);
                    dummy=fgetl(plotfile);
                    plotname=fgetl(plotfile);
                    plotloc=[plotloc temp]; %Add plot location to the list
                    sname=plotname;
                    plotname=[' Zone Plot: ' strtrim(plotname)...
                        ' - ' num2str(freqlist(i)*10^-6) 'MHz'];
                    i=i+1;
                else %Not multi charge state plot
                    temp=ftell(plotfile)-14;
                    plotname=fgetl(plotfile);
                    if(regexp(plotname,'\d{15}'))
                        continue
                    end
                    plotloc=[plotloc temp]; %Add the plot location to the list                
                    if (plottype==1) %If this is an emittance plot, edit the name
                        sname=plotname;
                        plotname=[' Emittance Plot: ' strtrim(plotname)...
                            ' - ' num2str(freqlist(i)*10^-6) 'MHz'];
                        i=i+1; 
                    else
                        sname='-';
                    end
                end
                if (isempty(plotlist)) %Append plotname to plotlist
                    plotlist=plotname;
                    shortnames{1}=strtrim(sname);
                else
                    plotlist=char(plotlist,plotname);
                    shortnames{length(shortnames)+1}=strtrim(sname);
                end

            end
        end
        fclose(plotfile);
    end
    
    
    %Scan through 'dynac.short' to find plot z-positions
    dsfile=fopen('dynac.short');
    zpos=0;
    nextline=fgetl(dsfile);
    
    devarray=[]; %Structure array containing positions and types of devices
    i=1;
    while ~feof(dsfile)
        %Store running z position in zpos for lines starting with position
        runpos=regexp(nextline,'^\s*(?<zpos>\d*\.*\d*) mm\s*(?<type>\w*).*(?:length|trajectory):?\s*=*\s*(?<length>\d*\.*\d*E?[+-]?\d*)','names'); 
        if ~isempty(runpos)
            zpos=str2double(runpos.zpos)*.001; %convert to m
            devarray.offset(i)=0;
            %Store start, length, type, and color code for each device listed
            switch runpos.type 
                case 'Quadrupole'
                    devarray.type(i)='Q';                  
                    devarray.color(i)='g';
                    devarray.offset(i)=1;
                    valueline=fgetl(dsfile);
                    sign=regexp(valueline,'^\s*(voltage|field)\s=\s*(?<sign>-)','once');
                    if ~isempty(sign);
                        devarray.offset(i)=-1;
                    end
                case 'bending'
                    devarray.type(i)='B';
                    devarray.color(i)='b';
                case 'Deflector'
                    devarray.type(i)='B';
                    devarray.color(i)='b';
                case 'Solenoid'
                    devarray.type(i)='S';
                    devarray.color(i)='c';
                case 'rfq'
                    devarray.type(i)='R';
                    devarray.color(i)='r';
                case 'Cavity'
                    devarray.type(i)='C';
                    devarray.color(i)='r';                                  
            end
            if ~strcmp(runpos.type,'Drift')
                devarray.end(i)=zpos;
                devarray.length(i)=str2double(runpos.length)*.001; %mm->m
                i=i+1;
            end
        end
        %If current line matches a stored short name...
        if ~isempty(find(strcmp(shortnames,strtrim(nextline)), 1))
            %add the position to the appropriate index in plotzpos
            plotzpos{find(strcmp(shortnames,strtrim(nextline)),1)}=zpos;
        end
        nextline=fgetl(dsfile);
    end
    
    fclose(dsfile);
    
    ud=get(handles.generatedgraphs_listbox,'UserData');
    ud.plotlist=plotlist;
    ud.plotloc=plotloc;
    ud.names=shortnames;
    ud.plotzpos=plotzpos;
    ud.devarray=devarray;
    set(handles.generatedgraphs_listbox,'UserData',ud);
    guidata(gcbf,handles);
    
end


function longdist_checkbox_Callback(~, ~, ~) %#ok<DEFNU>
%Callback for the "Current" checkbox for the t>tRFQ button.  Does nothing,
%click away.
end


function pdfile_checkbox_Callback(~, ~, handles) %#ok<DEFNU>
%Toggles whether or not an external particle distribution file will be
%used.
    if get(handles.pdfile_checkbox,'Value')==1;
        set(handles.pdfile_button,'Enable','on');
        set(handles.pdfile_button,'ForegroundColor','Black');
        set(handles.pdfile_inputbox,'ForegroundColor','Black');
        set(handles.pdfile_inputbox,'BackgroundColor','White');
    else
        set(handles.pdfile_button,'Enable','off');
        set(handles.pdfile_button,'ForegroundColor',[.502 .502 .502]);
        set(handles.pdfile_inputbox,'ForegroundColor',[.502 .502 .502]);
        set(handles.pdfile_inputbox,'BackgroundColor',[.973 .973 .973]);
    end
end


function pdfile_button_Callback(~, ~, handles) %#ok<DEFNU>
%Specifies external particle distribution file. If "Cancel" is selected,
%resets previous value.

    temp=get(handles.pdfile_inputbox,'String');
    
    if ispc
        [pdfile,pdpath,~]=uigetfile('Particle Distributions\*.*');
    else
        [pdfile,pdpath,~]=uigetfile('Particle Distributions/*.*');
    end
    
    if isequal(pdfile,0) %If "Cancel" is selected
        pdfile=temp;
        set (handles.pdfile_inputbox,'String',pdfile);
    else
        set (handles.pdfile_inputbox,'String',[pdpath pdfile]);
        %Indicate that a particle distribution has been selected
        set(handles.pdfile_inputbox,'Userdata',1);
        %Reset Checkboxes
        set(handles.gendeck_checkbox,'Value',0.0);
        set(handles.viewdeck_button,'Enable','off');
        set(handles.sr_menu,'Enable','off');
        set(handles.rundeck_checkbox,'Value',0.0);
        set(handles.longdist_checkbox,'Value',0.0);
    end
end


function clearoutput_button_Callback(~, ~, handles) %#ok<DEFNU>
set(handles.dynac_output_textbox,'String','');
end

function viewdeck_button_Callback(~, ~, handles) %#ok<DEFNU>
%Displays currently generated deck.
%Original code stolen from:
%http://www.mathworks.com/matlabcentral/answers/19553-display-window-for-text-file
deckfile=get(handles.outputdeck_inputbox,'String');

f = figure('menu','none','toolbar','none','Name',deckfile,'NumberTitle','Off');
fid = fopen(deckfile);
%ph = uipanel(f,'Units','normalized','position',[0.4 0.3 0.5 0.5],'title',...
%    deckfile);
ph = uipanel(f,'Units','normalized','position',[0.05 0.05 0.9 0.9],...
    'BorderType','none');
lbh = uicontrol(ph,'style','listbox','Units','normalized','position',...
    [0 0 1 1],'FontSize',9);

indic = 1;
while 1
     tline = fgetl(fid);
     if ~ischar(tline), 
         break
     end
     strings{indic}=tline;  %#ok<AGROW>
     indic = indic + 1;
end
fclose(fid);
set(lbh,'string',strings);
set(lbh,'Value',1);
set(lbh,'Selected','on');

end

function disperror(errortext)
figtag = 'DynacGUI';
guifig = findobj(allchild(0), 'flat','Tag', figtag);
guihand = guidata(guifig);
set(guihand.dynac_output_textbox,'String',errortext);
end

function plotdst(~,~,~)
%Plot an arbitrary distribution file

%[dstfile,dstfpath,~]=uigetfile(['Particle Distributions' filesep '*.dst']);
dst=getdst;

    if isequal(dst.file,0)
    %selection cancelled
        return
    end


eaxtype='pct'; 
paxtype='ns'; 
dst2={};

%Generate the figure
plots.fh=figure('Renderer','Painter','Name',dst.file);
            
    %Generate the X X' plot
    plots.xx=subplot(2,2,1);
        plot(dst.x,dst.xp,'r.','MarkerSize',3);
        title('Horizontal Phase Space');
        xlabel('X (cm)');
        ylabel('Px (mrad)');
        grid on;
        dstxlim=xlim;
        dstxplim=ylim;
    %Generate the Y Y' plot
    plots.yy=subplot(2,2,2);
        plot(dst.y,dst.yp,'r.','MarkerSize',3);
        title('Vertical Phase Space');
        xlabel('Y (cm)');
        ylabel('Py (mrad)');
        grid on;
    %Generate the realspace plot, with profiles
    plots.xy=subplot(2,2,3);
        plot(dst.x,dst.y,'r.','MarkerSize',3);
        title('Real Space');
        xlabel('X (cm)');
        ylabel('Y (cm)');
        grid on;
        hold on;
        dstxlim=xlim;
        dstylim=ylim;
        %Add histograms and widths
        [xelements,xcenters]=hist(dst.x,30);
        [yelements,ycenters]=hist(dst.y,30);
        xyxhist=plot(xcenters,(xelements/max(xelements))*0.25*(dstylim(2)-dstylim(1))+dstylim(1));
        xyyhist=plot((yelements/max(yelements))*0.25*(dstxlim(2)-dstxlim(1))+dstxlim(1),ycenters);
        profiletext=sprintf('X \\sigma = %g\nY \\sigma = %g',std(dst.x),std(dst.y));
        dstxlim=xlim;
        dstylim=ylim;
        xyt=text(dstxlim(2),dstylim(2),profiletext,'HorizontalAlignment','right',...
            'VerticalAlignment','top','FontSize',8);
        hold off;
    %Generate the phase/energy plot
    plots.te=subplot(2,2,4);
        tep=plot(dst.phase,dst.pctenergy,'r.','MarkerSize',3);
        teaxes=gca;
        title('Longitudinal Phase Space');
        paxislabel=xlabel('Time (ns)');
        set (paxislabel,'ButtonDownFcn',{@changepaxis});
        eaxislabel=ylabel('Rel. Energy dE/E %');
        set (eaxislabel,'ButtonDownFcn',{@changeeaxis});
        grid on;
        hold on;
        dstplim=xlim;
        dstelim=ylim;
        
        %Add histograms and widths
        [dst.pelements,dst.pcenters]=hist(dst.phase,50);
        [dst.eelements,dst.ecenters]=hist(dst.pctenergy,50);
        pephist=plot(dst.pcenters,(dst.pelements/max(dst.pelements))*.25*(dstelim(2)-dstelim(1))+dstelim(1));
        peehist=plot((dst.eelements/max(dst.eelements))*.25*(dstplim(2)-dstplim(1))+dstplim(1),dst.ecenters);
        
        dstplim=xlim;
        dstelim=ylim;
        dst.ewidthpct=6*std(dst.pctenergy);
        dst.ewidthmev=dst.ewidthpct*dst.eavg;
        dst.pwidthns=6*std(dst.phase);
        dst.pwidthdeg=dst.pwidthns*360*dst.freq*10^-9;
        dst.pwidthtext=[num2str(dst.pwidthns) ' ns'];
        dst.ewidthtext=[num2str(dst.ewidthpct) ' (%)'];
        profiletext=sprintf('Phase 3\\sigma FW: %s\nEnergy 3\\sigma FW: %s\n',...
            dst.pwidthtext,dst.ewidthtext);
        tet=text(dstplim(2),dstelim(2),profiletext,'HorizontalAlignment','right',...
            'VerticalAlignment','top','FontSize',8);
        hold off;
        set(tet,'Position',[dstplim(2) dstelim(2)])    

    sfilename=strrep(dst.file,'_','\_');       
    stitle=suptitle(sfilename);

    %Add Menu Options
    toolsmenu=uimenu(plots.fh,'Label','DynacGUI Tools');
    uimenu(toolsmenu,'Label','Show Distribution Properties','Callback',...
        {@showdstdata,dst.file,dst});
    uimenu(toolsmenu,'Label','Overplot Additional .dst file','Callback',...
        {@overplotdst,plots});
%wm1=uimenu(toolsmenu,'Label','Auxiliary Plots','separator','on');
%wm3=uimenu(toolsmenu,'Label','Export COSY Distribution File','Callback',...
%         {@write_cosy_distribution,x,xp,y,yp,phase,energy,freqlist(plotnumber)});
%            wm4=uimenu(toolsmenu,'Label',...
%           'Export TRACK Distribution File','Callback',...
%           {@write_track_distribution,x,xp,y,yp,phase,energy,freqlist(plotnumber)});
            

%     %Auxiliary Plots Menu
%     pm0=uimenu(wm1,'Label','X vs. Time','Callback',...
%         {@xt_plot,x,phase});
%     pm1=uimenu(wm1,'Label','Y vs. Time','Callback',...
%         {@yt_plot,y,phase});
%     pm2=uimenu(wm1,'Label','X vs. Energy','Callback',...
%         {@xe_plot,x,energy});
%     pm3=uimenu(wm1,'Label','Y vs. Energy','Callback',...
%         {@ye_plot,y,energy});
%     pm4=uimenu(wm1,'Label','P vs. x','Callback',...
%         {@px_plot,x,energy,plottitle});
%     pm5=uimenu(wm1,'Label','Phase / Energy Histogram','Callback',...
%         {@p_hist,phase,plottitle});
    
    function changeeaxis(~,~)
        %Change energy axis scale
        if strcmp(eaxtype,'pct')
            %Set energy axis to absolute energy in MeV
            set(peehist,'Ydata',dst.eavg*(1+0.01*dst.ecenters));
            set(pephist,'Ydata',dst.eavg*(1+0.01*get(pephist,'Ydata')));
            set(tep,'Ydata',dst.absenergy);
            dst.ewidthtext=[num2str(dst.ewidthmev) ' MeV'];
            if isfield(dst2,'absenergy'); set(dst2.tep,'Ydata',dst2.absenergy); end;
            set(eaxislabel,'String','Energy (MeV)');
            eaxtype='abs';
        elseif strcmp(eaxtype,'abs')
            %Set energy axis to relative energy in MeV
            set(peehist,'Ydata',(dst.eavg*(1+0.01*dst.ecenters)-dst.eavg));
            set(pephist,'Ydata',get(pephist,'Ydata')-dst.eavg);
            set(tep,'Ydata',dst.relenergy);
            if isfield(dst2,'relenergy'); set(dst2.tep,'Ydata',dst2.relenergy); end;
            set(eaxislabel,'String','Rel. Energy (MeV)');
            eaxtype='rel';
        elseif strcmp(eaxtype,'rel')
            %Set energy axis to percent energy deviation
            set(peehist,'Ydata',dst.ecenters);
            set(pephist,'Ydata',100*get(pephist,'Ydata')/dst.eavg)
            set(tep,'Ydata',dst.pctenergy);
            dst.ewidthtext=[num2str(dst.ewidthpct) ' (%)'];
            if isfield(dst2,'pctenergy'); set(dst2.tep,'Ydata',dst2.pctenergy); end;
            set(eaxislabel,'String','Rel. Energy dE/E (%)');
            eaxtype='pct';            
        end
        profiletext=sprintf('Phase 3\\sigma FW: %s\nEnergy 3\\sigma FW: %s\n',...
            dst.pwidthtext,dst.ewidthtext);
        set(tet,'String',profiletext);
        dstplim=xlim;
        dstelim=ylim;
        set(tet,'Position',[dstplim(2) dstelim(2)])        
    end
   
    function changepaxis(~,~)
        if strcmp(paxtype,'ns')
            %Set Phase Axis to Degrees
            set(peehist,'Xdata',get(peehist,'Xdata')*360*dst.freq*10^(-9));
            set(pephist,'Xdata',dst.pcenters*360*dst.freq*10^(-9));
            set(tep,'Xdata',dst.deg);
            if isfield(dst2,'deg'); set(dst2.tep,'Xdata',dst2.deg); end;
            set(paxislabel,'String','Phase (deg)');
            dst.pwidthtext=[num2str(dst.pwidthdeg) ' deg'];
            paxtype='deg';
        else
            %Set Phase Axis to nanoseconds
            set(tep,'Xdata',dst.phase);
            if isfield(dst2,'phase'); set(dst2.tep,'Xdata',dst2.phase); end;
            set(peehist,'Xdata',get(peehist,'Xdata')/360/dst.freq*10^9);
            set(pephist,'Xdata',dst.pcenters);
            set(paxislabel,'String','Time (ns)');
            dst.pwidthtext=[num2str(dst.pwidthns) ' ns'];
            paxtype='ns';
        end
        profiletext=sprintf('Phase 3\\sigma FW: %s\nEnergy 3\\sigma FW: %s\n',...
            dst.pwidthtext,dst.ewidthtext);
        set(tet,'String',profiletext);
        dstplim=xlim;
        dstelim=ylim;
        set(tet,'Position',[dstplim(2) dstelim(2)])  
    end

    function overplotdst(~,~,plots)
    %given a list of plot handles, load in another .dst file and overplot the
    %data.

        dst2=getdst;
        if isequal(dst2.file,0)
            %selection cancelled
            return
        end
        
        stitletext=['\color{red}' dst.file '\color{black} / '...
            '\color{blue}' dst2.file];
        stitletext=strrep(stitletext,'_','\_');       
        set(stitle,'String',stitletext);
        
        hold(plots.xx,'on');
        plot(plots.xx,dst2.x,dst2.xp,'b.','MarkerSize',3);
        hold(plots.yy,'on');
        plot(plots.yy,dst2.y,dst2.yp,'b.','MarkerSize',3);
        hold(plots.xy,'on');
        plot(plots.xy,dst2.x,dst2.y,'b.','MarkerSize',3);
        hold(plots.te,'on');
        if strcmp(paxtype,'ns')
            switch eaxtype
                case 'rel'
                    dst2.tep=plot(plots.te,dst2.phase,dst2.relenergy,'b.','MarkerSize',3);
                case 'pct'
                    dst2.tep=plot(plots.te,dst2.phase,dst2.pctenergy,'b.','MarkerSize',3);
                    dstplim=xlim(plots.te);
                    dstelim=ylim(plots.te);
                    set(tet,'Position',[dstplim(2) dstelim(2)])
                case 'abs'
                    dst2.tep=plot(plots.te,dst2.phase,dst2.absenergy,'b.','MarkerSize',3);
            end
        else %phase in degrees
            switch eaxtype
                case 'rel'
                    dst2.tep=plot(plots.te,dst2.deg,dst2.relenergy,'b.','MarkerSize',3);
                case 'pct'
                    dst2.tep=plot(plots.te,dst2.deg,dst2.pctenergy,'b.','MarkerSize',3);
                case 'abs'
                    dst2.tep=plot(plots.te,dst2.deg,dst2.absenergy,'b.','MarkerSize',3);
            end
        end

    end

end



function dst=getdst
    %Returns a structure, dst, which contains the data from a .dst file.
    [dst.file,dst.path,~]=uigetfile(['Particle Distributions' filesep '*.dst']);
    
    if isequal(dst.file,0)
    %selection cancelled
        return
    end

    dstfullpath=[dst.path dst.file];
    %For now, assume .dst files are in MHz and radians.  Allow this to be
    %configured at some point.

    %Read in the header information
    dstfid=fopen(dstfullpath);
        dstheader=fgetl(dstfid);
        dsthead=strsplit(dstheader);
    fclose(dstfid);

    dst.freq=str2double(dsthead(4))*10^6; %Freq in Hz

    % Read the particle data
    dstdata=dlmread(dstfullpath,'',1,0);    

    dst.x  = dstdata(:,1)*10; % cm -> mm
    dst.xp = dstdata(:,2)*1000; % rad -> mrad

    dst.y =  dstdata(:,3)*10; % cm -> mm
    dst.yp = dstdata(:,4)*1000; % rad - > mrad

    dst.phase =  dstdata(:,5)*1/(2*pi)*(1/dst.freq)*10^9; %rad -> ns
    dst.deg = dstdata(:,5)*(180/pi); %rad -> deg
    dst.absenergy = dstdata(:,6);
    if length(dsthead)>=5 %If the header contains the RP energy, use that
        dst.eavg = str2double(dsthead(5)); %RP energy in MEV (not an average)
    else %If the RP energy is not present, use the c.o.g. energy
        dst.eavg = mean(dstdata(:,6));
    end
    dst.relenergy = (dst.absenergy-dst.eavg);
    dst.pctenergy = (dst.absenergy/dst.eavg-1)*100;  % E_total -> percentage
end

function showdstdata(~,~,dstfile,dst)
%Calculate and display beam properties for a .dst file

%Calculate TWISS parameters 
sigmax = cov(dst.x,dst.xp);
sigmay = cov(dst.y,dst.yp);
sigmaz = cov(dst.phase,dst.mev*1000); %Energy in keV

emitx = sqrt(det(sigmax));
emity = sqrt(det(sigmay));
emitz = sqrt(det(sigmaz));

betax = sigmax(1,1)/emitx;
betay = sigmay(1,1)/emity;
betaz = sigmaz(1,1)/emitz;

alphax = -sigmax(1,2)/emitx;
alphay = -sigmay(1,2)/emity;
alphaz = -sigmaz(1,2)/emitz;
gammaz = (1+alphaz^2)/betaz;

dx = 2*sqrt(emitx*betax);
dy = 2*sqrt(emity*betay);
dtime = 2*sqrt(emitz*betaz);
denergy = 2*sqrt(emitz*gammaz); 

        %Create output string:
        i=1;
        outstring{i}=['Beam Data for File: ' dstfile]; i=i+1;
        outstring{i}=' ';i=i+1;
        outstring{i}=['Mean Energy: ' num2str(dst.eavg) ' MeV'];i=i+1;
        outstring{i}=' ';i=i+1;
        outstring{i}=['X-Alpha: ' num2str(alphax)];i=i+1;
        outstring{i}=['X-Beta: ' num2str(betax) ' mm/mrad'];i=i+1;
        outstring{i}=['X Emittance (4 RMS): ',num2str(emitx*4),' mm.mrad'];i=i+1;
        outstring{i}=['X 1/2 Width (4 RMS): ' num2str(dx) ' mm'];i=i+1;
        outstring{i}=' ';i=i+1;
        outstring{i}=['Y-Alpha: ' num2str(alphay)];i=i+1;
        outstring{i}=['Y-Beta: ' num2str(betay) ' mm/mrad'];i=i+1;
        outstring{i}=['Y Emittance (4 RMS): ',num2str(emity*4),' mm.mrad'];i=i+1;
        outstring{i}=['Y 1/2 Width (4 RMS): ' num2str(dy) ' mm'];i=i+1;
        outstring{i}=' ';i=i+1;
        outstring{i}=['Z Emittance (4 RMS, non-normalized): ',num2str(emitz*4),...
            ' keV.ns'];i=i+1;
        outstring{i}=['Phase 1/2 Width (4 RMS): ',num2str(dtime), ' ns'];i=i+1;
        outstring{i}=['Energy 1/2 Width (4 RMS): ',num2str(denergy), ' keV'];i=i+1;
        outstring{i}=' ';i=i+1;
        outstring{i}=['Number of Particles: ',num2str(length(dst.x))];i=i+1;
        
        %Display output string.
        %Original code stolen from:
        %http://www.mathworks.com/matlabcentral/answers/19553-display-window-for-text-file

        f = figure('menu','none','toolbar','none','Name',[dstfile ' data'],...
            'NumberTitle','Off');
        ph = uipanel(f,'Units','normalized','position',[0.05 0.05 0.9 0.9],...
            'BorderType','none');
        lbh = uicontrol(ph,'style','listbox','Units','normalized','position',...
            [0 0 1 1],'FontSize',9);

        set(lbh,'string',outstring);
        set(lbh,'Value',1);
        set(lbh,'Selected','on');

end


function hout=suptitle(str, fs)
%SUPTITLE Puts a title above all subplots.
%	SUPTITLE('text') adds text to the top of the figure
%	above all subplots (a "super title"). Use this function
%	after all subplot commands.

% This file is from pmtk3.googlecode.com


%PMTKauthor Drea Thomas  
%PMTKdate June 15, 1995
%PMTKemail drea@mathworks.com

% Warning: If the figure or axis units are non-default, this
% will break.

% Parameters used to position the supertitle.

% Amount of the figure window devoted to subplots
plotregion = .92;

% Y position of title in normalized coordinates
titleypos  = .95;

% Fontsize for supertitle
if nargin < 2
  fs = get(gcf,'defaultaxesfontsize')+4;
end

% Fudge factor to adjust y spacing between subplots
fudge=1;

haold = gca;
figunits = get(gcf,'units');

% Get the (approximate) difference between full height (plot + title
% + xlabel) and bounding rectangle.

	if (~strcmp(figunits,'pixels')),
		setings(gcf,'units','pixels');
		pos = get(gcf,'position');
		setings(gcf,'units',figunits);
    else
		pos = get(gcf,'position');
	end
	ff = (fs-4)*1.27*5/pos(4)*fudge;

        % The 5 here reflects about 3 characters of height below
        % an axis and 2 above. 1.27 is pixels per point.

% Determine the bounding rectange for all the plots

h = findobj(gcf,'Type','axes');  

max_y=0;
min_y=1;

oldtitle =0;
for i=1:length(h),
	if (~strcmp(get(h(i),'Tag'),'suptitle')),
		pos=get(h(i),'pos');
		if (pos(2) < min_y), min_y=pos(2)-ff/5*3;end;
		if (pos(4)+pos(2) > max_y), max_y=pos(4)+pos(2)+ff/5*2;end;
    else
		oldtitle = h(i);
	end
end

if max_y > plotregion,
	scale = (plotregion-min_y)/(max_y-min_y);
	for i=1:length(h),
		pos = get(h(i),'position');
		pos(2) = (pos(2)-min_y)*scale+min_y;
		pos(4) = pos(4)*scale-(1-scale)*ff/5*3;
		set(h(i),'position',pos);
	end
end

np = get(gcf,'nextplot');
set(gcf,'nextplot','add');
if (oldtitle),
	delete(oldtitle);
end
ha=axes('pos',[0 1 1 1],'visible','off','Tag','suptitle');
ht=text(.5,titleypos-1,str);set(ht,'horizontalalignment','center','fontsize',fs);
set(gcf,'nextplot',np);
axes(haold);
if nargout,
	hout=ht;
end
end

function change_dynacgui_settings(hObject,~)
%Change some of the values defined in DynacGUI.ini from within the program
handles=guidata(hObject);
parent=hObject;
swheight=200;
settingswin=figure('Name','Change DynacGUI Settings','Color',[0.941 0.941 0.941],...
    'Position',[50 500 300 swheight],'NumberTitle','Off','menubar','none');
uicontrol('Style','Text','String','Setting',...
    'Position',[10 swheight-30 100 20]);
uicontrol('Style','Text','String','Value',...
    'Position',[90 swheight-30 70 20],'HorizontalAlignment','Center');
uicontrol('Style','Text','String','Esectors',...
    'HorizontalAlignment','Right',...
    'Position',[10 swheight-60 70 20]);
uicontrol('Style','edit','Position',[90 swheight-60 60 20],...
    'String',handles.inivals.Esectors,'HorizontalAlignment','Center',...
    'BackgroundColor','white','Callback',{@dg_setting_callback,'Esectors'});
uicontrol('Style','Text','String','Bsectors',...
    'HorizontalAlignment','Right',...
    'Position',[10 swheight-80 70 20]);
uicontrol('Style','edit','Position',[90 swheight-80 60 20],...
    'String',handles.inivals.Bsectors,'HorizontalAlignment','Center',...
    'BackgroundColor','white','Callback',{@dg_setting_callback,'Bsectors'});
uicontrol('Style','Text','String','Csectors',...
    'HorizontalAlignment','Right',...
    'Position',[10 swheight-100 70 20]);
uicontrol('Style','edit','Position',[90 swheight-100 60 20],...
    'String',handles.inivals.Csectors,'HorizontalAlignment','Center',...
    'BackgroundColor','white','Callback',{@dg_setting_callback,'Csectors'});
uicontrol('Style','Text','String','RFQreject',...
    'HorizontalAlignment','Right','Position',[10 swheight-120 70 20]);
uicontrol('Style','edit','Position',[90 swheight-120 60 20],...
    'String',handles.inivals.RFQreject,'HorizontalAlignment','Center',...
    'BackgroundColor','white','Callback',{@dg_setting_callback,'RFQreject'});

function dg_setting_callback(hObject,~,settingname)
    val=get(hObject,'String');
    disp(settingname);
    disp(['Oldvalue: ' handles.inivals.(settingname)]);
    handles.inivals.(settingname)=val;
    disp(['Newvalue: ' handles.inivals.(settingname)]);
    guidata(parent,handles);
end

end

