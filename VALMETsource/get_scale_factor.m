function [vfactor vlabel] = get_scale_factor(yposition, vartype, askfor)

%global rb_yes rb7 rb8 rb9 rb_lin rb_spline rb_nn h_f3 ...
%     rb_dx rb_xstart rb_xstop rb_nx;

rb_yes = [];
vfactor = 0;
vlabel = ' ';

tx5 = uicontrol('units','normalized', 'style','text', 'string',...
  ['Do you want to multiply the ' vartype  ...
  ' variable by a scale factor?'],...
  'position',[0.0 yposition 0.80 0.05], 'fontsize',10);

rb_yes = uicontrol( 'units','normalized',...
  'style','radiobutton','string','YES',...
  'position',[0.04 yposition-0.05 0.10 0.05], 'callback', {@call_settrue});

rb_no = uicontrol( 'units','normalized',...
  'style','radiobutton','string','NO',...
  'position',[0.16 yposition-0.05 0.10 0.05], 'callback', {@call_resume});

set(rb_yes,'value',0);
set(rb_yes,'UserData',0)

% Wait for an answer
uiwait;
   
ansv = get(rb_yes,'value');
if ansv
   factorcell = inputdlg('Enter the scale factor:');
   vfactor = str2num(factorcell{1});    
end
if (askfor)
   labelcell = inputdlg(['Enter a caption with (units) for the ' ...
       vartype ' variable:']);
   vlabel = labelcell{1};
end
%  end get_scale_factor
% ==============================================================
