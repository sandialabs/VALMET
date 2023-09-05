function [button_num] = chooseonetextbutton(choice_question,labels, ...
    handle, xp,yp)
%  Select one radio button with text labels out of several buttons. 
%  Latest revision:  
%  01/27/06 HJI Initial version.
%  05/22/06 HJI Changed callback structure from string to function call. 
%   5/24/06 HJI Added arguments handle,xp, and yp so that the question and 
%               buttons can be placed where wanted.

global h_rb;

firsttime = true;
%h_choose_text_button = figure('visible','on');
uicontrol(handle,'units','normalized','style','text',...
    'string',choice_question,...
    'position',[xp yp 1.0 0.05], 'fontsize',10);

num_labels = length(labels);
h_rb = zeros(num_labels,1);
button_num = 0;
while button_num == 0
   xpos = 0.0;
   ypos = yp - 0.05;

   for i=1:num_labels
      dx = 0.0125*length(labels{i})+0.05;
      xend = xpos + dx;
      if (xend > .99)
         xpos = 0.0;
         xend = xpos + dx;
         ypos = ypos - 0.06;
      end
      h_rb(i) = uicontrol(handle,'units','normalized',...
         'style','radiobutton','string',labels(i),...
         'position',[xpos ypos dx 0.05], 'fontsize',10, ...
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
        'position',[0.25 ypos  0.1 0.05], 'callback',{@call_done}');
      set (h_done,'UserData',0);
      set (h_done,'value',0);
   end
   uiwait;

   for i=1:num_labels
      if (get(h_rb(i),'UserData') == 1)  
         button_num = i;
      end
   end
%  Can't leave until a button has been selected.
end
% Ghost or clear buttons
for i=1:num_labels
   set(h_rb(i),'Enable','off');
end
set(h_done,'Visible','off');
%  end of chooseonetextbutton