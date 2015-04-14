function DG_viewresults(~,~)
%View Saved Results from DynacGUI runs
%
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

%Initial Version 10/22/14

xsize=800;
ysize=500;

vrwindow=figure('Name','Results Viewer','MenuBar','none',...
    'Color',[0.941 0.941 0.941],'Position',[100 100 xsize ysize]);

vrdir_textbox=uicontrol('Style','Text','BackgroundColor','w',...
    'Position',[20 ysize-30 500 20]);
vrdir_button=uicontrol('Style','pushbutton','FontSize',10,...
    'String','Select Results Directory','Position',[525 ysize-30 200 20],...
    'Callback',{@vr_directory_button});

plotz_button=uicontrol('Style','pushbutton','FontSize',10,...
    'String','Plot Energy/Envelope Graph','Position',[20 ysize-60 200 20],...
    'Callback',{@zplots_button_Callback},'Enable','off');

graphs_listbox=uicontrol('style','listbox','Position',[20 ysize-450 350 350],...
    'BackgroundColor','w','Callback',@listbox_callback);
uicontrol('style','text','String','Generated Graphs (click to plot)',...
    'Position',[20 ysize-95 250 15],'FontSize',10,'HorizontalAlignment','left');


function vr_directory_button(~,~)
    %Callback for "Select Results Directory" button.  Also loads data from
    %stored 'data.mat' file and stores it in the UserData field of the
    %Results Viewer window.
        vrdir=uigetdir('Results','Select Results Directory');
        if isequal(vrdir,0)
            return;
        end
        set(vrdir_textbox,'String',vrdir);  
        vrname=regexp(vrdir,filesep,'split');
        vrname=cellstr(vrname(length(vrname)));
        S=load([vrdir filesep 'data.mat']); 
        S.vrdir=vrdir;
        S.vrname=vrname{1};
        set(gcbf,'UserData',S);
        set(plotz_button,'Enable','on');
        set(graphs_listbox,'String',S.ud.plotlist);
end

end

function listbox_callback(hObject,~)
%Callback for clicking on a plot in the list.
S=get(gcbf,'UserData');
selection=get(hObject,'Value');
emitplot(S.ud.freqlist,S.ud.plotloc(selection),selection,S.vrdir);
end

function zplots_button_Callback(~,~)
    %Plots data from the "dynac.print" file, consisting of envelope
    %and energy data.
    S=get(gcbf,'UserData');
    ud=S.ud;
    handles.settings=S.set;
    vrdir=S.vrdir;
    
    try    
        zdata=importdata([vrdir filesep 'dynac.print']);
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
    ylabel(transaxes,'RMS Width (mm)');
    set(transaxes,'color','none');
    box(transaxes,'off');
    
    %Plot Y envelope
    hold on;
    yline=plot(transaxes,zdata.data(:,1),-zdata.data(:,3),'Color','g');
    
    %Plot dashed line at x/y = 0
    zeroline=plot(transaxes,[0,max(zdata.data(:,1))],[0,0],':k','LineWidth',.1);
    
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
    graphtitle=[strrep((S.vrname),'_','\_') ...
        ': A = ' num2str(handles.settings.A) ...
        ' Q = ' num2str(handles.settings.Q) ...
        ' N = ' num2str(handles.settings.Npart)];
    title(graphtitle,'FontSize',14);
    
    %Plot Box Locations
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
    
    %Add lines for emittance plots - this should evenutally replace the
    %hard coded box plots. (Perhaps add to the list any EMITL cards?)
    plotlinehandles=[];
    plotlabelhandles=[];
    if isstruct(ud) && ~isempty(ud.plotzpos)
        for i=1:length(ud.plotzpos);
            if ~isempty(ud.plotzpos{i})
                h=line([ud.plotzpos{i} ud.plotzpos{i}],ylim);
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
        line([ud.devarray.end(j)-ud.devarray.length(j) ud.devarray.end(j)],...
            [0,0],'Color',ud.devarray.color(j),'LineWidth',5,'Parent',transaxes);
    end
    
    %setup axes for particle number counts
    if (size(zdata.data,2)==10)
        particleaxes=axes('Position',get(transaxes,'Position'),...
        'XaxisLocation','bottom','YAxisLocation','right',...
        'Visible','off','Xlim',[zmin zmax],'Ylim',[0 1],...
        'Color','none','Ytick',[]);
         pline=line(zdata.data(:,1),zdata.data(:,10)/max(zdata.data(:,10)),...
            'Color','blue','Parent',particleaxes);
        %Displays particle count
        %Note: this is hardcoded - do not trust.
        %pcount=sprintf('L080: %g L92: %g\r\n',zdata.data(129,10),...
        %   zdata.data(150,10));
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
%    xy_checkbox=uicontrol(plot_window,...
%        'Style','checkbox','String','X/Y Plot',...
%        'Position',[20 20 100 30],'BackgroundColor',backgroundcolor,...
%        'FontSize',12,'Max',1,'Value',1,'callback',@toggle_xyplot);
    
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
    
    boxlabel_checkbox=uicontrol(plot_window,...
        'Style','checkbox','String','ReA3 Boxes',...
        'Position',[1060 20 200 30],'BackgroundColor',backgroundcolor,...
        'FontSize',12,'Max',1,'Value',0,'callback',@toggle_boxlabel);
    toggle_boxlabel;
    
%    beta_checkbox=uicontrol(plot_window,...
%        'Style','checkbox','String','Beta Functions',...
%        'Position',[960 20 200 30],'BackgroundColor',backgroundcolor,...
%        'FontSize',12,'Max',1,'Value',0,'callback',@toggle_beta);
%    toggle_beta;
    
    plot_dropdown=uicontrol(plot_window,...
        'Style','popupmenu','String',{'X/Y Envelope',...
        'X/Y Emittance','Z Emittance','X/Y Beta Functions','None'},...
        'Position',[20 20 200 30],'BackgroundColor','white',...
        'FontSize',12,'Value',1,'callback',@dropdown_callback);
    
    %setup limit text boxes
    start_textbox=uicontrol(plot_window,...
        'Style','edit','String',num2str(zmin),'Position',[650 25 50 20],...
        'FontSize',10,'callback',@change_min);
    start_label=uicontrol(plot_window,'Style','text','String','Start Position (m)',...
        'Position',[690 25 150 20],'FontSize',12,...
        'BackgroundColor',backgroundcolor);
    end_textbox=uicontrol(plot_window,...
        'Style','edit','String',num2str(zmax),...
        'Position',[850 25 50 20],'FontSize',10,...
        'callback',@change_max);
    end_label=uicontrol(plot_window,'Style','text','String','End Position (m)',...
        'Position',[890 25 150 20],'FontSize',12,...
        'BackgroundColor',backgroundcolor);
    
    %Graph Legend
    leg=legend([xline yline zemitline eline pline],...
        'X','Y','Z','Energy','Particle Count','Location','Southeast');
    set(leg,'Color','none');
    
    function dropdown_callback(src,~)
        graphtype=get(src,'Value');
        yaxislabel=get(transaxes,'ylabel');
        set(xline,'Visible','off')
        set(yline,'Visible','off')
        set(xbetaline,'Visible','off')
        set(ybetaline,'Visible','off')
        set(xemitline,'Visible','off')
        set(yemitline,'Visible','off')
        set(zemitline,'Visible','off')
        switch graphtype
            case 1 %X/Y Envelope Plot
                set(xline,'Visible','on');
                set(yline,'Visible','on');
                set(yaxislabel,'String','RMS Width (mm)');
            case 2 %X/Y Emittance Plot
                set(xemitline,'Visible','on');
                set(yemitline,'Visible','on');
                set(yaxislabel,'String',...
                    'X/Y Emittance (mm.mrad - 1 RMS Normalized)')
            case 3 %Z Emittance Plot
                set(zemitline,'Visible','on');
                set(yaxislabel,'String','Z Emittance (keV.ns - 4 RMS)')
            case 4 %Beta Function Plot
                set(xbetaline,'Visible','on');
                set(ybetaline,'Visible','on');
                set(yaxislabel,'String','X/Y Beta Function (mm/mrad)');
            case 5 %None of the above
                set(yaxislabel,'String','');
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
    function toggle_xyplot(src,eventdata)
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
    function toggle_boxlabel(src,eventdata)
        %Toggles dipslay of box positions
        if (get(boxlabel_checkbox,'Value')==0)
            set(boxlinehandles,'Visible','off');
            set(boxlabelhandles,'Visible','off');
        else
            set(boxlinehandles,'Visible','on');
            set(boxlabelhandles,'Visible','on');
        end
    end
    function toggle_plotlabel(src,eventdata)
        %Toggles display of plot positions
        if (get(plotlabel_checkbox,'Value')==0)
            set(plotlabelhandles,'Visible','off');
            set(plotlinehandles,'Visible','off');
        else
            set(plotlabelhandles,'Visible','on');
            set(plotlinehandles,'Visible','on');
        end
    end
    function toggle_particles(src,eventdata)
        %Toggles dipslay of particle count
        if (get(particles_checkbox,'Value')==0)
            set(pline,'Visible','off');
        else
            set(pline,'Visible','on');
        end
    end
    function toggle_beta(src,eventdata)
        %Toggles display of beta functions
        if(get(beta_checkbox,'Value')==0)
            set(xbetaline,'Visible','off');
            set(ybetaline,'Visible','off');
        else
            set(xbetaline,'Visible','on');
            set(ybetaline,'Visible','on');
        end
    end
    function change_max(src,eventdata)
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
    function change_min(src,eventdata)
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