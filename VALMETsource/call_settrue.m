function call_settrue(h1,eventdata)
%  When called, set UserData = 1 and set value = 1.
%
set (h1,'UserData',1);
set (h1,'value',1);
uiresume;
%  end call_settrue