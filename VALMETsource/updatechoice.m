function [dx xstart xstop nx] = updatechoice(xmin,xmax,xstep)
%
global h_rb;     % as used here:  dx, xstart, xstop, nx
%
%  Create a DONE button to allow the program to end early:
h_done = uicontrol('units','normalized','style','pushbutton',...
    'string','DONE','fontsize',12, ...
    'position',[0.65 0.30  0.1 0.05], ...
    'callback',{@call_done});
set (h_done,'UserData',0);

arg_xmin = xmin;
arg_xmax = xmax;

%  first cut at roundnumber values -- stay within min and max:
dx = xstep;
xstart = dx*ceil(xmin/dx);
xstop = dx*floor(xmax/dx);
nx = fix((xstop - xstart)/dx + 1.0001);
changed = [0 0 0 0];
h_rb = zeros(4,1);
done = 0;
%  Allow changes to the roundnumber spacing values. 
  uicontrol('units','normalized',...
    'style','text','string',...
    'Set roundnumber spacing parameters.  When completely done click "DONE"',...
    'position',[0.0 0.50 0.80 0.05], 'fontsize',10);
  uicontrol('units','normalized',...
    'style','text','string',...
    'To maintain consistency, some values will change as you change others.',...
    'position',[0.0 0.45 0.80 0.05], 'fontsize',10);
%On a Mac laptop, changing a value did not clear the old values, making it 
%difficult or impossible to read the numbers.  I have added a blank
%overwrite to erase the previous value.
while (done == 0) 
  prompt1 = strcat('Step size (current value = ',num2str(dx),'):');
  uicontrol('units','normalized', 'style','text','string', ...
    '                         ','position',[0.25 0.40 0.25 0.05], ...
    'fontsize',10,'BackgroundColor','w');
  h_rb(1) = uicontrol('units','normalized',...
    'style','radiobutton','string',prompt1,...
    'position',[0.05 0.40  0.50 0.05], 'fontsize',10, ...
    'callback', {@call_mod_value,'dx'});
  prompt2 = strcat('Interval start (current value = ',num2str(xstart),'):');
  uicontrol('units','normalized', 'style','text','string', ...
    '                         ','position',[0.25 0.35 0.25 0.05], ...
    'fontsize',10,'BackgroundColor','w');
  h_rb(2) = uicontrol('units','normalized',...
    'style','radiobutton','string',prompt2,...
    'position',[0.05 0.35 0.50 0.05], 'fontsize',10, ...
    'callback', {@call_mod_value,'xstart'});
  prompt3 = strcat('Interval end (current value = ',num2str(xstop),'):');
  uicontrol('units','normalized', 'style','text','string', ...
    '                         ','position',[0.25 0.30 0.25 0.05], ...
    'fontsize',10,'BackgroundColor','w');
  h_rb(3) = uicontrol('units','normalized',...
    'style','radiobutton','string',prompt3,...
    'position',[0.05 0.30  0.50 0.05], 'fontsize',10, ...
    'callback', {@call_mod_value,'xstop'});
  prompt4 = strcat('Number of points (current value = ',num2str(nx),'):');
  uicontrol('units','normalized', 'style','text','string', ...
    '                         ','position',[0.25 0.25 0.25 0.05], ...
    'fontsize',10,'BackgroundColor','w');
  h_rb(4) = uicontrol('units','normalized',...
    'style','radiobutton','string',prompt4,...
    'position',[0.05 0.25  0.50 0.05], 'fontsize',10, ...
    'callback', {@call_mod_value,'nx'});
% Wait for an answer about the roundnumber values:
   uiwait;
   
   if get(h_rb(1),'value') 
       prompt5 = strcat('Enter new step size (min=',...
           num2str(0.0001),', max=',num2str(arg_xmax-arg_xmin),'):');
       answer = inputdlg(prompt5);
       if (length(answer) > 0)
          dx = str2num(answer{1});
          changed(1) = 1;
       end
   elseif get(h_rb(2),'value')
       prompt6 = strcat('Enter new interval start value (min=',...
           num2str(arg_xmin),', max=',num2str(arg_xmax),'):');
       answer = inputdlg(prompt6);
       if (length(answer) > 0)
          xstart = str2num(answer{1});
          changed(2) = 1;
          if changed(3)
             nx = fix((xstop - xstart)/dx + 1.0001);
          else
             nx = fix((arg_xmax - xstart)/dx + 1.0001);
          end
          xstop = xstart + (nx-1)*dx;
       end
   elseif get(h_rb(3),'value')
       prompt7 = strcat('Enter new interval end value (min=',...
           num2str(xmin),', max=',num2str(xmax),'):');
       answer = inputdlg(prompt7);
       if (length(answer) > 0)
          xstop = str2num(answer{1});
          changed(3) = 1;
          if changed(2)          
             nx = fix((xstop - xstart)/dx + 1.0001);
          else
             nx = fix((xstop - arg_xmin)/dx + 1.0001);
          end
          xstart = xstop - (nx-1)*dx;
       end
   elseif get(h_rb(4),'value')
       if changed(2) && changed(3)
           prompt8 = strcat('Enter new number of points (min=2, max=', ...
              num2str(fix((xmax-xmin)/dx + 1.0001)),'):');
       elseif changed(2)
          prompt8 = strcat('Enter new number of points (min=2, max=', ...
              num2str(fix((arg_xmax-xmin)/dx + 1.0001)),'):');
       elseif changed(3)
           prompt8 = strcat('Enter new number of points (min=2, max=', ...
           num2str(fix((xmax-arg_xmin)/dx + 1.0001)),'):');
       else
           prompt8 = 'Enter new number of points (min=2):';
       end
       answer = inputdlg(prompt8);
       if (length(answer) > 0)
          nx = fix(str2num(answer{1}));
          changed(4) = 1;
          dx = (xstop - xstart)/nx;
       end
   end

   v1 = get(h_rb(1),'value');
   v2 = get(h_rb(2),'value');
   v3 = get(h_rb(3),'value');
   v4 = get(h_rb(4),'value');
   % Reconcile values if something has changed:
   if v1+v2+v3+v4 > 0
      [dx1 xstart1 xstop1 nx1] = gridcheck(dx,xstart,xstop,nx,...
                       arg_xmin,arg_xmax,changed);
   else
       dx1 = dx;
       xstart1 = xstart;
       xstop1 = xstop;
       nx1 = nx;
   end
   dx = dx1;
   xstart = xstart1;
   xstop = xstop1;
   nx = nx1;
% Was the DONE button selected?
   done = get(h_done,'UserData');
end