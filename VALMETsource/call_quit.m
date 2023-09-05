function call_quit(q1,eventdata)
%  When called, set UserData = 1
%
set (q1,'UserData',1);
uiresume;
%   end call_quit