function callback_rbuttons(h1,eventdata)
%  When called, toggle UserData between 0 and 1 
%
if (get(h1,'UserData') == 1)
   set (h1,'UserData',0);
else
   set (h1,'UserData',1);
end
%  end callback_rbuttons
