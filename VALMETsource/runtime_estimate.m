function  runtime_estimate(np,regression_form)
%  Run time estimate for the bounds iterations.

pd3runtime =     [.0016 .0022 .0038 .0173 .0162 .0281 .0206 .0222 .0039 ...
                  .0011 .0026 .0091 .0306 .0509 .0068];
pIII931runtime = [.0134 .0200 .0244 .0318 .0427 .0556 .0560 .0920 .0160 ...
                  .0167 .0151 .0475 .1687 .2811 .0291];
              
%  Very rough running time estimate:
pIII931minutes = fix(np*pIII931runtime(regression_form) + 0.5);
pd3minutes = fix(np*pd3runtime(regression_form) + 0.5);
if pIII931minutes == 0 
   pIII931minutes = 1;
end
if pd3minutes == 0 
   pd3minutes = 1;
end

h_wait = figure('visible','on');
uicontrol(h_wait,'units','normalized', 'style','text','string',...
     'Rough estimates of time to calculate the confidence intervals:', ...
     'position',[0.0 0.60 0.90 0.05], 'fontsize',10);
uicontrol(h_wait,'units','normalized', 'style','text','string',...
     ['931 MHz Pentium III:                    ',num2str(pIII931minutes), ...
      ' minute(s)'], 'position',[0.0 0.50 0.90 0.05], 'fontsize',10);
uicontrol(h_wait,'units','normalized', 'style','text','string',...
     ['2.2 GHz Athlon 64 X2 / 3 Ghz Pentium D: ',num2str(pd3minutes), ...
     ' minute(s)'], 'position',[0.0 0.40 0.90 0.05], 'fontsize',10);
uicontrol(h_wait,'units','normalized', 'style','text','string',...
     'Ignore the many warning messages produced by MATLAB.', ...
     'position',[0.0 0.30 0.70 0.05], 'fontsize',10);
pause(4);
close(h_wait);