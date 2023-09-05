function [newcoefs1] = update_ip(coefs1,scaling)
%
global  h_rb;

ncoords = length(coefs1);
h_rb = zeros(1,ncoords);
newcoefs1 = coefs1;

%  Create a DONE button to finish accepting the changes:
h_done = uicontrol('units','normalized','style','pushbutton',...
    'string','DONE','fontsize',12, ...
    'position',[0.65 0.30  0.1 0.05], ...
    'callback',{@call_done});
set (h_done,'UserData',0);

uicontrol('units','normalized', 'style','text','string',...
    'Change initial-point coordinates.  When completely done click "DONE"',...
    'position',[0.0 0.60 0.80 0.05], 'fontsize',10, 'BackgroundColor','w');
uicontrol('units','normalized', 'style','text','string', 'Current values',...
    'position',[0.15 0.55 0.20 0.05], 'fontsize',10, 'BackgroundColor','w');

done = 0;
%  Allow changes to the initial-point coordinates. 
while (done == 0)
    for i=1:ncoords
       prompt = strcat(['c',num2str(i),':','          ', ...
           num2str(newcoefs1(i) .* scaling(i))]);
       h_rb(i) = uicontrol('units','normalized',...
              'style','radiobutton','string',prompt,...
              'position',[0.05 0.55-0.05*i  0.50 0.05], 'fontsize',10, ...
              'callback', {@call_mod_ip,num2str(i)}, 'BackgroundColor','w');
    end

% Wait for an answer:
   uiwait;
   for i=1:ncoords
      if get(h_rb(i),'value')
         answer = inputdlg(strcat('Enter new c',num2str(i),': '));
         if ~isnan(str2double(answer{1}))
            newcoefs1(i) = str2double(answer{1})./scaling(i);
         end
      end
   end
  
% Was the DONE button selected?
   done = get(h_done,'UserData');
end