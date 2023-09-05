function call_done(q1,eventdata)
%  When called, set UserData = 1 and execute uiresume.
%
set (q1,'UserData',1);
uiresume;
%  end of call_done