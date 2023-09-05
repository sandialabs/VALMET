function call_mod_ip(handle,eventdata,method) 
%
global h_rb;  
%  callback for modify initial-point coordinate values 
nmethods = length(h_rb);
nm = str2double(method);
turned_on = get(h_rb(nm),'value');
if turned_on
   for j=1:nmethods
      if j ~= nm
          set(h_rb(j),'value',0);
      end
   end
end
uiresume;