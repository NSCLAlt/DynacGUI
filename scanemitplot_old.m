function scanemitplot(varargin)
    try
        plotfile=fopen('emit.plot');
    catch
        disp('Error: Unable to open emit.plot');
        return
    end
    
    plotlist=[];
    while ~feof(plotfile)
        line=fgetl(plotfile);
        if (regexp(line,'^\s{11}\d')==1)
            plottype=line(12);
            plotname=fgetl(plotfile);
            if (plottype=='1')
                plotname=[' Envelope Plot: ' plotname];
            else
                plotname=[plotname '                '];
            end
            plotlist=[plotlist;plotname];
        end
    end
    fclose(plotfile)
end