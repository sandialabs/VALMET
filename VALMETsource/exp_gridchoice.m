function [xe_grid] = exp_gridchoice(xcell,xunits)
%  Have the user select an experimental grid if more than one
%  Revision log:  
%   Aug 23, 2006  HJI  Initial version.

h_exp_g = figure('visible','on');
ngrids = length(xcell);
diffs = false;
for i=2:ngrids
   if ~isempty(setdiff(unique(xcell{1}),unique(xcell{i}))) 
      diffs = true;
   end
end
if ~diffs
   xe_grid = unique(xcell{1});
else
   uicontrol('units','normalized','style','text','string',...
    'The experimental grids differ.  Please choose one grid for the data.',...
    'position',[0.00 0.90 0.80 0.05], ...
    'fontsize',10, 'BackgroundColor','w');

%  Create a QUIT button to allow the program to end early:
   q1 = uicontrol(h_exp_g,'units','normalized','style','pushbutton',...
    'string','QUIT','fontsize',12, ...
    'position',[0.88 0.92  0.1 0.05], ...
    'callback',{@call_quit});
   set (q1,'UserData',0);

   uicontrol('units','normalized','style','text','string',...
    'GRID #                     # points         Start        End      Avg Spacing',...
    'position',[0.00 0.80 0.80 0.05], ...
    'fontsize',10, 'BackgroundColor','w');
    npts = zeros(ngrids+1,1);
    xstart = zeros(ngrids+1,1);
    xend = zeros(ngrids+1,1);
    dx = zeros(ngrids+1,1);
    labels = cell(ngrids+1,1);
    prefixes = cell(ngrids+1,1);
    for i=1:ngrids
       npts(i) = length(unique(xcell{i}));
       xstart(i) = xcell{i}(1);
       xend(i) = xcell{i}(npts(i));
       dx(i) = (xend(i) - xstart(i))./(npts(i) - 1);
       labels{i} = num2str(i);
       prefixes{i} = ' ';
       yh = 0.80 - 0.05*i;
%  Print grid parameters
       uicontrol('units','normalized',...
          'style','text','string',num2str(i), ...
          'position',[0.0 yh 0.25 0.05], ...
          'fontsize',10, 'BackgroundColor','w');
       uicontrol('units','normalized','style','text','string',...
          num2str(npts(i)),'position',[0.25 yh 0.10 0.05],...
          'fontsize',10, 'BackgroundColor','w');
       uicontrol('units','normalized','style','text','string',...
          num2str(xstart(i),4), 'position',[0.40 yh 0.10 0.05],...
          'fontsize',10, 'BackgroundColor','w');
       uicontrol('units','normalized','style','text','string',...
          num2str(xend(i),4), 'position',[0.50 yh 0.10 0.05],...
          'fontsize',10, 'BackgroundColor','w');
       uicontrol('units','normalized','style','text','string',...
          num2str(dx(i),4), 'position',[0.60 yh 0.10 0.05],...
          'fontsize',10, 'BackgroundColor','w');
       uicontrol('units','normalized','style','text','string',xunits, ...
           'position',[0.70 yh 0.15 0.05], ...
           'fontsize', 10, 'BackgroundColor','w');
    end
%  Work out round number endpoints that bound are bounded by 
%  both the experimental and computational data.
   xstart(ngrids+1) = xstart(1);
   xstart(ngrids+1) = max (xstart(:));
   xend(ngrids+1) = xend(1);
   xend(ngrids+1) = min(xend(:));
   logdiff = log10(xend(ngrids+1) - xstart(ngrids+1));
   xstep = 10^(floor(logdiff)-1);
   nsteps = fix((xend(ngrids+1)-xstart(ngrids+1))/xstep);
%  Choose xstep to give between 15 and 150 steps
   if nsteps > 150
      xstep = 10*xstep;
   elseif nsteps < 15
      xstep = 0.1*xstep;
   end
   xstart(ngrids+1) = xstep*ceil(xstart(ngrids+1)/xstep);
   xend(ngrids+1) = xstep*floor(xend(ngrids+1)/xstep);
   npts(ngrids+1) = fix((xend(ngrids+1)-xstart(ngrids+1))/xstep) + 1;
   dx(ngrids+1) = (xend(ngrids+1) - xstart(ngrids+1))./nsteps;
      
   yh = yh - 0.05;
   uicontrol('units','normalized',...
      'style','text','string', 'Round number grid', ...
      'position',[0.01 yh 0.26 0.05], ...
      'fontsize',10, 'BackgroundColor','w');
   uicontrol('units','normalized','style','text','string',...
       num2str(npts(i)),'position',[0.25 yh 0.10 0.05],...
       'fontsize',10, 'BackgroundColor','w');
   uicontrol('units','normalized','style','text','string',...
       num2str(xstart(i),4), 'position',[0.40 yh 0.10 0.05],...
       'fontsize',10, 'BackgroundColor','w');
   uicontrol('units','normalized','style','text','string',...
       num2str(xend(i),4), 'position',[0.50 yh 0.10 0.05],...
       'fontsize',10, 'BackgroundColor','w');
   uicontrol('units','normalized','style','text','string',...
       num2str(dx(i),4), 'position',[0.60 yh 0.10 0.05],...
       'fontsize',10, 'BackgroundColor','w');
   uicontrol('units','normalized','style','text','string',xunits, ...
       'position',[0.70 yh 0.15 0.05], ...
       'fontsize', 10, 'BackgroundColor','w');
%   done = get(q1,'UserData');

%  Ask which spacing to use for the validation calculations
   q2 = 'Which experimental grid do you want to use?';
   prefixes{ngrids+1} =  '  ';
   labels{ngrids+1} = 'Round number';
   answer = chooseonetextbutton_ps(q2,prefixes,labels, h_exp_g, 0.,0.55);   
   if answer <= ngrids
      xe_grid = unique(xcell{answer});
   else
      xe_grid = (xstart(ngrids+1):dx(ngrids+1):xend(ngrids+1))';
   end

% Was the QUIT button selected?
%   if get(q1,'UserData')
%      exit
%   end
end
close(h_exp_g);
%  end exp_gridchoice