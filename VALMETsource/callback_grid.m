function callback_grid(src,eventdata,gridtype) 
%  callback for grid type selections 
%
global h_rb;

switch gridtype
    case 'expgrid     '
        turned_on = get(h_rb(1),'value');
        if turned_on
            set(h_rb(2), 'value', 0);
            set(h_rb(3), 'value', 0);
        end
        uiresume;
    case 'compgrid    '
        turned_on = get(h_rb(2),'value');
        if turned_on
            set(h_rb(1), 'value', 0);
            set(h_rb(3), 'value', 0);
        end
        uiresume;
    case 'roundnumbers'
        turned_on = get(h_rb(3),'value');
        if turned_on
            set(h_rb(1), 'value', 0);
            set(h_rb(2), 'value', 0);
        end
        uiresume;
end
%  end callback_grid