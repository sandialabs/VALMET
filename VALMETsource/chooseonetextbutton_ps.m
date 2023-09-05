function [button_num] = chooseonetextbutton_ps(choice_question,prefixes,...
                 suffixes, handle,xp,yp)
%  Select one radio button with text labels out of several buttons. 
%  The buttons are preceeded by prefixes and followed by suffixes.
%  Revision log:  
%   2/06/06 HJI Working version.
%   4/07/06 HJI Modified to keep prefix, button, and suffix on one line.
%   5/20/06 HJI Changed callback definitions from strings to function calls.  
%   5/24/06 HJI Added arguments handle,xp, and yp so that the question and 
%               buttons can be placed where wanted.

global h_rb;

firsttime = true;
%h_choose_text_button = figure('visible','on');
uicontrol(handle,'units','normalized','style','text',...
    'string',choice_question,...
    'position',[xp yp 1.0 0.05], 'fontsize',10);
   
num_labels = length(suffixes);
h_rb = zeros(num_labels,1);
button_num = 0;
%  Stay in the while loop until the NEXT button is chosen.  This allows
%  the user to change his choice before leaving the page.
while button_num == 0
   xpos = 0.0;
   ypos = yp - 0.05;

   for i=1:num_labels
      dxp = 0.0125*length(prefixes{i});
      dxs = 0.0125*length(suffixes{i}) + 0.05;
      dx = dxp + dxs;
      xend = xpos + dx;
      if (xend > .99)
         xpos = 0.01;
         xend = xpos + dx;
         ypos = ypos - 0.06;
      end
      uicontrol(handle,'units','normalized',...
         'style','text','string',prefixes{i},...
         'position',[xpos ypos dxp 0.05], 'fontsize',10);
      xpos = xpos + dxp;
      h_rb(i) = uicontrol(handle,'units','normalized',...
         'style','radiobutton','string',suffixes{i},...
         'position',[xpos ypos dxs 0.05], 'fontsize',10, ...
         'callback', {@callback_exclusive_rbuttons,num_labels,i});
      set(h_rb(i),'UserData',0);
      set(h_rb(i),'value',0);
      xpos = xend;
   end

%  First time through, create a NEXT button to allow the button selection 
%  to end the button choice:
   if (firsttime)
      firsttime = false;
      ypos = ypos - 0.10;
      h_done = uicontrol(handle,'units','normalized',...
       'style','pushbutton', 'string','NEXT','fontsize',12, ...
       'position',[0.5 ypos  0.1 0.05], 'callback',{@call_done});
      set (h_done,'UserData',0);
      set (h_done,'value',0);
   end

   uiwait;

%  Can't leave until a button has been selected:
   for i=1:num_labels
      if (get(h_rb(i),'value') == 1)  
         button_num = i;
      end
   end
end
% Ghost or clear buttons
for i=1:num_labels
   set(h_rb(i),'Enable','off');
end
set(h_done,'Visible','off');
%  end of chooseonetextbutton_ps