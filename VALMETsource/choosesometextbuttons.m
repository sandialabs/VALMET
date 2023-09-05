function [button_num] = choosesometextbuttons(choice_question,labels, ...
    handle, xp,yp)
%  Select one or more radio button with text labels out of several buttons. 
%  Omit buttons and text for numbers in omit_list.
%  Revision log:  
%   2/17/06 HJI Initial version (taken from validation_2d, selection of
%               columns of experimental data).
%   2/27/06 HJI If there is only one button choice, select that choice
%               and skip the interactive button request.
%   5/22/06 HJI Changed callback definitions from strings to function calls. 

global h_rb;

num_labels = length(labels);
% If there is only one choice, select it and skip the interactive choice mode.
if num_labels == 1
  button_num = 1;
  return
end

h_rb = zeros(num_labels,1);
button_num = [];
while isempty(button_num)
%   h_choose_text_button = figure('visible','on');
   uicontrol(handle,'units','normalized','style','text',...
    'string',choice_question,'position',[xp yp 1.0 0.05],'fontsize',11,  ...
    'BackgroundColor','w');

   xpos = xp;
   ypos = yp - 0.10;

   for i=1:num_labels
      dx = 0.0125*length(labels{i})+0.10;
      xend = xpos + dx;
      if (xend > .99)
         xpos = 0.01;
         xend = xpos + dx;
         ypos = ypos - 0.06;
      end

      h_rb(i) = uicontrol(handle,'units','normalized',...
         'style','radiobutton','string',labels(i),...
         'position',[xpos ypos dx 0.05], 'fontsize',10, ...
         'BackgroundColor','w', 'callback', {@callback_rbuttons});
     
     set(h_rb(i),'UserData',0);
      xpos = xend;
   end
%  Create a NEXT button to allow the button selection to end:
   ypos = ypos - 0.07;

   h_done = uicontrol(handle,'units','normalized', 'style','pushbutton',...
    'string','NEXT','fontsize',12, 'position',[0.5 ypos  0.1 0.05], ...
    'BackgroundColor','w', 'callback',{@call_done}');

   ypos = ypos - 0.10;
   set (h_done,'UserData',0);
   uiwait;
   
   k=0;
   for i=1:num_labels 
      if (get(h_rb(i),'value') == 1)
         k = k+1;
         button_num(k) = i;
      end
   end
   if isempty(button_num) 
%  Can't leave until a button has been selected.
      uicontrol(handle,'units','normalized', 'style','text','string',...
       'You must select at least one button',...
       'position',[0.00 ypos 0.60 0.05], 'fontsize',10, 'BackgroundColor','w');
      pause (2);      
   end
end
%close (h_choose_text_button);