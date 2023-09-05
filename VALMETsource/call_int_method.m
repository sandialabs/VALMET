function call_int_method(src,eventdata,method) 
%  callback for grid type selections 
%  When one type of interpolation is selected, unset all the others.

global h_rb;

switch method
    case 'linear'
        turned_on = get(h_rb(1),'value');
        if turned_on
            set(h_rb(2), 'value', 0);
%            set(h_rb(3), 'value', 0);
        end
        uiresume;
    case 'spline'
        turned_on = get(h_rb(2),'value');
        if turned_on
            set(h_rb(1), 'value', 0);
%            set(h_rb(3), 'value', 0);
        end
        uiresume;
%    case 'nn    '
%        turned_on = get(h_rb(3),'value');
%        if turned_on
%            set(h_rb(1), 'value', 0);
%            set(h_rb(2), 'value', 0);
%        end
%        uiresume;
end
%  end call_int_method