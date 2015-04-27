function varargout = DynacGUIFit(varargin)
% DYNACGUIFIT MATLAB code for DynacGUIFit.fig
%       
%       DynacGUIFit is a graphical interface between the Matlab
%       Optimization Toolbox and Dynac.  It will not work unless you have
%       Dynac, Matlab, AND the Matlab Optimization Toolbox installed. (The
%       MOT is in general not included with Matlab, and requires an
%       additional license.)
%
%       DynacGUIFit can be run as a standalone application to optimize
%       existing complete Dynac decks, or it can be called from within
%       DynacGUI.
%
%       DynacGUIFit and DynacGUI are by Daniel Alt.  Questions, bug
%       reports, and suggestions to alt@nscl.msu.edu.
%
%       Dynac itself is by Tanke, Valero, and LaPostolle. Support at 
%       http://dynac.web.cern.ch.
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
%       3/11/15 - Initial version
%       3/24/15 - Set default limits on variables to correspond with sign
%       of variable.
%       3/25/15 - A few bugfixes, laid groundwork for reading dynac.long
%       3/26/15 - Added reading dispersion in from dynac.long.  Requires
%       writing a particle distribution each and every time, dagnabbit. 
%               - Added executable selection menu. 
%       4/1/15 - Fixed a bug where fitting statements on the last element
%       before a manually selected stop points didn't work.
%       4/21/15 - Dispersion function is now calculated directly from a particle
%       distribution, not from the number reported in 'dynac.long'
%                - Improved handling of "NaN" results from the fitting
%                function
%
%       To Do:
%           Grab executable choice from DynacGUI when called from there.
%           Use at least two fitting parameters with selectable weights.
%           Transfer result vector back to DynacGUI quickly. (Harder than it
%               sounds, since non-tunable parameters can be used for fitting.)


% Edit the above text to modify the response to help DynacGUIFit

% Last Modified by GUIDE v2.5 11-Mar-2015 15:01:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DynacGUIFit_OpeningFcn, ...
                   'gui_OutputFcn',  @DynacGUIFit_OutputFcn, ...
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

%DON'T FORGET TO DO:
%    - Manually account for RFQ and FSOLE cards that start with text.


% --- Executes just before DynacGUIFit is made visible.
function DynacGUIFit_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% ~  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DynacGUIFit (see VARARGIN)

% Choose default command line output for DynacGUIFit
handles.output = hObject;

% --- List of Conditions to Match --- %

% To add your own fitting condition, do the following:
%   1. Add the actual equation for the condition at the BOTTOM of this
%   file.  See the example for 'radius'.
%   2. Add the variable name of the parameter to 'matchlist'. If you called your
%   parameter out.steve, add 'steve' to the matchlist.
%   3. Add a natural language name to 'matchnames'. This must be in the 
%   *same position* in the list as the variable in 'matchlist'.  Seriously,
%   that's important.  So if 'out.steve' is actually the number of
%   particles divided by the y beta function (why you'd want that is
%   another question), you could add 'NParticles / Ybeta [mrad/mm]'.
%   4. If your function will require the use of a dispersion function, add the
%   short name to the array in handles.dstfunctions.

matchlist={'alphax','betax','alphay','betay',...
    'alphaznskev','betaznskev','alphazdegkev','betazdegkev','dx','dxp','dy','dyp',...
    'dphi','dw','betarp','energyrp','tofrp','energycog','tofcog','eoffsetcog','toffsetcog',...
    'xcog','xpcog','ycog','ypcog','rxxp','ryyp','rphie','emitxnorm','emitxnon','emitynorm','emitynon',...
    'emitznskev','emitzdegkev','particles','radius','xdisp','xdispoversqrtbetax',...
    'alphasum','cogxoverdx','cogxminusdx'};
matchnames={'X alpha',...
    'X beta [mm/mrad]',...
    'Y alpha',...
    'Y alpha [mm/mrad]',...
    'Z Alpha (ns/keV)',...
    'Z Beta [ns/keV]',...
    'Z Alpha (deg/keV)',...
    'Z Beta [deg/keV]',...
    'X FWHM Spread [mm]',...
    'XP FWHM Spread [mrad]',...
    'Y FWHM Spread [mm]',...
    'YP FWHM Spread [mrad]',...
    'Phase Spread [deg]',...
    'Energy Spread [keV]',...
    'R.P. Velocity (v/c)',...
    'R.P. Energy [MeV]',...
    'R.P. Time-of-Flight [deg]',...
    'C.O.G. Energy [MeV]',...
    'C.O.G. Time-of-Flight [deg]',...
    'C.O.G. Energy Offset [MeV]',...
    'C.O.G. Time Offset [deg]',...
    'X c.o.g. [mm]',...
    'Xp c.o.g. [mrad]',...
    'Y c.o.g. [mm]',...
    'Yp c.o.g. [mm]',...
    'X/Xp Correlation',...
    'Y/Yp Correlation',...
    'Phase/Energy Correlation',...
    'X Emit (norm, 4 sig. [mm.mrad])',...
    'X Emit (nonnorm, 4sig. [mm.mrad])',...
    'Y Emit (norm, 4sig. [mm.mrad])',...
    'Y Emit (nonnorm, 4sig. [mm.mrad])',...
    'Z Emit (nonnorm, 4sig. [ns.kev])',...
    'Z Emit (nonnorm, 4sig. [deg.kev])',...
    'Particles Remaining',...
    'Radius (dx^2+dy^2) [mm]',...
    'Dispersion',...
    'X Dispersion/Sqrt(betax)',...
    'Alpha X + Alpha Y',...
    'X C.O.G. / X FWHM',...
    'X c.o.g. - X FWHM'};
    
%List of fitting functions requiring a particle distribution computation
handles.dstfunctions={'xdisp','xdispoversqrtbetax'};

set(handles.matchpars_popup,'String',matchnames);
set(handles.matchpars_popup,'UserData',matchlist);

%Location of executable will be loaded from DynacGUI.ini and stored in
%UserData field of parent GUI.  

try
    inifile=fopen('DynacGUI.ini');
catch
    disperror('No .INI file found');
    handles.executable='dynacv6_0 -mingw'; %Hard coded executable if no INI file
end
mingw=[];

%Assuming an .INI file was present, run through it and deal with 
%the contents. Lines in the .INI file starting with ; are comments.
if inifile>=1
    %Create a structure called "handles.inivals" containing values from the .ini
    %file.  For example: handles.inivals.layout='Machine Data\layout.txt'
    i=1;
    while ~feof(inifile)
        line=fgetl(inifile);
        if regexp(line,'^;'); continue; end;
        iniarray{i,1}=regexp(line,'\t','split');
        i=i+1;
    end
    tmp=cellfun(@(v) v(1),iniarray(:,1));
    tmp2=cellfun(@(v) v(2),iniarray(:,1));
    handles.inivals=cell2struct(tmp2,tmp,1);
    fclose(inifile);
    
    %Set the values present in the .ini file
    if isfield(handles.inivals,'Executable')
        handles.executable=handles.inivals.Executable;
        if isfield(handles.inivals,'Executable2') %If there is a second executable...
            %setup executable choice
            exmenu=uimenu(hObject,'Label','Executable');
            handles.inivals.exm1=uimenu(exmenu,'Label',...
                handles.inivals.Executable,'Callback',...
                {@change_executable,1},'Checked','on');
            handles.inivals.exm2=uimenu(exmenu,'Label',...
                handles.inivals.Executable2,'Callback',...
                {@change_executable,2});
            if isfield(handles.inivals,'Executable3') %If there is ALSO a third
                handles.inivals.exm3=uimenu(exmenu,'Label',...
                    handles.inivals.Executable3,'callback',...
                    {@change_executable,3});
            end
        end
    end
    if isfield(handles.inivals,'Mingw') && str2num(handles.inivals.Mingw)
        mingw=' -mingw';
    end
end

set(hObject,'UserData',{handles.executable,mingw}); %Store exectuable location for later use

%Add Tools menu
toolsmenu=uimenu(hObject,'Label','Tools');
handles.writemenu=uimenu(toolsmenu,'Label','Write Fitting Deck','Callback',@writefile,'Enable','off');

if (nargin>=4)    
    disperror(hObject, handles, 'Input File Loaded from DynacGUI');
    set(handles.indeck_inputbox,'String',varargin{1});
    parseinputfile(hObject,handles);
end

% Update handles structure
guidata(hObject, handles);

function change_executable(hObject, ~, exnumber)
    %Changes the active executable to the exnumber.  Performs
    %NO sanity checks.
    handles=guidata(hObject);
    if exnumber==1
        handles.executable=handles.inivals.Executable;
        set(handles.inivals.exm1,'Checked','On');
        set(handles.inivals.exm2,'Checked','Off');
        if isfield(handles.inivals,'exm3');
            set(handles.inivals.exm3,'Checked','Off');
        end
    elseif exnumber==2
        handles.executable=handles.inivals.Executable2;
        set(handles.inivals.exm1,'Checked','Off');
        set(handles.inivals.exm2,'Checked','On');
        if isfield(handles.inivals,'exm3')
            set(handles.inivals.exm3,'Checked','Off');
        end
    elseif exnumber==3
        handles.executable=handles.inivals.Executable3;
        set(handles.inivals.exm1,'Checked','Off');
        set(handles.inivals.exm2,'Checked','Off');
        set(handles.inivals.exm3,'Checked','On');
    else
        disperror('Error! Executable not found in .ini file');
    end
    figtag = 'DynacGUIFit';
    guifig = findobj(allchild(0), 'flat','Tag', figtag);
    ud=get(guifig,'UserData');
    ud{1}=handles.executable;
    set(guifig,'UserData',ud);
    guidata(hObject,handles);


% UIWAIT makes DynacGUIFit wait for user response (see UIRESUME)
% uiwait(handles.DynacGUIFit);


% --- Outputs from this function are returned to the command line.
function varargout = DynacGUIFit_OutputFcn(hObject, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% ~  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function indeck_inputbox_Callback(hObject, ~, handles)


function indeck_inputbox_CreateFcn(hObject, ~, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function selectfile_button_Callback(hObject, ~, handles)

temp=get(handles.indeck_inputbox,'String');
[devicefile,dfpath,~]=uigetfile('*.*');

if isequal(devicefile,0) %user cancels out of file select
    set (handles.indeck_inputbox,'String',temp)
else
    set(handles.indeck_inputbox,'String',[dfpath devicefile]);
    parseinputfile(hObject,handles);
end


function parseinputfile(hObject,handles)
inputdeckname=get(handles.indeck_inputbox,'String');
if exist(inputdeckname,'file')==0 %Throw an error if file missing
    set(handles.allvars_listbox,'String',['Error: File ' inputdeckname ' not found.']);
    return  
end

inputdeck=fopen(inputdeckname);

fileflag=0;
linenumber=1;
i=1;
parlist={};
while ~feof(inputdeck) %While there is input deck left
    inputline=fgetl(inputdeck); %Read a new line from the input deck
    if regexp(inputline,'^EMITGR') %Strip unneccessary output cards
        fgetl(inputdeck);
        fgetl(inputdeck);
        fgetl(inputdeck);
        continue;
    elseif regexp(inputline,'^EMITL')
        fgetl(inputdeck);
        continue;
    elseif regexp(inputline,'^EMIT')
        continue;
    elseif regexp(inputline,'^ENVEL')
        fgetl(inputdeck);
        fgetl(inputdeck);
        fgetl(inputdeck);
        fgetl(inputdeck);
        continue;
    elseif regexp(inputline,'^WRBEAM')
        fgetl(inputdeck);
        fgetl(inputdeck);
        continue
    end
    if fileflag==1 %Don't split things up if this is a filename
        linepars={inputline};
        fileflag=0;
    else
        linepars=regexp(inputline,'\s+','split'); %Split the line by whitespace
    end
    if regexp(inputline,'^RFQPTQ|^FIELD|^FSOLE|^RDBEAM')
            fileflag=1; %Next line down the pipeline is a file name
    end
    for parnumber=1:length(linepars) 
        %Add each item on the line to the running list with an index
        listitem=['(' num2str(linenumber) ',' num2str(parnumber)...
            ') ' linepars{parnumber}];
        parlist=[parlist listitem];   %#ok<AGROW>
        i=i+1;
    end
    linenumber=linenumber+1; %increment line number
end

fclose(inputdeck);

set(handles.allvars_listbox,'String',parlist);
set(handles.endselect_button,'Enable','on');
set(handles.resetend_button,'Enable','on');
disperror(hObject,handles,'File Selected');



function allvars_listbox_Callback(hObject, ~, handles)
%When you click on the list box containing all the elements
allvars=get(handles.allvars_listbox,'String');
index_selected=get(handles.allvars_listbox,'Value');
item_selected=allvars{index_selected};
items=regexp(item_selected,'\s+','split');
if isempty(str2num(items{2})) %If you have selected a text field
    set(handles.addvar_button,'Enable','off'); %You can't add a variable
    set(handles.endselect_button,'Enable','on'); %You can define an endpoint
    return 
end

%If you've selected a number field
set(handles.index_textbox,'String',items{1});
set(handles.value_editbox,'String',items{2});
if(str2double(items{2})<0)
    set(handles.min_editbox,'String','-9999');
    set(handles.max_editbox,'String','0');
else
    set(handles.min_editbox,'String','0');
    set(handles.max_editbox,'String','9999');
end

set(handles.addvar_button,'Enable','on'); %You CAN add a variable
set(handles.endselect_button,'Enable','off'); %You can't define an endpoint



function allvars_listbox_CreateFcn(hObject, ~, handles)

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function selectedvars_listbox_Callback(hObject, ~, handles)
%When you click on a value in the "independent variables" listbox.
selectedvars=get(handles.selectedvars_listbox,'String');
index_selected=get(handles.selectedvars_listbox,'Value');
item_selected=selectedvars{index_selected};
parts=regexp(item_selected,'[\s\(\)\,]','split');
index=['(' parts{2} ',' parts{3} ')'];
set(handles.index_textbox,'String',index);
set(handles.value_editbox,'String',parts{6});
set(handles.min_editbox,'String',parts{9});
set(handles.max_editbox,'String',parts{10});
set(handles.addvar_button,'Enable','on'); 

function selectedvars_listbox_CreateFcn(hObject, ~, handles)

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function addvar_button_Callback(hObject, ~, handles)
selectedvars=get(handles.selectedvars_listbox,'String');
index=get(handles.index_textbox,'String');
startvalue=get(handles.value_editbox,'String');
minvalue=get(handles.min_editbox,'String');
maxvalue=get(handles.max_editbox,'String');


item_to_add=([index ' Start: ' startvalue ' Range: ('...
    minvalue ',' maxvalue,')']);


if isempty(selectedvars) %If the variable list is empty, skip the checks.
    selectedvars=[selectedvars; {item_to_add}];
else
    if ismember(item_to_add,selectedvars) %Refuse to add exact duplicate
        return;
    end
    duplicate=regexp(selectedvars,item_to_add(1:6)); %However, if new parameters, update
    if ~all(cellfun('isempty',duplicate));
        dupline=find(~cellfun('isempty',duplicate));
        selectedvars{dupline}=item_to_add;
    else %Not a duplicate line - append to array
        selectedvars=[selectedvars; {item_to_add}];
    end
end

selectedvars=sort(selectedvars);
set(handles.selectedvars_listbox,'String',selectedvars);

%Once you've added a variable
set(handles.removevar_button,'Enable','on'); %You can remove variables
set(handles.writemenu,'Enable','on'); %You can write the fitting deck
set(handles.solve_button,'Enable','on'); %You can run the optimizer



function removevar_button_Callback(hObject, ~, handles)
selectedvars=get(handles.selectedvars_listbox,'String');
index_selected=get(handles.selectedvars_listbox,'Value');
set(handles.selectedvars_listbox,'Value',1);
selectedvars(index_selected)=[];
set(handles.selectedvars_listbox,'String',selectedvars);

%If you've removed all the variables...
if isempty(selectedvars)
    set(handles.removevar_button,'Enable','off'); %You can't remove any more
    set(handles.writemenu,'Enable','off'); %You also can't make a fitting deck
    set(handles.solve_button,'Enable','off'); %You also can't run the optimizer
end


function endselect_button_Callback(hObject, ~, handles)
allvars=get(handles.allvars_listbox,'String');
index_selected=get(handles.allvars_listbox,'Value');
item_selected=allvars(index_selected);

set(handles.endpoint_textbox,'String',item_selected{1});


function resetend_button_Callback(hObject, ~, handles)
set(handles.endpoint_textbox,'String','End of File');


function min_editbox_Callback(hObject, ~, handles)


function min_editbox_CreateFcn(hObject, ~, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function max_editbox_Callback(hObject, ~, handles)


function max_editbox_CreateFcn(hObject, ~, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function writefile(hObject, ~)
handles=guidata(hObject);
%Check for scratch directory, create it if it doesn't exist.
if ~isdir('dynacscratch')
    try
        mkdir('dynacscratch');
    catch
        disp('Unable to create scratch directory');
        return;
    end
end
sdir=['dynacscratch' filesep]; %location of scratch directory

%Write particle file if fitting on parameter that needs it
matchpars=get(handles.matchpars_popup,'UserData');
matchval=get(handles.matchpars_popup,'Value');
if  ismember(matchpars(matchval),handles.dstfunctions)
    dstcard='WRBEAM\r\nend.dst\r\n1 2\r\n';
else
    dstcard=[];
end

%Retrieve independent variables and ending line
selectedvars=get(handles.selectedvars_listbox,'String'); 
endpoint=get(handles.endpoint_textbox,'String'); 
if strcmp(endpoint,'End of File')
    endline=0;
else
    endtext=regexp(endpoint,'\d+','match');
    endline=str2num(endtext{1});
end
for i=1:length(selectedvars)
    vararray(i,:)=regexp(selectedvars{i},'[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?','match');
end
fitlines=vararray(:,1);
fitcols=vararray(:,2);

%Prepare to scan the input deck
inputdeckname=get(handles.indeck_inputbox,'String');
[~,name,ext] = fileparts(inputdeckname); 
fitdeckname=strrep([name ext],'.in','_fit.in');
inputdeck=fopen(inputdeckname);
fitdeck=fopen([sdir fitdeckname],'w');
prefix=[];
bufferline=1;
fileflag=0;

inputline=fgetl(inputdeck); %Read the first line from the input file.
cardbuffer=[inputline '\r\n']; %Start the card buffer with this line.

linenumber=2;
while ~feof(inputdeck)
    inputline=fgetl(inputdeck); %Read a new line from the input file.
    items=regexp(inputline,'\s+','split');
    if fileflag==1 %If we're in the midst of a card with a filename in it
        inputline=['..' filesep inputline];
        inputline=strrep(inputline,'\','\\');
        cardbuffer=[cardbuffer inputline '\r\n']; %Add this line to the card buffer
        bufferline=bufferline+1;
        fileflag=0;
    elseif isempty(str2num(items{1})) %If this line starts with text...
        if ~isempty(prefix) %If there is a fitting line
            cardbuffer=[';FIT' prefix '\r\n' cardbuffer]; %Prepend it to the buffer
            prefix=[]; %And then clear it.
        end
        if ~isempty(cardbuffer)
            fprintf(fitdeck,[cardbuffer]); %...dump the card buffer...
        end
        bufferline=1; %Reset the bufferline counter.
        if regexp(inputline,'^EMITGR') %Strip unneccessary output cards
            fgetl(inputdeck);
            fgetl(inputdeck);
            fgetl(inputdeck);
            cardbuffer=[];
            continue;
        elseif regexp(inputline,'^EMITL')
            fgetl(inputdeck);
            cardbuffer=[];
        continue;
        elseif regexp(inputline,'^EMIT')
            cardbuffer=[];
            continue;
        elseif regexp(inputline,'^ENVEL')
            fgetl(inputdeck);
            fgetl(inputdeck);
            fgetl(inputdeck);
            fgetl(inputdeck);
            cardbuffer=[];
        continue;
        elseif regexp(inputline,'^WRBEAM')
            fgetl(inputdeck);
            fgetl(inputdeck);
            cardbuffer=[];
        continue
        end

        cardbuffer=[inputline '\r\n']; %...then start a new buffer with this line.
        if regexp(cardbuffer,'^STOP') %Copes with terminal blank lines in input file
            cardbuffer=[dstcard 'EMIT\r\n' cardbuffer]; %make sure there's a final emit card
            break;
        elseif regexp(inputline,'^RFQPTQ|^FIELD|^FSOLE|^RDBEAM')
            fileflag=1; %Next line down the pipeline is a file name
        end
    else %If this line starts with a number...
        if ismember(num2str(linenumber),fitlines) %... and it has a fit parameter on it
           wherefits=ismember(fitlines,num2str(linenumber)); 
           numfits=length(fitlines(wherefits)); %Number of indep vars on this line
           whichcols=fitcols(wherefits); %Columns of indep variables on this line
           for j=1:numfits %For each time line is present
               prefix=[prefix ' ' num2str(bufferline) ' '  whichcols{j} ];
           end
           cardbuffer=[cardbuffer inputline '\r\n']; %Add line to buffer
        else %otherwise don't mark it...
           cardbuffer=[cardbuffer inputline '\r\n']; ...and add it to the card buffer. 
        end
        bufferline=bufferline+1;
    end       
    linenumber=linenumber+1;
    if linenumber==endline %If we have reached the designated endpoint
        if ~isempty(prefix) %If there is a fitting line
            cardbuffer=[';FIT' prefix '\r\n' cardbuffer]; %Prepend it to the buffer
            prefix=[]; %And then clear it.
        end
        cardbuffer=[cardbuffer dstcard 'EMIT\r\nSTOP\r\n']; %Make the final cardbuffer
        break %Drop out of the while loop
    end
end

fprintf(fitdeck,cardbuffer); %Last buffer should always contain "STOP"

fclose(fitdeck);
fclose(inputdeck);

disperror(hObject,handles,['Output File Written, ' datestr(now)]);
set(handles.solve_button,'Enable','on');

handles.fitdeckname=fitdeckname;
guidata(hObject,handles);

function disperror(hObject,handles,errortext)
%Display an error to the error box
set(handles.error_textbox,'String',errortext);


function matchpars_popup_Callback(hObject, ~, handles)


function matchpars_popup_CreateFcn(hObject, ~, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function solve_button_Callback(hObject, ~, handles)
%Callback for the "solve" button.

%Starting Parameters
sdir='dynacscratch';
matchpars=get(handles.matchpars_popup,'UserData');
selectedpar=matchpars{get(handles.matchpars_popup,'Value')};

%General Fitting Options
options=optimoptions('fmincon','DiffMinChange',.1,'Display','Iter');

set(handles.solve_button,'ForegroundColor',[1 0 0],'String','Running');

%Write the modified file with ;FIT statements
writefile(hObject, []);
handles=guidata(hObject);
fitdeckname=handles.fitdeckname;

%Extract independent variable data from list box.
selectedvars=get(handles.selectedvars_listbox,'String'); 
for i=1:length(selectedvars)
    vararray(i,:)=regexp(selectedvars{i},'[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?','match');
end
fitstarts=str2double(vararray(:,3));
fitlower=str2double(vararray(:,4));
fitupper=str2double(vararray(:,5));

%Change to scratch directory and call fitting routine.
cd(sdir);
fitmode=get(get(handles.fit_buttongroup,'SelectedObject'),'String');
if strcmp(fitmode,'Minimize')
    %x, fval, exitflag
    [result,fval,~,output]=fmincon(@(x)dynfunc(x,selectedpar,fitdeckname),...
        fitstarts,[],[],[],[],fitlower,fitupper,[],options)
elseif strcmp(fitmode,'Maximize')
    [result,fval,~,output]=fmincon(@(x)(-dynfunc(x,selectedpar,fitdeckname)),...
        fitstarts,[],[],[],[],fitlower,fitupper,[],options)
elseif strcmp(fitmode,'Fit to Value:')
    fitvalue=str2num(get(handles.fitvalue_editbox,'String'));
    [result,fval,~,output]=fmincon(@(x)abs(fitvalue-dynfunc(x,selectedpar,fitdeckname)),...
        fitstarts,[],[],[],[],fitlower,fitupper,[],options)
else
    disperror('Error: Undefined fit mode');
    return;
end
cd('..');
    
set(handles.solve_button,'ForegroundColor',[0 0 0],'String','Solve');

outputdata={['Result Vector: ' mat2str(result)]};
outputdata{end+1}=['Function Value: ' mat2str(fval)];
outputdata{end+1}=output.message;

disperror(hObject, handles, ['Solver Finished at ' datestr(now)]);

set(handles.output_textbox,'String',outputdata);


function fitvalue_editbox_Callback(hObject, ~, handles)


function fitvalue_editbox_CreateFcn(hObject, ~, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function dynfunc=dynfunc(values,output,deckfile)
%Returns an arbitrary value for a given deck. The parameters identified 
%by ;FIT # statements in the deck will be replaced by the elements of 
%the "values" input, which should be a vector.
%
%To call this from the Matlab optimization tool or using one of the 
%optimization functions such as fminunc, use
%@(x)dynfunc(x,'output','filename').  
%Example:
%@(x)dynfunc(x,'dw','deck.in')

%'Output' should be a string designating which parameter is to be returned.
%For the full list of parameters, see the "getlastemit" function at the 
%bottom of the file or the documentation.

%Values likely to be commonly used:
%'dw' - Energy Spread (keV)
%'dphi' - Time Spread (deg)
%'alphax','betax','emitxnon','emitxnorm' - X CS Parameters
%'alphay','betay','emitynon','emitynorm' - Y CS Parameters

%'Deckfile' should be a string idenifying the dynac input deck to be
%optimized.

%To identify a line in the input deck to be used for fitting, insert
%a comment before the card with the form ;FIT [line #] [parameter #],
%where [line #] is which line of numeric data to use, and [parameter #] is
%which parameter to use.

%For example:
% ;FIT 2 3
% CAVNUM
% 1
% 0 -90 -86.5 8 1
%
% would vary the amplitude of the cavity (-86.5 here) to achieve a fit.


%8/6/14 - Added user confiurable parameters section
%8/7/14 - Added ability to use multiple fit parameters per card
%8/20/14 - If dynac.short ends up empty, return NaN
%3/11/15 - Moved dynfunc code inside DynacGUIFit.m

figtag = 'DynacGUIFit';
guifig = findobj(allchild(0), 'flat','Tag', figtag);
ud=get(guifig,'UserData');
executable=ud{1};
mingw=ud{2};

%Returns selected output value for a given input deck and value of fit parameter
    datafile1='dynac.short';
    datafile2='end.dst';
    outfile='temp.in';
    %Modify temporary deck with input values.
    result=moddeck(deckfile, outfile, values);
    if result~=0 
        return 
    end
    %Run dynac on the modified deck
    command=['"' executable '"' mingw ' ' outfile];
    [~,~]=system(command);
    %Scan dynac.short for the results
    out=getlastemit(datafile1,datafile2);
    if ~isempty(out)
        dynfunc=out.(output);
    else
        dynfunc=NaN;
    end

function result=moddeck(deckfile, outfile, values)
%Sets the value of a parameter identified by a 'Fit' comment to the value
%given by number 'value'
deck=fopen(deckfile);
newdeck=[];

line=fgetl(deck); %Get first line
i=0;

while ischar(line)
    line=strrep(line,'\','\\');
    newdeck=[newdeck line '\r\n']; %Add line to new file
    if strncmp(line,';FIT',4)
        C=strsplit(line);        %Split fit comment line
        nfits=(length(C)-1)/2;   %number of line/value pairs
        rows=C(2:2:length(C));   %array of row values
        rows=cellfun(@str2num,rows(1,:)); %convert to #
        if mod(nfits,1)          %check for odd number of parameters
            disp('Error: Odd number of FIT parameters');
            result=-1;
            return;
        end
        newcard='';                  %Initialize the new card
        for k=1:nfits
         i=i+1;               %count number of FIT statements till this point
         if (length(values))<i    %Check for more FIT statements than inputs
            disp('Error: Not enough input values');
            result=-1;
            return;
         end
         fitline=str2double(C(k*2)); %Determine which line contains fitting par
         fitpar=str2double(C(k*2+1)); %Determine which is fitting parameter
         if k==1 %First parameter per card
           for j=1:fitline
            line=fgetl(deck);        %Skip to line with parameter
            newcard{j}=[line ' \r\n'];
           end
           line=fgetl(deck);        %Get line with parameter to be changed
           D=strsplit(line);
           D{fitpar}=num2str(values(i));%change parameter to value
           newcard{j+1}=[strjoin(D) ' \r\n']; %reassemble line
           while j<max(rows) %Assemble the rest of the card
              j=j+1;
              line=fgetl(deck);
              newcard{j+1}=[line ' \r\n'];
           end
         else %Subsequent parameters
              D=strsplit(newcard{fitline+1});
              D{fitpar}=num2str(values(i));
              newcard{fitline+1}=strjoin(D);
         end
        end
        newdeck=[newdeck horzcat(newcard{:})];   %add the new card to the deck 
    end
    
    line=fgetl(deck); %get next line
end

fclose(deck);

if i==0
    disp('Error: No Fit Statements Found');
    result=-1;
    return;
end
if (length(values))>i
    disp('Warning: More values input than FIT statements');
end

%Write modified deck
deck=fopen(outfile,'w');
fprintf(deck,newdeck);
fclose(deck);
result=0;

function out=getlastemit(shortfilename,dispfilename)

shortfile=fopen(shortfilename);
fseek(shortfile,-648,'eof');
line=fgetl(shortfile);

while isempty(strfind(line,'beam'))
    if feof(shortfile)
        disp('Error: Emit Card Not Found')
        fclose(shortfile);
        out=[];
        return;
    end
    line=fgetl(shortfile);
end
line=fgetl(shortfile);
C=strsplit(line,'\s*',...
    'DelimiterType','RegularExpression');
out.betarp=str2double(C(2));
out.energyrp=str2double(C(3));
out.tofrp=str2double(C(4));
out.energycog=str2double(C(5));
out.tofcog=str2double(C(6));
out.eoffsetcog=str2double(C(7));
out.toffsetcog=str2double(C(8));
line=fgetl(shortfile);
C=strsplit(line,'\s*',...
    'DelimiterType','RegularExpression');
out.xcog=str2double(C(2));
out.xpcog=str2double(C(3));
out.ycog=str2double(C(4));
out.ypcog=str2double(C(5));
line=fgetl(shortfile);
C=strsplit(line,'\s*',...
    'DelimiterType','RegularExpression');
out.alphax=str2double(C(2));
out.betax=str2double(C(3));
out.alphay=str2double(C(4));
out.betay=str2double(C(5));
out.alphaznskev=str2double(C(6));
out.betaznskev=str2double(C(7));
line=fgetl(shortfile);
C=strsplit(line,'\s*',...
    'DelimiterType','RegularExpression');
out.alphazdegkev=str2double(C(2));
out.betazdegkev=str2double(C(3));
out.emitzdegkev=str2double(C(4));
out.freq=str2double(C(6));
line=fgetl(shortfile);
C=strsplit(line,'\s*',...
    'DelimiterType','RegularExpression');
out.dphi=str2double(C(2));
out.dw=str2double(C(3));
out.rphie=str2double(C(4));
out.emitznskev=str2double(C(5));
out.particles=str2double(C(7));
line=fgetl(shortfile);
C=strsplit(line,'\s*',...
    'DelimiterType','RegularExpression');
out.dx=str2double(C(2));
out.dxp=str2double(C(3));
out.rxxp=str2double(C(4));
out.emitxnorm=str2double(C(5));
out.emitxnon=str2double(C(8));
line=fgetl(shortfile);
C=strsplit(line,'\s*',...
    'DelimiterType','RegularExpression');
out.dy=str2double(C(2));
out.dyp=str2double(C(3));
out.ryyp=str2double(C(4));
out.emitynorm=str2double(C(5));
out.emitynon=str2double(C(8));
line=fgetl(shortfile);
line=fgetl(shortfile);
out.runtime=fgetl(shortfile);

fclose(shortfile);

%---Parameters NOT read from dynac.short---%
out.gammarp=1/sqrt(1-out.betarp^2);
out.momentumrp=out.energyrp*(out.betarp*out.gammarp/(out.gammarp-1)); %in MeV/c


%If 'dispersion' is selected, read in distribution file
handles=guidata(gcbf);
matchpars=get(handles.matchpars_popup,'UserData');
matchval=get(handles.matchpars_popup,'Value');
if  ismember(matchpars(matchval),handles.dstfunctions)
  %Compute dispersion function
    dispfile=fopen(dispfilename);
    particles=dlmread(dispfilename,'',1,0); 
    fclose(dispfile);
    x=particles(:,1); %x in cm
    energy=particles(:,6); %Energy in MeV
    momentum=energy*(out.betarp*out.gammarp/(out.gammarp-1)); %Momentum in MeV/c
    dpp=momentum/out.momentumrp;
    fitcoeffs=polyfit(dpp,x,1); %Coeffs in (dp/p)/cm and (dp/p)
    out.xdisp=.01*fitcoeffs(1); %Dispersion function in m/(dp/p) 
end


%Outdated code - reads dispersion dp/p from dynac.long, but not the
%dispersion function (dp/p) / x, which is what is needed.
%  file=fopen(longfilename);
%  fseek(file,-420,'eof');
%  line=fgetl(file);
%  token=regexp(line,':  (\S*)','tokens');
%  out.dispersion=str2double(token{1});
%  fclose(file);

%---Custom fitting parameters---%
%Rather than running dynac twice or more (computationally expensive), define
%compound fitting parameters here, and then add them to the list of options
%near the top of this file. Be sure to name your new parameter
%'out.[parameter name]', using the 'out.radius' example below.
%

out.radius=sqrt(out.dx^2+out.dy^2);
out.alphasum=out.alphax+out.alphay;
out.cogxoverdx=abs(out.xcog)/out.dx;
out.cogxminusdx=abs(out.xcog)-out.dx;

%If your function uses dispersion or another input parameter that requires
%a particle distribution to be output, add it within this "if" statement.
if  ismember(matchpars(matchval),handles.dstfunctions)
    out.xdispoversqrtbetax=abs(out.xdisp)/sqrt(out.betax);
end

