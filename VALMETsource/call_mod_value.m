function call_mod_value(handle,eventdata,method) 
%
%global rb_yes rb7 rb8 rb9 rb_lin rb_spline rb_nn h_f3 ...
%    rb_dx rb_xstart rb_xstop rb_nx;
global h_rb;   %  callbacks correspond to: dx, xstart, xstop, nx

%  callback for modify roundnumber parameter values 
%
switch method
    case 'dx'
        turned_on = get(h_rb(1),'value');
        if turned_on
            set(h_rb(2), 'value', 0);
            set(h_rb(3), 'value', 0);
            set(h_rb(4), 'value', 0);
        end
        uiresume;
    case 'xstart'
        turned_on = get(h_rb(2),'value');
        if turned_on
            set(h_rb(1), 'value', 0);
            set(h_rb(3), 'value', 0);
            set(h_rb(4), 'value', 0);
        end
        uiresume;
    case 'xstop'
        turned_on = get(h_rb(3),'value');
        if turned_on
            set(h_rb(1), 'value', 0);
            set(h_rb(2), 'value', 0);
            set(h_rb(4), 'value', 0);
        end
        uiresume;
    case 'nx'
        turned_on = get(h_rb(4),'value');
        if turned_on
            set(h_rb(1), 'value', 0);
            set(h_rb(2), 'value', 0);
            set(h_rb(3), 'value', 0);
        end
        uiresume;
    otherwise
        call_mod_value_unknown_method = 1
end