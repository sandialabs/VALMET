function  callback_exclusive_rbuttons(h1,eventdata,num_rb,k)
%  When called, toggle UserData and value for the selected button between
%  0 and 1.
%  If UserData = 1, then set UserData = 0 and value = 0 for all the 
%  remaining buttons.

global h_rb;

if (get(h1,'UserData') == 1)
   set (h1,'UserData',0);
   set (h1,'Value',0);
else
   set (h1,'UserData',1);
   set (h1,'Value',1);
%  Clear all other buttons:
   for i=1:num_rb
       if (i ~= k)
           set(h_rb(i),'UserData',0);
           set(h_rb(i),'Value',0);
       end
   end
end
%  end of callback_exclusive_rbuttons
