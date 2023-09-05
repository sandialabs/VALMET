% Copyright (2009) Sandia Corporation. Under the terms of 
% Contract DE-AC04-94AL85000, there is a non-exclusive license
% for use of this work by or on behalf of the U.S. Government. 
% Export of this program may require a license from the 
% United States Government.
%function VALMET
%  VALMET.m:  evaluate validation metrics for a 1-dimensional
%  problem. (2-D coding is started but is incomplete).
%
%  Revision log for the past 12 months:
%  11/15/06 HJI Added options statements to the bounds routines.  
%               Added second pass to bounds optimization.  beta version 1.4
%  12/12/06 HJI Corrected coding to process multiple files of experimental 
%               data.                                beta version 1.5
%   4/17/07 HJI Added gradient calculation and multiple initial
%               coefficients to bounds_step1.        beta version 1.6
%   4/23/07 HJI Added Lorentzian regression form.    beta version 1.7.
%   8/19/07 HJI Increased tolerances TolCon and TolFun.  Beta version 1.8.   
%   8/29/07 HJI Added calculation and print of avg_rel_conf_indicator and 
%               ci_for_max_rel_err_metric for regression option.  
%                                                      beta version 1.9.
%   9/09/07 HJI Changed bounds routines to use regression round-number grid.
%               Added tolcon and tolfun as arguments to bounds routines so
%               that their values can be passed in from the main program.
%                                                       beta version 2.0.
%   9/13/07 HJI Minor fixes (missing plot title, round-number grid
%               inconsistencies, timing estimates, ...).  Tested all 
%               regression functions.                 beta version 2.1.
%  10/04/07 HJI Added the ability to change the iteration starting point.
%                                                     beta version 2.2.
%  10/10/07 HJI Added scaling to pulse regression function.
%                                                Production version 1.0.

global h_rb xmagn ymagn c3c5magn

clear all
timestamp_y_place = -0.12;
%  Display cover sheet:
h_intro = figure('visible','on');
uicontrol(h_intro,'units','normalized','style','text','string',...
  'Validation and Uncertainty Quantification Program, version 1.0 (10/10/07)',...
  'position',[0.00 0.80 1.00 0.10], 'fontsize',12);
pause (1);

q1='Do you want a text output file with experimental, computational, and CI data?';
labels{1} = 'yes';
labels{2} = 'no' ;
answer = chooseonetextbutton(q1,labels, h_intro, 0.0, 0.75);
fid = 0;
if (answer == 1)
    while (fid <= 0)
        outputfilenamecell = {''};
        while strcmp(outputfilenamecell,{''})
           outputfilenamecell = ...
               inputdlg('Enter a name for the output text data file: ');
        end
        outputfilename = outputfilenamecell{1};
        fid = fopen(outputfilename,'w');
    end
end

if fid == 0
   q2='Do you want the date and time appended to the plots?';
else
   q2='Do you want the date and time appended to the plots and text output file?';
end
answer = chooseonetextbutton(q2,labels, h_intro, 0.,0.65);
if (answer == 1)
   appendtimestamp = true;
else
   appendtimestamp = false;
end

q3='Are the experimental data in one file or multiple files?';
labels{1} = 'All data in one file';
labels{2} = 'Data in multiple files';
multiple_files = chooseonetextbutton(q3,labels, h_intro, 0.,0.55);
if multiple_files == 2 
   uicontrol(h_intro,'units','normalized','style','text','string',...
      'Current restrictions on multiple input files: ',...
      'position',[0.00 0.45 1.00 0.10], 'fontsize',10);
     uicontrol(h_intro,'units','normalized','style','text','string',...
      ' 1) one column of data per file,',...
      'position',[0.00 0.40 1.00 0.10], 'fontsize',10);
     uicontrol(h_intro,'units','normalized','style','text','string',...
      ' 2) same number of values in each column,',...
      'position',[0.00 0.35 1.00 0.10], 'fontsize',10);
     uicontrol(h_intro,'units','normalized','style','text','string',...
      ' 3) same x-values for each column.',...
      'position',[0.00 0.30 1.00 0.10], 'fontsize',10);
   pause (10);
end
close(h_intro);

filecount = 0;
total_ecolumns = 0;
moredata = true;
while moredata
   filecount = filecount + 1;
%  Request the experimental data:  xe will be a numeric ndim by nex array.
%          ve will be a numeric necols by nex array.
   [xe nxecol ve e_column_nums ex_label evar_label quitflag] = ...
              request_datafile('EXPERIMENTAL',filecount == 1);
   
%  if quitflag
%     return
%  end
   necols = length(e_column_nums);
   nex = length(xe);
   if filecount == 1
      ex_label1 = ex_label;
      evar_label1 = evar_label;
% Retrieve the independent-variable units if in parentheses
      x_units = ' ';
      [lpar0 lpar1] = regexp(ex_label1,'(');
      [rpar0 rpar1] = regexp(ex_label1,')');
      if (lpar1 > 0 & rpar1 > 0)
         textchars = ex_label1';
         x_units = textchars(lpar1:rpar1)';
      end
   end

%Current restrictions on multiple input files: 
% 1) one column of data per file,
% 2) same number of values in each column,
% 3) same x-values for each column.
   if multiple_files == 2
      xcell{filecount} = xe;
      vecell{filecount} = ve;
      ecolnumscell{filecount} = e_column_nums;
      total_ecolumns = necols + total_ecolumns;
      h_more_files = figure('visible','on');
      q1='Do you want to read another data file?';
      labels{1} = 'yes';
      labels{2} = 'no' ;
      answer = chooseonetextbutton(q1,labels, h_more_files, 0.0, 0.50);
      moredata = (answer == 1);
      close(h_more_files);
      if ~moredata
         [xe_grid] =  exp_gridchoice(xcell,x_units);    
      end
   else
      moredata = false;
   end
end

if multiple_files == 2
    for i = 1:filecount 
        ve(:,i) = vecell{i};
        e_column_nums(i)= ecolnumscell{i};
    end
    necols = filecount;
end


ndims = length(nxecol);
%  Get the independent variable(s) (up to 3):
% !!!    W A R N I N G :
%     This coding is not complete for ndims > 1: In 2 dimensions, columns 
%     of x and y data will most likely be nex*ney long, and some 
%     non-trivial coding will be necessary to figure out nex and ney,
%     or else the y values will be in a separate row, which is not
%     allowed for by the current request_datafile script.
%if ndims == 1
%   xe = exp_data(:,nxecol);
%else
%   xe = exp_data(:,nxecol(1));
%end
%nex = length(xe);
%if ndims > 1
%    ye = exp_data(:,nxecol(2));
%    ney = length(ye);
%end
%if ndims > 2
%    ze = exp_data(:,nxecol(3));
%    nez = length(ze);
%end
%close(h_choose_cols);

degrees_of_freedom = necols-1;

% Retrieve the dependent-variable units if in parentheses
v_units = ' ';
[lpar0 lpar1] = regexp(evar_label1,'(');
[rpar0 rpar1] = regexp(evar_label1,')');
if (lpar1 > 0 & rpar1 > 0)
   textchars = evar_label1';
   v_units = textchars(lpar1:rpar1)';
end
    
% If it was requested, write the experimental data to a file:
if (fid > 0)
   if appendtimestamp
       timestamp = date_and_time();
       fprintf(fid,'%s\r\n',timestamp);
   end
   fprintf(fid,'%s\r\n','experimental data');
   fprintf(fid,'%s\r\n',ex_label1);
   fprintf(fid,'%s\r\n',evar_label1);
   fprintf(fid,'%4d %4d\r\n', necols, nex);
%  column headings:
   fprintf(fid,'%s','     xe     ');
   if ndims > 1
      fprintf(fid,'%s','     ye     ');
   end    
   if ndims > 2
      fprintf(fid,'%s','     ze     ');
   end
   for i=e_column_nums
      fprintf(fid,'   col_%d     ',i);
   end
   fprintf(fid,'\r\n');

   for i=1:nex
      fprintf(fid,'%12.3e',xe(i));
      if (ndims > 1)
          fprintf(fid,'%12.3e',ye(i));
      end
      if (ndims > 2)
          fprintf(fid,'%12.3e',ze(i));
      end

      for j=1:necols
          fprintf(fid,'%12.3e',ve(i,j));
      end
      fprintf(fid,'\r\n'); 
   end
end


%  Request the computational data:
nccols = 0;
nxccol = [];
[xc nxccol vc c_column_nums cxlabel cvar_label quitflag] = ...
        request_datafile('COMPUTATIONAL',false);
%comp_data = sortrows(u_comp_data,nxccol);
nccols = length(c_column_nums);

%if quitflag
%    return
%end

%  Get the independent variable(s) (up to 3):
ncomp = length(xc);
nccols = length(c_column_nums);
%if ndims == 1
%   xc = comp_data(:,nxccol);
%else
%   xc = comp_data(:,nxccol(1));
%end
%if ndims > 1
%   yc = comp_data(:,nxccol(2));
%end
%if ndims > 2
%    zc = comp_data(:,nxccol(3));
%end

if (fid > 0)
   fprintf(fid,'\r\n%s\r\n','computational data');
% experimental and computational variables should have the same names.
   fprintf(fid,'%s\r\n',ex_label1);
   fprintf(fid,'%s\r\n',evar_label1);
   fprintf(fid,'%4d %4d\r\n', nccols, ncomp);

   %  column headings:
   fprintf(fid,'%s','     xc     ');
   if ndims > 1
      fprintf(fid,'%s','     yc     ');
   end    
   if ndims > 2
      fprintf(fid,'%s','     zc     ');
   end
   for i=c_column_nums
      fprintf(fid,'   col_%d     ',i);
   end
   fprintf(fid,'\r\n');
   
   for i=1:ncomp
      fprintf(fid,'%12.3e',xc(i));
      if (ndims > 1)
          fprintf(fid,'%12.3e',yc(i));
      end
      if (ndims > 2)
          fprintf(fid,'%12.3e',zc(i));
      end
      for j=1:nccols
          fprintf(fid,'%12.3e',vc(i,j));
      end
      fprintf(fid,'\r\n'); 
   end
end

analyze_again = true;
while analyze_again
   timestamp = date_and_time();
   h_analysis = figure('visible','on');
% Request the desired confidence interval:
% (This version of the program can use any confidence interval between
%  0 and 100 percent, but the request specifies a practical range of 50 to 
%  99.99%)
   conf_int = 0;
   while (conf_int <= 0. || conf_int >= 1.0)
      cicell = {''};
      while strcmp(cicell,{''})
      cicell = inputdlg('What % confidence interval do you want (50 to 99.99)?');
      end
      conf_int = 0.01*str2num(cicell{1});
   end
   close(h_analysis);

   h_process = figure('visible','on');
%  Choose between data interpolation and regression:
   question = ' Do you want to use interpolation or regression on the data?';
   labels{1} = 'interpolation';
   labels{2} = 'regression';
   numchoice = chooseonetextbutton(question,labels, h_process, 0.,0.9);
   pause(1);
   close(h_process);

   if numchoice == 1    
%  Omit the endpoints that are outside the overlapping region of the 
%  experimental and computational data.
%  Start with experimental data endpoints:
      nxei = 1;
      while (xe(nxei) < xc(1))
         nxei = nxei + 1;
      end
      nxef = nex;
      while (xe(nxef) > xc(ncomp))
         nxef = nxef -1;
      end
      exp_spacing = (xe(nxef)-xe(nxei))/(nxef-nxei);

%  Find computational data endpoints that bound the experimental 
%  data
      nxci = 1;
      while (xc(nxci) < xe(1))
         nxci = nxci + 1;
      end
      nxcf = ncomp;
      while (xc(nxcf) > xe(nex))
         nxcf = nxcf - 1;
      end
      comp_spacing = (xc(nxcf)-xc(nxci))/(nxcf-nxci);

%  Work out round number endpoints that are bounded by 
%  both the experimental and computational data.
      xstart = max ([xc(1) xe(1)]);
      xend = min ([xc(ncomp) xe(nex)]);
      logdiff = log10(xend - xstart);
      xstep = 10^(floor(logdiff)-1);
      nsteps = fix((xend-xstart)/xstep);
   %  Choose xstep to give between 15 and 150 steps
      if nsteps > 150
         xstep = 10*xstep;
      elseif nsteps < 15
         xstep = 0.1*xstep;
      end
      xstart = xstep*ceil(xstart/xstep);
      xend = xstep*floor(xend/xstep);
      nsteps = fix((xend-xstart)/xstep);

      interp_grid = ' ';
      interp_method = ' ';
%  Create a window with the interpolation grid and method choices
      process = 'interpolation';
      [interp_grid,interp_method, roundstart,roundend,roundstep] = ...
          gridchoice([nxef-nxei+1,nxcf-nxci+1,nsteps+1],...
                [xe(nxei),xc(nxci),xstart], ...
                [xe(nxef),xc(nxcf),xend], ...
                [exp_spacing,comp_spacing,xstep], x_units, process);

      if strcmp(interp_grid,'experimental')
         x_interp = xe(nxei:nxef);
         nsteps = nxef-nxei;
      elseif strcmp(interp_grid,'computational')
         x_interp = xc(nxci:nxcf);
         nsteps = nxcf-nxci;
      elseif strcmp(interp_grid,'roundnumbers')
         x_interp = (roundstart:roundstep:roundend+0.0001)';
         nsteps = length(x_interp) - 1;
      end

% Obtain the interpolated computational data:
      vc_interp = interp1(xc,vc,x_interp,interp_method);
      npoints = nsteps+1;
   
% Obtain the interpolated experimental data:
      ve_interp = interp1(xe,ve,x_interp,interp_method);

% Generate global metrics
% Open window f4 for printing the metrics 
      f4 = figure('visible','on');
      f4_filename = ...
          strcat('globalmetrics_for_interp_',cicell{1},'pct.fig');
      tx_savef4 = uicontrol(f4,'units','normalized',...
         'style','text','string',...
         ['This screen will be saved as file: ' f4_filename], ...
         'position',[0.0 0.10 0.80 0.05], 'fontsize',10, ...
         'BackgroundColor','w');
%      tx_tolcon = uicontrol(f4,'units','normalized',...
%         'style','text','string', ['TolCon = ' num2str(tolcon)], ...
%         'position',[0.1 0.0 0.20 0.05], 'fontsize',8, ...
%         'BackgroundColor','w');
%      tx_tolfun = uicontrol(f4,'units','normalized',...
%         'style','text','string', ['TolFun = ' num2str(tolfun)], ...
%         'position',[0.3 0.0 0.20 0.05], 'fontsize',8, ...
%         'BackgroundColor','w');

      hgt = 0.90;
      tx_lbl1 = uicontrol(f4,'units','normalized','style','text',...
         'string','VALIDATION  METRICS', ...
         'position',[0.20 hgt 0.40 0.05], 'fontsize',12, ...
         'BackgroundColor','w');
      hgt = hgt - 0.05;

      tx_lbl2 = uicontrol(f4,'units','normalized','style','text','string',...
        ['Validation uses the ' cicell{1} '% confidence interval, ' ...
        interp_grid ' grid, ' interp_method ' interpolation.'], ...
        'position',[0.0 hgt 0.95 0.05], 'fontsize',10, ...
        'BackgroundColor','w');
      hgt = hgt - 0.10;

      if necols == 1
         ve_avg_interp = ve_interp;
      else
         ve_avg_interp = mean(ve_interp,2);
      end
% Compute the average absolute value of the average experimental data.
      avg_abs_avg = mean(abs(ve_avg_interp));
      nearly_zero = 5.e-14*avg_abs_avg;
%  Compute the average standard deviation of the average experimental
%  data.  
      ve_stddev_interp = std(ve_interp,0,2);
      avg_stddev = mean(ve_stddev_interp);
      est_error = vc_interp - ve_avg_interp;
      nz_ve_avg_interp = find(abs(ve_avg_interp) > nearly_zero);
      any_zero_ve_avg_interp = any(find(abs(ve_avg_interp) <= nearly_zero));
      
      tx_aaa = uicontrol(f4,'units','normalized',...
          'style','text','string',...
        ['Avg(abs(y-bar_e))          = ' num2str(avg_abs_avg,4) '  ' v_units],...
        'position',[0.0 hgt 0.50 0.05], 'fontsize',10, ...
        'BackgroundColor','w');
      hgt = hgt - 0.05;

%tx_asd = uicontrol(f4,'units','normalized',...
%    'style','text','string',...
%    ['Average standard deviation of experimental data = ' ...
%    num2str(avg_stddev,4) '  ' v_units],...
%    'position',[0.0 hgt 0.75 0.05], 'fontsize',10);
%hgt = hgt - 0.05;

%  The remaining metrics are dimensionless
%      avg_rel_error_metric = sum(abs(est_error))/(npoints*avg_abs_avg);
      avg_rel_error_metric = mean(abs(est_error(nz_ve_avg_interp)./ ...
            ve_avg_interp(nz_ve_avg_interp)));
      tx_are = uicontrol(f4,'units','normalized','style','text', ...
         'string',['Average relative error metric = ' ...
         num2str(avg_rel_error_metric,4)],...
         'position',[0.0 hgt 0.50 0.05], 'fontsize',10, ...
         'BackgroundColor','w');
      hgt = hgt - 0.05;

%      avg_rel_conf_indicator = tinv(conf_int,degrees_of_freedom)* ...
%         avg_stddev/(sqrt(necols)*avg_abs_avg); 
      avg_rel_conf_indicator = tinv(conf_int,degrees_of_freedom)* ...
         mean(abs(ve_stddev_interp(nz_ve_avg_interp) ./  ...
               ve_avg_interp(nz_ve_avg_interp)))/sqrt(necols); 
      tx_rci  = uicontrol(f4,'units','normalized','style','text', ...
         'string',['Average relative confidence indicator = ' ...
         num2str(avg_rel_conf_indicator,4)],... 
         'position',[0.0 hgt 0.55 0.05], 'fontsize',10, ...
         'BackgroundColor','w');
      hgt = hgt - 0.05;

%  Evaluate the maximum relative error metric:
%      max_rel_error_metric = max(abs(est_error))/avg_abs_avg;
      max_rel_error_metric = max(abs(est_error(nz_ve_avg_interp)./ ...
            ve_avg_interp(nz_ve_avg_interp)));
      tx_mre = uicontrol(f4,'units','normalized','style','text', ...
         'string', ['Maximum relative error metric = ' ...
         num2str(max_rel_error_metric,4)],... 
         'position',[0.0 hgt 0.50 0.05], 'fontsize',10, ...
         'BackgroundColor','w');
      hgt = hgt - 0.05;

% Evaluate the confidence interval for the maximum relative error metric:
%      imax = find(abs(est_error)/avg_abs_avg >= max_rel_error_metric);
%      ci_for_max_rel_err_metric = tinv(conf_int,degrees_of_freedom)* ...
%           ve_stddev_interp(imax)/(sqrt(necols)*avg_abs_avg);
      ci_for_max_rel_err_metric = tinv(conf_int,degrees_of_freedom)* ...
           max(abs(ve_stddev_interp(nz_ve_avg_interp) ./  ...
                   ve_avg_interp(nz_ve_avg_interp)))/sqrt(necols); 
      tx_cimre = uicontrol(f4,'units','normalized', 'style','text', ...
         'string',...
        ['Confidence interval for maximum relative error metric = ' ...
        num2str(ci_for_max_rel_err_metric,4)],... 
        'position',[0.0 hgt 0.70 0.05], 'fontsize',10, ...
        'BackgroundColor','w');
      hgt = hgt - 0.05;
      if appendtimestamp
         uicontrol(f4,'units','normalized', 'style','text', ...
            'string',timestamp, 'position',[0.7 0.01 0.3 0.05], ...
            'fontsize',10, 'BackgroundColor','w');
      end
      saveas(f4,f4_filename);
   
% ---------------------------------------------------------------------   
%  Plot the experimental data:
      plot_exp_data(xstart,xend, xe,ve,vc,e_column_nums,ex_label1, ...
          evar_label1,appendtimestamp,timestamp,timestamp_y_place);
   
% ---------------------------------------------------------------------
%  Select symbols to identify up to 12 sets of experimental data:
      linestyle = ['o','s','d','.','x','*','p','h','^','v','<','>'];
      vmin = min(min(vc),min(min(ve)));
      vmax = max(max(vc),max(max(ve))); 
      midpoint = fix(nex/2);
      ve_left = mean(ve(1,:));
      ve_mid = mean(ve(midpoint,:));
      ve_right = mean(ve(nex,:));

      ci_del = tinv(conf_int,degrees_of_freedom)* ...
            ve_stddev_interp/sqrt(necols);
% Open window f6 for plotting experimental data average, computational
% data, and mean +/- confidence interval.
      legend_matrix = {'experimental average';'computation';...
         ['mean + ' cicell{1} '% confidence interval']; ...
         ['mean - ' cicell{1} '% confidence interval']};
      f6 = figure('visible','on');
      vmin2 = min([vmin  min(vc_interp)  min(ve_avg_interp-ci_del)]);
      vmax2 = max([vmax  max(vc_interp)  max(ve_avg_interp+ci_del)]);
      [vstart2,vend2,vtic] = roundbounds(vmin2,vmax2,0.175);
      plot(x_interp,ve_avg_interp,'-ok',x_interp,vc_interp,'- .b',...
          x_interp,ve_avg_interp + ci_del,'- .g', ...
          x_interp,ve_avg_interp - ci_del,'- .r')
      axis([xstart xend vstart2 vend2]);
      xlabel(ex_label1);
      ylabel(evar_label1);
      title ({strcat(['Experimental mean with ' cicell{1}], ...
         '% confidence interval and computational result'); ...
        [interp_grid ' grid, ' interp_method ' interpolation.']});
      grid on;
      legend_corner = legend_location(ve_left,ve_mid,ve_right);
      legend(legend_matrix,'Location',legend_corner);
      if appendtimestamp
         xtpos = xstart + 0.75*(xend-xstart);
         ytpos = vstart2 + timestamp_y_place*(vend2-vstart2);
         text(xtpos,ytpos,timestamp, 'BackgroundColor','w');
      end
      hold off
      saveas(f6,strcat('comp_and_exp_mean_with_',cicell{1},'pct_ci.fig'));

% ---------------------------------------------------------------------
% Open window f7 for plotting validation metric result with 
% confidence interal.
      onethird = int32(nsteps/3);
      twothirds = int32(2*nsteps/3);
      ve_left = mean(est_error(1:onethird)); 
      ve_mid = mean(est_error(onethird:twothirds));
      ve_right = mean(est_error(twothirds:nsteps+1));

      f7 = figure('visible','on');
      vmin3 = min(min(est_error),min(-ci_del));
      vmax3 = max(max(est_error),max( ci_del));
      [vstart3,vend3,vtic] = roundbounds(vmin3,vmax3,0.175);
      legend_matrix = {'Estimated computational error';...
         ['+',cicell{1},' confidence interval']; ...
         ['-',cicell{1},' confidence interval']}; 
      plot(x_interp,est_error,'- .k',x_interp,ci_del,'- .g',...
         x_interp,-ci_del,'- .r');
      axis([xstart xend vstart3 vend3]);
      xlabel(ex_label1)
      ylabel(['estimated error of computation and experimental CI '...
             v_units]);
      title ({strcat(['Validation metric result and ' cicell{1}], ...
         '% confidence interval'); ...
        [interp_grid ' grid, ' interp_method ' interpolation.']});
      legend_corner = legend_location(ve_left,ve_mid,ve_right);
      legend(legend_matrix,'Location',legend_corner);
      grid on;
      if appendtimestamp
         xtpos = xstart + 0.75*(xend-xstart);
         ytpos = vstart3 + timestamp_y_place*(vend3-vstart3);
         text(xtpos,ytpos,timestamp, 'BackgroundColor','w');
      end
      hold off
      saveas(f7,strcat('est_error_with_',cicell{1},'plus_minus_ci_del.fig'));

% ---------------------------------------------------------------------
% Open window f8 for plotting.
      f8 = figure('visible','on');
      vmin4 = min(min(est_error),min(est_error-ci_del));
      vmax4 = max(max(est_error),max(est_error+ci_del));
      [vstart4,vend4,vtic] = roundbounds(vmin4,vmax4,0.175);
      legend_matrix = {'Estimated computational error';...
        ['+',cicell{1},' confidence interval']; ...
        ['-',cicell{1},' confidence interval']}; 
      plot(x_interp,est_error,'- .k',x_interp,est_error+ci_del,'- .g',...
         x_interp,est_error-ci_del,'- .r')
      axis([xstart xend vstart4 vend4]);
      xlabel(ex_label1)
      ylabel(['error in ' evar_label1])
      title ({strcat(['Estimated error and true error in the model with ', ...
         cicell{1},'% confidence interval']); ...
         [interp_grid ' grid, ' interp_method ' interpolation.']});
      legend_corner = legend_location(ve_left,ve_mid,ve_right);
      legend(legend_matrix,'Location',legend_corner);
      grid on;
      if appendtimestamp
         xtpos = xstart + 0.75*(xend-xstart);
         ytpos = vstart4 + timestamp_y_place*(vend4-vstart4);
         text(xtpos,ytpos,timestamp, 'BackgroundColor','w');
      end
      hold off
      saveas(f8,strcat('est_error_with_',cicell{1},'pct_bounds.fig'));
% ---------------------------------------------------------------------

      if (fid > 0)
         fprintf(fid,'\r\n%s\r\n','validation metrics');
         fprintf(fid,'%s            %s\r\n',cicell{1}, ...
             'percent confidence interval');
         fprintf(fid,'%12.3e         %s\r\n',avg_abs_avg, ...
             'Avg(abs(y-bar_e))');
         fprintf(fid,'%12.3e          %s\r\n',avg_rel_error_metric, ...
             'Average relative error metric');
         fprintf(fid,'%12.3e          %s\r\n',avg_rel_conf_indicator, ...
             'Average relative confidence indicator');
         fprintf(fid,'%12.3e          %s\r\n',max_rel_error_metric, ...
             'Maximum relative error metric');
         fprintf(fid,'%12.3e          %s\r\n',ci_for_max_rel_err_metric, ...
             'Confidence interval for maximum relative error metric');
         fprintf(fid,'%s grid, %s interpolation\r\n',interp_grid, ...
             interp_method);

         fprintf(fid,'\r\n %4d %4d\r\n', 7, nsteps+1);
  %  column headings:
         fprintf(fid,'%s','      x     ');
         if ndims > 1
            fprintf(fid,'%s','      y     ');
         end    
         if ndims > 2
            fprintf(fid,'%s','      z     ');
         end
         fprintf(fid,'   exp avg  ');
         fprintf(fid,' exp avg +CI');
         fprintf(fid,' exp avg -CI');  
         fprintf(fid,'     comp   ');
         fprintf(fid,' est cmp err');
         fprintf(fid,'  true ce+CI');
         fprintf(fid,'  true ce-CI');
         fprintf(fid,'\r\n');
   
         for i=1:nsteps + 1
            fprintf(fid,'%12.3e',x_interp(i));
%      if (ndims > 1)
%          fprintf(fid,'%12.3e',yc(i));
%      end
%      if (ndims > 2)
%          fprintf(fid,'%12.3e',zc(i));
%      end
            fprintf(fid,'%12.3e',ve_avg_interp(i));
            fprintf(fid,'%12.3e',ve_avg_interp(i) + ci_del(i));
            fprintf(fid,'%12.3e',ve_avg_interp(i) - ci_del(i));
            fprintf(fid,'%12.3e',vc_interp(i));
            fprintf(fid,'%12.3e',est_error(i));
            fprintf(fid,'%12.3e',est_error(i)+ci_del(i));
            fprintf(fid,'%12.3e',est_error(i)-ci_del(i));

            fprintf(fid,'\r\n'); 
         end
      end
%  END OF THE INTERPOLATION OPTION    

   else
%  START OF THE REGRESSION OPTIONS
%  Work out round number endpoints for the confidence bounds that  
%  bound the extrema of the experimental and computational data.
      xstart = min ([xc(1) xe(1)]);
      xend = max ([xc(ncomp) xe(nex)]);
      logdiff = log10(xend - xstart);
      xstep = 10^(floor(logdiff)-1);
      nsteps = fix((xend-xstart)/xstep);
 %  Choose xstep to give between 30 and 150 steps
      if nsteps > 150
         xstep = 10*xstep;
         nsteps = fix((xend-xstart)/xstep);
      end
      if nsteps < 30
         xstep = 0.1*xstep;
         nsteps = fix((xend-xstart)/xstep);
         if nsteps > 150
             xstep = 2*xstep;
             nsteps = fix((xend-xstart)/xstep);
         end
      end
      xstart = xstep*fix(xstart/xstep);
      if xstart < min([xc(1) xe(1)])
          xstart = xstart+xstep;
      end
      xend = xstep*fix(xend/xstep + 0.1);
      if xend > 1.00001*max([xc(ncomp) xe(nex)])
          xend = xend - xstep;
      end
      nsteps = fix((xend-xstart)/xstep);
      exp_spacing = (xe(nex)-xe(1))/(nex+1);
      comp_spacing = (xc(ncomp)-xc(1))/(ncomp+1);

      process = 'regression';
      [interp_grid,interp_method, roundstart,roundend,roundstep] = ...
          gridchoice([nex,ncomp,nsteps+1],...
                [xe(1),xc(1),xstart], ...
                [xe(nex),xc(ncomp),xend], ...
                [exp_spacing,comp_spacing,xstep], x_units, process);
      
      xvalues = [roundstart:roundstep:roundend]';
      np = length(xvalues);
         
      if necols == 1
         ve_avg = ve;
      else
         ve_avg = mean(ve,2);             % curve (column vector)
      end
      avg_abs_avg = mean(abs(ve_avg));    % scalar
      nearly_zero = 5.e-14*avg_abs_avg;

      xmin = min(xc(1),xe(1));
      xmax = max(xc(ncomp),xe(nex));
%  Allow some space at both ends of the axes.
      [xstart,xend,xtic] = roundbounds(xmin,xmax,0.125);
   
% Display the available regression equations and ask for one:
      regression_form = request_regression_eqn(ndims);
   
   if ndims == 1
%  put multiple sets of experimental data into one long data set:
       if necols == 1 
           x_exp = xe;
           y_exp = ve;
       else
           x_exp = repmat(xe,necols,1);
           y_exp = reshape(ve,necols*nex,1);
       end
       ve_min = min(y_exp);
       ve_max = max(y_exp);
       if nccols == 1 
           x_comp = xc;
           y_comp = vc;
       else
           x_comp = repmat(xc,nccols,1);
           y_comp = reshape(vc,nccols*ncomp,1);
       end
       
%  TO DO: Choose computational data if there are no experimental data.       
       x_regress = x_exp;
       y_regress = y_exp;
       
%%  The first 8 regression forms are polynomial fits of degrees 1 to 8:
       if regression_form <= 8
          tolcon = 1.e-6;
          tolfun = 1.e-7;
          if regression_form > 4
              tolcon = 1.e-7;
              tolfun = 1.e-8;
          end
          if regression_form == 1
             regression_eqn = ['y = c_1 x + c_2'];             
             regression_eqn_txt = ['y = c1 x + c2'];
          elseif regression_form == 2
             regression_eqn = ['y = c_1 x^2 + c_2 x + c_3'];
             regression_eqn_txt = ['y = c1 x^2 + c2 x + c3'];  
          elseif regression_form == 3
             regression_eqn = ['y = c_1 x^3 + c_2 x^2 + c_3 x + c_4'];
             regression_eqn_txt = ['y = c1 x^3 + c2 x^2 + c3 x + c4'];  
          elseif regression_form == 4
             regression_eqn = ['y = c_1 x^4 + c_2 x^3 + c_3 x^2 + c_4 x + c_5'];
             regression_eqn_txt = ['y = c1 x^4 + c2 x^3 + c3 x^2 + c4 x + c5'];    
          else
             regression_eqn = ...
                ['y = c_1 x^n + c_2 x^n^-^1 +...+ c_n_+_1,  n=', ...
                num2str(regression_form)];
             regression_eqn_txt = ...
                ['y = c1 x^n + c2 x^(n-1) +...+ cn+1,  n=', ...
                num2str(regression_form)];
          end
          coefs = polyfit(x_exp,y_exp,regression_form);
          vxval_fit = polyval(coefs,xvalues);
          vc_fit = polyval(coefs,xc);
          sse0 = sumsqerr_poly(coefs,x_exp,y_exp);
          p = regression_form + 1;
          sseci = (1+p/(nex-p)*finv(conf_int,p,nex-p))*sse0;
%  Some fraction of the curve fit coefficients are probably the best guess 
%  for starting the iteration that finds the coefficients that bound the 
%  confidence region.
          if regression_form < 7
              mult_lower = 0.3;
              mult_upper = 1.0;
          else
              mult_lower = 0.2;
              mult_upper = 0.5;
          end
          ncoords = size(coefs);
          scaling = ones(1,ncoords);
          [nipl c0lower nipu c0upper xval_l xval_u coords_l coords_u] = ...
             select_iteration_ip(coefs,mult_lower,mult_upper,scaling, ...
             np,xvalues, regression_form, regression_eqn_txt);
          
          [flower,fupper,flower_n,fupper_n,cc_l,cc_u,sse_l,sse_u] = ...
               bounds_poly(c0lower,c0upper,xvalues, x_exp,y_exp,sseci, ...
               tolcon,tolfun);

           if (nipl == 2 || nipl == 3) && ~any(c0lower(2,:))
             coords_l(2,:) = coords_l(1,:);
             for i=2+nipl:nipl:nipl*np
                 coords_l(i,:) = cc_l(i-nipl,:);
             end
          end
          if (nipu == 2 || nipu == 3) && ~any(c0upper(2,:))
             coords_u(2,:) = coords_u(1,:);
             for i=2+nipu:nipu:nipu*np
                 coords_u(i,:) = cc_u(i-nipu,:);
             end
          end
         
       elseif regression_form == 9
%%             Form = a + b/(1+c*x)   (form109(c,x))
          tolcon = 1.e-6;
          tolfun = 1.e-7;
          regression_eqn = 'y = c_1 + c_2 / (1 + c_3 * x)';
          regression_eqn_txt = 'y = c1 + c2 / (1 + c3 * x)';     
%  The initial guess at the regression coefficients depends on whether
%  the curve is concave upwards or downwards:
          mid = fix(nex/2);
          concavity = 0.5*(ve(1, 1) + ve(nex, 1)) - ve(mid, 1);
          trend = ve(nex,1) - ve(1,1);
          if concavity >= 0.
             coef0(1) = 1.3*min(y_regress);
          else
             coef0(1) = 1.3*max(y_regress);
          end
 %  If the direction of the concavity (up = +) times the trend direction  
 %  is positive, use one approximation for coef0(3), otherwise use the
 %  other.
          if concavity*trend >= 0
             coef0(3) = -2/(3*max(xe) - min(xe));
          else
              if abs(3*min(xe)-max(xe)) > 1.e-4
                 coef0(3) = -2/(3*min(xe) - max(xe));
              else
                 coef0(3) = -3/(4*min(xe) - max(xe));
              end
          end
          coef0(2) = (ve(mid, 1)-coef0(1))/(1+coef0(3)*xe(mid));

          coefs = nlinfit(x_regress,y_regress,@form109,coef0);
          vxval_fit = form109(coefs,xvalues);
          vc_fit = form109(coefs,xc);
          sse0 = sumsqerr109(coefs,x_regress,y_regress);
          p = 3;
          sseci = (1+p/(nex-p)*finv(conf_int,p,nex-p))*sse0;
          
%  Some fraction of the curve fit coefficients are probably the best guess 
%  for starting the iteration that finds the coefficients that bound the 
%  confidence region.
          mult_lower = 0.3;
          mult_upper = 1.1;
          ncoords = size(coefs);
          scaling = ones(1,ncoords);
          [nipl c0lower nipu c0upper xval_l xval_u coords_l coords_u] = ...
             select_iteration_ip(coefs,mult_lower,mult_upper,scaling, ...
             np,xvalues, regression_form, regression_eqn_txt);
          
          [flower,fupper,flower_n,fupper_n,cc_l,cc_u,sse_l,sse_u] = ...
               bounds109(c0lower,c0upper,xvalues, x_exp,y_exp,sseci, ...
               tolcon,tolfun);

          if (nipl == 2 || nipl == 3) && ~any(c0lower(2,:))
             coords_l(2,:) = coords_l(1,:);
             for i=2+nipl:nipl:nipl*np
                 coords_l(i,:) = cc_l(i-nipl,:);
             end
          end
          if (nipu == 2 || nipu == 3) && ~any(c0upper(2,:))
             coords_u(2,:) = coords_u(1,:);
             for i=2+nipu:nipu:nipu*np
                 coords_u(i,:) = cc_u(i-nipu,:);
             end
          end
          
       elseif regression_form == 10
%%  Regression form y = c3 + c2*exp(c1*x)            (form110(coefs,x))
          coef0 = [];
          tolcon = 1.e-6;
          tolfun = 1.e-7;
          regression_eqn = 'y = c_3 + c_2 * exp(c_1*x)';
          regression_eqn_txt = 'y = c3 + c2 * exp(c1*x)';
%  y = c3 bounds the data, either above it or below it.  
%  Use the concavity to estimate c3, then get linear fit coefficients 
%  for the linear form ln(y-c3)=ln(c2) + c1*x
          mid = fix(nex/2);
          concavity = 0.5*(ve(1, 1) + ve(nex, 1)) - ve(mid, 1);
          if concavity >= 0.
             c3 = ve_min - 0.1*(ve_max-ve_min);
             lny = log(y_regress - c3); 
             coef0 = polyfit(x_regress,lny,1);
% Now change the coefficients for the real curve fit:
             coef0(2) = exp(coef0(2));
             coef0(3) = c3;
          else
             c3 = ve_max + 0.1*(ve_max-ve_min);
             lny = log(c3 - y_regress);
             coef0 = polyfit(x_regress,lny,1);
% Now change the coefficients for the real curve fit:
             coef0(2) = exp(-coef0(2));
             coef0(3) = c3;
          end
%  Use the coefficients as the starting point for a non-linear regression:
          coefs = nlinfit(x_regress,y_regress,@form110,coef0);
          vxval_fit = form110(coefs,xvalues);
          vc_fit = form110(coefs,xc);
          sse0 = sumsqerr110(coefs,x_regress,y_regress);
          p = 3;
          sseci = (1+p/(nex-p)*finv(conf_int,p,nex-p))*sse0;

%  Some fraction of the curve fit coefficients are probably the best guess 
%  for starting the iteration that finds the coefficients that bound the 
%  confidence region.
          mult_lower = 0.3;
          mult_upper = 1.1;
          ncoords = size(coefs);
          scaling = ones(1,ncoords);
          [nipl c0lower nipu c0upper xval_l xval_u coords_l coords_u] = ...
             select_iteration_ip(coefs,mult_lower,mult_upper,scaling, ...
             np,xvalues, regression_form, regression_eqn_txt);

          [flower,fupper,flower_n,fupper_n,cc_l,cc_u,sse_l,sse_u] = ...
               bounds110(c0lower,c0upper,xvalues, x_exp,y_exp,sseci, ...
               tolcon,tolfun);
 
          if (nipl == 2 || nipl == 3) && ~any(c0lower(2,:))
             coords_l(2,:) = coords_l(1,:);
             for i=2+nipl:nipl:nipl*np
                 coords_l(i,:) = cc_l(i-nipl,:);
             end
          end
          if (nipu == 2 || nipu == 3) && ~any(c0upper(2,:))
             coords_u(2,:) = coords_u(1,:);
             for i=2+nipu:nipu:nipu*np
                 coords_u(i,:) = cc_u(i-nipu,:);
             end
          end
          
       elseif regression_form == 11
%%  Regression form y = c2 * x^c1                   (form111(coefs,x))
          tolcon = 1.e-6;
          tolfun = 1.e-7;
          regression_eqn = 'y = c_2 * x^c^1';
          regression_eqn_txt = 'y = c2 * x^c1';
%  Start by getting coefficients for the linear form ln(y) = c1*ln(x) + c2
          coef0 = [];
          lny = log(y_regress);
          lnx = log(x_regress);
          coef0 = polyfit(lnx,lny,1);
          coef0(2) = exp(coef0(2));
%  Use the coefficients as the starting point for a non-linear regression:
          coefs = nlinfit(x_regress,y_regress,@form111,coef0);
          vxval_fit = form111(coefs,xvalues);
          vc_fit = form111(coefs,xc);
          sse0 = sumsqerr111(coefs,x_regress,y_regress);
          p = 2;
          sseci = (1+p/(nex-p)*finv(conf_int,p,nex-p))*sse0;
          
%  Some fraction of the curve fit coefficients are probably the best guess 
%  for starting the iteration that finds the coefficients that bound the 
%  confidence region.
          mult_lower = 0.3;
          mult_upper = 1.1;
          ncoords = size(coefs);
          scaling = ones(1,ncoords);
          [nipl c0lower nipu c0upper xval_l xval_u coords_l coords_u] = ...
             select_iteration_ip(coefs,mult_lower,mult_upper,scaling, ...
             np,xvalues, regression_form, regression_eqn_txt);

          [flower,fupper,flower_n,fupper_n,cc_l,cc_u,sse_l,sse_u] = ...
               bounds111(c0lower,c0upper,xvalues, x_exp,y_exp,sseci, ...
               tolcon,tolfun);
 
          if (nipl == 2 || nipl == 3) && ~any(c0lower(2,:))
             coords_l(2,:) = coords_l(1,:);
             for i=2+nipl:nipl:nipl*np
                 coords_l(i,:) = cc_l(i-nipl,:);
             end
          end
          if (nipu == 2 || nipu == 3) && ~any(c0upper(2,:))
             coords_u(2,:) = coords_u(1,:);
             for i=2+nipu:nipu:nipu*np
                 coords_u(i,:) = cc_u(i-nipu,:);
             end
          end

       elseif regression_form == 12
%%  Regression form y = (c1 + x^c3)/(c2 + x^c3)     (form_step1(coefs,x))
          tolcon = 1.e-8;
          tolfun = 1.e-10;
          regression_eqn = 'y = (c_1 + x^c^3)/(c_2 + x^c^3)';
          regression_eqn_txt = 'y = (c1 + x^c3)/(c2 + x^c3)';
%  Start by estimating the coefficients c1, c2, and c3 using a cubic
%  polynomial fit:
          coef0 = polyfit(x_regress,y_regress,3);
%  Find which end of the curve is farthest from y=1 and average the 
%  two most extreme points.  This will estimate c1/c2.
          if (abs(ve_avg(1) - 1.) < abs(ve_avg(nex)-1.))
              yextr = 0.5*(ve_avg(nex-1) + ve_avg(nex));
          else
              yextr = 0.5*(ve_avg(1) + ve_avg(2));
          end
%  Estimate the location of the inflection point. If x=1 is in the 
%  range of the data, use x=1.  
          if x_regress(1) < 1. & x_regress(nex) > 1.
              xinfl = 1.;
          else
              xinfl = 0.5*(x_regress(1) + x_regress(nex));
          end
          yinfl = polyval(coef0,xinfl);
%  The slope of the cubic at the inflection point should approximate
%  the slope of the fit, which is, at least for y=1, 
%       slope=c3*(c2-c1)/(c2+1)^2.
          infl_slope = 3*coef0(1)*xinfl^2 + 2*coef0(2)*xinfl + coef0(3);
          yone = polyval(coef0,1.);
%  Now find the starting approximation for the nonlinear fit 
%  coefficients c1, c2, c3.
          coef0 = [];
%  Use y(1) from the cubic to approximate y(1) = (c1+1)/(c2+1).
%  From the estimates of yextr = c1/c2 and y(1) = (c1+1)/(c2+1) we
%  can estimate c1 and c2.  
          coef0(2) = (1.-yone)/(yone-yextr);
          coef0(1) = yextr*coef0(2);          
          coef0(3) = infl_slope*(coef0(2) + 1.)^2/(coef0(2)-coef0(1));
          
%  Use coef0 as the starting point for a non-linear regression:
          coefs = nlinfit(x_regress,y_regress,@form_step1,coef0);
          ans_coefs = coefs
          vxval_fit = form_step1(coefs,xvalues);
          vc_fit = form_step1(coefs,xc);
          sse0 = sumsqerr_step1(coefs,x_regress,y_regress);
          p = length(coefs);
          sseci = (1+p/(nex-p)*finv(conf_int,p,nex-p))*sse0;

%  Some fraction of the curve fit coefficients are probably the best guess 
%  for starting the iteration that finds the coefficients that bound the 
%  confidence region.
          mult_lower = 0.3;
          mult_upper = 1.1;
          ncoords = size(coefs);
          scaling = ones(1,ncoords);
          [nipl c0lower nipu c0upper xval_l xval_u coords_l coords_u] = ...
             select_iteration_ip(coefs,mult_lower,mult_upper,scaling, ...
             np,xvalues, regression_form, regression_eqn_txt);

          [flower,fupper,flower_n,fupper_n,cc_l,cc_u,sse_l,sse_u] = ...
               bounds_step1(c0lower,c0upper,xvalues, x_exp,y_exp,sseci, ...
               tolcon,tolfun);
 
          if (nipl == 2 || nipl == 3) && ~any(c0lower(2,:))
             coords_l(2,:) = coords_l(1,:);
             for i=2+nipl:nipl:nipl*np
                 coords_l(i,:) = cc_l(i-nipl,:);
             end
          end
          if (nipu == 2 || nipu == 3) && ~any(c0upper(2,:))
             coords_u(2,:) = coords_u(1,:);
             for i=2+nipu:nipu:nipu*np
                 coords_u(i,:) = cc_u(i-nipu,:);
             end
          end
       
       elseif regression_form == 13
%%  Regression form y = c1+c2*(1/(1+exp(c3*(x-c4)))-1/(1+exp(c5*(x-c6))) )
          tolcon = 1.e-8;
          tolfun = 1.e-9;
          regression_eqn = ...
        'y = c_1+c_2*(1/(1+exp(c_3*(x-c_4)))-1/(1+exp(c_5*(x-c_6))))';
          regression_eqn_txt = ...
           'y = c1+c2*(1/(1+exp(c3*(x-c4)))-1/(1+exp(c5*(x-c6))))';

%  Estimate coefficients coef0:
%  These coefficients are the ones described in the User's Manual.
          [coef0] = baseline_step_levels(x_regress,y_regress);
% If the ratio abs(larger/smaller) of coef0(1) and coef0(2) is greater
% than 100, set the smaller to zero.
          if abs(coef0(1)) < 100*abs(coef0(2))
             coef0(1) = 0.;
          elseif abs(coef0(1)) > 100*abs(coef0(2))
             coef0(2) = 0.;     
          end
 % Determine the orders of magnitude of scaling parameters.
          xmagn = get_magnitude(coef0(4),coef0(6))
          ymagn = get_magnitude(coef0(1),coef0(2))
          c3c5magn = get_magnitude(coef0(3),coef0(5))
 
          coef1 = [coef0 xmagn ymagn c3c5magn];
          xxx = form_pulse(coef1,xvalues(10));
          yyy = negform_pulse(coef1,xvalues(10));
 
          coef0(1) = coef0(1)/ymagn;
          coef0(2) = coef0(2)/ymagn;
          coef0(3) = coef0(3)/c3c5magn;
          coef0(4) = coef0(4)/xmagn;
          coef0(5) = coef0(5)/c3c5magn;
          coef0(6) = coef0(6)/xmagn;          
          ans_coef0 = coef0
 %  Use coef0 as the starting point for a non-linear regression:
          coefs = nlinfit(x_regress,y_regress,@form_pulse,coef0)
          
%          vxval_fit = form_square_pulse(coef0,xvalues);
%          vc_fit = form_square_pulse(coef0,xc);
%          sse0 = sumsqerr_square_pulse(coef0,x_regress,y_regress);
          vxval_fit = form_pulse(coefs,xvalues);
          vc_fit = form_pulse(coefs,xc);
          sse0 = sumsqerr_pulse(coefs,x_regress,y_regress);
          p = 6;
          sseci = (1+p/(nex-p)*finv(conf_int,p,nex-p))*sse0;

%  The midpoints (coefs(4) and coefs(6)) and slopes (coefs(3) and coefs(5))
%  might not change significantly, so use the regression coefficients as 
%  iteration starting points. 
          mult_lower = 1.0;
          mult_upper = 1.0;
          ncoords = size(coefs);
          scaling(1) = ymagn;
          scaling(2) = ymagn;
          scaling(3) = c3c5magn;
          scaling(4) = xmagn;
          scaling(5) = c3c5magn;
          scaling(6) = xmagn;       
          [nipl c0lower nipu c0upper xval_l xval_u coords_l coords_u] = ...
             select_iteration_ip(coefs,mult_lower,mult_upper,scaling, ...
             np,xvalues, regression_form, regression_eqn_txt);

 %         [flower,fupper,flower_n,fupper_n,cc_l,cc_u,sse_l,sse_u] = ...
 %              bounds_square_pulse(c0lower,c0upper,xvalues, x_exp,y_exp,sseci, ...
 %              tolcon,tolfun);
           [flower,fupper,flower_n,fupper_n,cc_l,cc_u,sse_l,sse_u] = ...
               bounds_pulse(c0lower,c0upper,xvalues, x_exp,y_exp,sseci, ...
               tolcon,tolfun);

 % Now restore all 6 coefficients:
 %         coefs = coef0;
          coefs(1) = coefs(1)*ymagn;
          coefs(2) = coefs(2)*ymagn;
          coefs(3) = coefs(3)*c3c5magn;
          coefs(4) = coefs(4)*xmagn;
          coefs(5) = coefs(5)*c3c5magn;
          coefs(6) = coefs(6)*xmagn;
          
          if (nipl == 2 || nipl == 3) && ~any(c0lower(2,:))
             coords_l(2,:) = coords_l(1,:);
             for i=2+nipl:nipl:nipl*np
                 coords_l(i,:) = cc_l(i-nipl,:);
             end
          end
          if (nipu == 2 || nipu == 3) && ~any(c0upper(2,:))
             coords_u(2,:) = coords_u(1,:);
             for i=2+nipu:nipu:nipu*np
                 coords_u(i,:) = cc_u(i-nipu,:);
             end
          end
       
       elseif regression_form == 14
%%  Regression form y = c1+c2/(1+((x-c3)/c4)^2)
          tolcon = 1.e-8;
          tolfun = 1.e-9;
          regression_eqn = 'y = c_1 + c_2 / (1 + ((x - c_3)/c_4)^2) ';
          regression_eqn_txt = 'y = c1 + c2 / (1 + ((x - c3)/c4)^2) ';
%  Estimate the base line:
          baseline = mean([ve_avg(1:5)',ve_avg(nex-5:nex)']);
%  Estimate coefficients coef0:
          coef0 = [];
%  If the baseline is closer to the max than to the min, the lorentzian
%  peak is downward rather than upward.
          if (abs(baseline - ve_min) <= abs(baseline - ve_max))
             coef0(1) = ve_min;
             coef0(2) = ve_max - ve_min;
             coef0(3) = mean(x_regress(find(y_regress >= ve_max)));
          else
             coef0(1) = ve_max;
             coef0(2) = ve_min - ve_max;
             coef0(3) = mean(x_regress(find(y_regress <= ve_min))); 
          end
          coef0(4) = 0.02*(x_regress(nex) - x_regress(1));
 %  Use the coefficients as the starting point for a non-linear regression:
          coefs = nlinfit(x_regress,y_regress,@form_lorentzian,coef0);
          vxval_fit = form_lorentzian(coefs,xvalues);
          vc_fit = form_lorentzian(coefs,xc);
          sse0 = sumsqerr_lorentzian(coefs,x_regress,y_regress);
          p = length(coef0);
          sseci = (1+p/(nex-p)*finv(conf_int,p,nex-p))*sse0;
          
%  Some fraction of the curve fit coefficients are probably the best guess 
%  for starting the iteration that finds the coefficients that bound the 
%  confidence region.
          mult_lower = 0.3;
          mult_upper = 1.1;
          ncoords = size(coefs);
          scaling = ones(1,ncoords);
          [nipl c0lower nipu c0upper xval_l xval_u coords_l coords_u] = ...
             select_iteration_ip(coefs,mult_lower,mult_upper,scaling, ...
             np,xvalues, regression_form, regression_eqn_txt);

          [flower,fupper,flower_n,fupper_n,cc_l,cc_u,sse_l,sse_u] = ...
               bounds_lorentzian(c0lower,c0upper,xvalues, x_exp,y_exp,sseci, ...
               tolcon,tolfun);
 
          if (nipl == 2 || nipl == 3) && ~any(c0lower(2,:))
             coords_l(2,:) = coords_l(1,:);
             for i=2+nipl:nipl:nipl*np
                 coords_l(i,:) = cc_l(i-nipl,:);
             end
          end
          if (nipu == 2 || nipu == 3) && ~any(c0upper(2,:))
             coords_u(2,:) = coords_u(1,:);
             for i=2+nipu:nipu:nipu*np
                 coords_u(i,:) = cc_u(i-nipu,:);
             end
          end
          
       elseif regression_form == 15
%%  Regression form y = 1 + c1*(1/(1 + c2 * x^c3) - 1)  (form_shearlayer(coefs,x))
          tolcon = 1.e-8;
          tolfun = 1.e-10;
          regression_eqn = 'y = 1 + c_1*(1/(1 + c_2 * x^c^3) - 1)';
          regression_eqn_txt = 'y = 1 + c1*(1/(1 + c2 * x^c3) - 1)';

%  Start by estimating the coefficients c1, c2, and c3 using a cubic
%  polynomial fit:
          coef0 = polyfit(x_regress,y_regress,3);
%  Find which end of the curve is farthest from y=1 and average the 
%  two most extreme points.  This will estimate c1/c2.
          if (abs(ve_avg(1) - 1.) < abs(ve_avg(nex)-1.))
              yextr = 0.5*(ve_avg(nex-1) + ve_avg(nex));
          else
              yextr = 0.5*(ve_avg(1) + ve_avg(2));
          end
%  Estimate the location of the inflection point. If x=1 is in the 
%  range of the data, use x=1.  
          if x_regress(1) < 1. & x_regress(nex) > 1.
              xinfl = 1.;
          else
              xinfl = 0.5*(x_regress(1) + x_regress(nex));
          end
          yinfl = polyval(coef0,xinfl);
%  The slope of the cubic at the inflection point should approximate
%  the slope of the fit, which is, at least for y=1, 
%       slope=c3*(c2-c1)/(c2+1)^2.
          infl_slope = 3*coef0(1)*xinfl^2 + 2*coef0(2)*xinfl + coef0(3);
          yone = polyval(coef0,1.);
%  Now find the coefficients for case 12:

          coef0 = [];
%  Use y(1) from the cubic to approximate y(1) = (c1+1)/(c2+1).
%  From the estimates of yextr = c1/c2 and y(1) = (c1+1)/(c2+1) we
%  can estimate c1 and c2.  
          coef0(2) = (1.-yone)/(yone-yextr);
          coef0(1) = yextr*coef0(2);          
          coef0(3) = infl_slope*(coef0(2) + 1.)^2/(coef0(2)-coef0(1));
%  Now convert the coefficients to the current equation:
          coef0(1) = coef0(1)/coef0(2) - 1;
          coef0(3) = -coef0(3);
%  coef0(2) stays the same.
          
%  Use coef0 as the starting point for a non-linear regression:
          coefs = nlinfit(x_regress,y_regress,@form_shearlayer,coef0);
          ans_coefs = coefs
          vxval_fit = form_shearlayer(coefs,xvalues);
          vc_fit = form_shearlayer(coefs,xc);
          sse0 = sumsqerr_shearlayer(coefs,x_regress,y_regress);
          p = length(coefs);
          sseci = (1+p/(nex-p)*finv(conf_int,p,nex-p))*sse0;

%  Some fraction of the curve fit coefficients are probably the best guess 
%  for starting the iteration that finds the coefficients that bound the 
%  confidence region.
          mult_lower = 0.3;
          mult_upper = 1.1;
          ncoords = size(coefs);
          scaling = ones(1,ncoords);
          [nipl c0lower nipu c0upper xval_l xval_u coords_l coords_u] = ...
             select_iteration_ip(coefs,mult_lower,mult_upper,scaling, ...
             np,xvalues, regression_form, regression_eqn_txt);

          [flower,fupper,flower_n,fupper_n,cc_l,cc_u,sse_l,sse_u] = ...
               bounds_shearlayer(c0lower,c0upper,xvalues, x_exp,y_exp,sseci, ...
               tolcon,tolfun);
 
          if (nipl == 2 || nipl == 3) && ~any(c0lower(2,:))
             coords_l(2,:) = coords_l(1,:);
             for i=2+nipl:nipl:nipl*np
                 coords_l(i,:) = cc_l(i-nipl,:);
             end
          end
          if (nipu == 2 || nipu == 3) && ~any(c0upper(2,:))
             coords_u(2,:) = coords_u(1,:);
             for i=2+nipu:nipu:nipu*np
                 coords_u(i,:) = cc_u(i-nipu,:);
             end
          end
              
       end
%%  else
%  two-dimensional code goes here
   end

   nz_vx_fit = find(abs(vxval_fit) > nearly_zero);
   any_zero_vx_fit = any(find(abs(vxval_fit) <= nearly_zero));

%  Offer xc interpolation options in next version of the program.

% Generate global metrics
%  The CI may not be symmetric in the regression case, so find + and -.
   ci_del_p = fupper' - vxval_fit;
   ci_del_m = flower' - vxval_fit; 
%------------------------------------------------------------------------
% Open window f4 for printing the metrics 
   f4 = figure('visible','on');
   f4_filename = strcat('globalmetrics_for_rform',...
       num2str(regression_form),'_',cicell{1},'pct.fig');
   tx_savef4 = uicontrol(f4,'units','normalized',...
     'style','text','string',...
     ['This screen will be saved as file: ' f4_filename], ...
     'position',[0.0 0.1 0.80 0.05], 'fontsize',10,'BackgroundColor','w');
   tx_tolcon = uicontrol(f4,'units','normalized',...
      'style','text','string', ['TolCon = ' num2str(tolcon)], ...
      'position',[0.1 0.0 0.20 0.05], 'fontsize',8, ...
      'BackgroundColor','w');
   tx_tolfun = uicontrol(f4,'units','normalized',...
      'style','text','string', ['TolFun = ' num2str(tolfun)], ...
      'position',[0.3 0.0 0.20 0.05], 'fontsize',8, ...
      'BackgroundColor','w');
   hgt = 0.90;
   tx_lbl1 = uicontrol(f4,'units','normalized','style','text',...
     'string','VALIDATION  METRICS', 'position',[0.20 hgt 0.40 0.05], ...
     'fontsize',12,'BackgroundColor','w');
   hgt = hgt - 0.05;

   tx_lbl2 = uicontrol(f4,'units','normalized','style','text','string',...
     ['Validation uses the ' cicell{1} '% confidence interval'], ...    
     'position',[0.0 hgt 0.95 0.05], 'fontsize',10,'BackgroundColor','w');
   hgt = hgt - 0.10;
   

% Compute the average absolute value of the regression.
   avg_abs_regr = mean(abs(vc_fit)); 
   tx_aaa = uicontrol(f4,'units','normalized',...
     'style','text','string',... 
     ['Avg(abs(yregression))            = ' ...
     num2str(avg_abs_regr,4) '  ' v_units],...
     'position',[0.0 hgt 0.50 0.05], 'fontsize',10,'BackgroundColor','w');
   hgt = hgt - 0.05;

%  The remaining metrics are dimensionless
   est_error = vc - vc_fit;            % = f(xc)
   est_error_xval = interp1(xc,est_error,xvalues,interp_method);   % = f(xvalues)
   
   avg_rel_error_metric = sum(abs(est_error))/(ncomp*avg_abs_regr);
   tx_are = uicontrol(f4,'units','normalized',...
     'style','text','string',...
     ['Average relative error metric = ' ...
     num2str(avg_rel_error_metric,4)],...
     'position',[0.0 hgt 0.50 0.05], 'fontsize',10,'BackgroundColor','w');
   hgt = hgt - 0.05;
   
   avg_rel_conf_indicator = 0.5*mean(abs( (fupper(nz_vx_fit)-flower(nz_vx_fit))' ./ ...
         vxval_fit(nz_vx_fit) ));
   tx_rci  = uicontrol(f4,'units','normalized','style','text', ...
         'string',['Average relative confidence indicator = ' ...
         num2str(avg_rel_conf_indicator,4)],... 
         'position',[0.0 hgt 0.55 0.05], 'fontsize',10, ...
         'BackgroundColor','w');
   hgt = hgt - 0.05;
      
%  Evaluate the maximum relative error metric:
   max_rel_error_metric = max(abs(est_error))/avg_abs_regr;
   tx_mre = uicontrol(f4,'units','normalized',...
     'style','text','string',...
     ['Maximum relative error metric = ' ...
     num2str(max_rel_error_metric,4)],... 
     'position',[0.0 hgt 0.50 0.05], 'fontsize',10,'BackgroundColor','w');
   hgt = hgt - 0.05;
   
   ci_for_max_rel_err_metric = 0.5*max(abs( (fupper(nz_vx_fit)-flower(nz_vx_fit))' ./ ...
         vxval_fit(nz_vx_fit) ));
   tx_cimre = uicontrol(f4,'units','normalized', 'style','text', ...
         'string',...
        ['Confidence interval for maximum relative error metric = ' ...
        num2str(ci_for_max_rel_err_metric,4)],... 
        'position',[0.0 hgt 0.70 0.05], 'fontsize',10, ...
        'BackgroundColor','w');
   hgt = hgt - 0.05;  
   
   if appendtimestamp
      uicontrol(f4,'units','normalized', 'style','text', ...
         'string',timestamp, 'position',[0.7 0.01 0.3 0.05], ...
         'fontsize',10, 'BackgroundColor','w');
   end
   saveas(f4,f4_filename);
   
%  Append data to the output file if one has been chosen.
   if (fid > 0)
     fprintf(fid,'\r\n%s\r\n','validation metrics');
     fprintf(fid,'%s    %13.4e    %s \r\n',cicell{1},sseci, ...
         '% confidence interval, sum squared error');
     fprintf(fid,'%12.3e         %s\r\n',avg_abs_regr,'Avg(abs(yregression))');
     fprintf(fid,'%12.3e          %s\r\n',avg_rel_error_metric,'Average relative error metric');
     fprintf(fid,'%12.3e          %s\r\n',avg_rel_conf_indicator, ...
         'Average relative confidence indicator');
     fprintf(fid,'%12.3e          %s\r\n',max_rel_error_metric,'Maximum relative error metric');
     fprintf(fid,'%12.3e          %s\r\n',ci_for_max_rel_err_metric, ...
         'Confidence interval for maximum relative error metric');
%   fprintf(fid,'%s grid, %s interpolation\r\n',interp_grid,interp_method);
     fprintf(fid,'regression: %s\r\n',regression_eqn_txt);
%  The regression analysis does not (yet) use a common grid.

     fprintf(fid,' %4d\r\n',p);
%  Print the regression coefficients, up to 6 per line.
     for i=1:p
        fprintf(fid,'%13.4e',coefs(i));
        if (mod(i,6) == 0)
           fprintf(fid,'\r\n');
        end
     end
     if (mod(p,6) ~= 0)
        fprintf(fid,'\r\n');
     end
     
     fprintf(fid,'\r\n %4d %4d\r\n', 5, nex);
%  Next write the round number grid output:
%  column headings:
     fprintf(fid,'%s','      xval  ');
     if ndims > 1
        fprintf(fid,'%s','      yval  ');
     end    
     if ndims > 2
        fprintf(fid,'%s','      zval  ');
     end
     fprintf(fid,'   fit(xval)');
     fprintf(fid,'    fit+CI  ');
     fprintf(fid,'    fit-CI  ');  
     fprintf(fid,'      +CI   ');
     fprintf(fid,'      -CI   \r\n');  

%  Get the independent variable(s) (up to 3):
%     if ndims == 1
%        xe = exp_data(:,nxecol);
%     else
%        xe = exp_data(:,nxecol(1));
%     end
%     if ndims > 1
%        ye = exp_data(:,nxecol(2));
%     end
%     if ndims > 2
%        ze = exp_data(:,nxecol(3));
%     end
%  Write the experimental data coordinate(s), fit, fupper, flower, and
%  +/-CI.
     for i=1:nex
        fprintf(fid,'%12.3e',xvalues(i));
        if (ndims > 1)
           fprintf(fid,'%12.3e',ye(i));
        end
        if (ndims > 2)
           fprintf(fid,'%12.3e',ze(i));
        end
        fprintf(fid,'%12.3e',vxval_fit(i));
        fprintf(fid,'%12.3e',fupper(i));
        fprintf(fid,'%12.3e',flower(i));
        fprintf(fid,'%12.3e',ci_del_p(i));
        fprintf(fid,'%12.3e',ci_del_m(i));
        fprintf(fid,'\r\n'); 
     end 
     
     fprintf(fid,'\r\n %4d %4d\r\n', 2, ncomp); 
%  Write the computational grid output first:
%  column headings:
     fprintf(fid,'%s','      xc    ');
     if ndims > 1
        fprintf(fid,'%s','      yc    ');
     end    
     if ndims > 2
        fprintf(fid,'%s','      zc    ');
     end
     fprintf(fid,'    vc_fit  ');
     fprintf(fid,'  est error \r\n');
     
%  Get the independent variable(s) (up to 3):
%     ncomp = length(comp_data);
%     if ndims == 1
%        xc = comp_data(:,nxccol);
%     else
%        xc = comp_data(:,nxccol(1));
%     end
%     if ndims > 1
%        yc = comp_data(:,nxccol(2));
%     end
%     if ndims > 2
%        zc = comp_data(:,nxccol(3));
%     end
%  Write the computational data coordinate(s) and fit.  
     for i=1:ncomp
        fprintf(fid,'%12.3e',xc(i));
        if (ndims > 1)
           fprintf(fid,'%12.3e',yc(i));
        end
        if (ndims > 2)
           fprintf(fid,'%12.3e',zc(i));
        end
        fprintf(fid,'%12.3e',vc_fit(i));
        fprintf(fid,'%12.3e',est_error(i));
        fprintf(fid,'\r\n');
     end
     fprintf(fid,'\r\n');
   end

% ---------------------------------------------------------------------
%% PLOT 1 OF 5:
%  Plot the experimental data:
   plot_exp_data(xmin,xmax, xe,ve,vc,e_column_nums,ex_label1, ...
       evar_label1,appendtimestamp,timestamp,timestamp_y_place);
   
%------------------------------------------------------------------------
%% PLOT 2 OF 5:
   vmin = min(min(vc),min(min(ve)));
   vmax = max(max(vc),max(max(ve))); 
   midpoint = fix(nex/2);
   ve_left = mean(ve(1,:));
   ve_mid = mean(ve(midpoint,:));
   ve_right = mean(ve(nex,:));

 
% Open window f6 for plotting experimental data average, computational
% data, and +/- confidence interval.
   f6 = figure('visible','on');
   vmin2 = min(vmin,min(flower));
   vmax2 = max(vmax,max(fupper)); 
   [vstart2,vend2,vtic] = roundbounds(vmin2,vmax2,0.175);
   if (necols == 1)
      legend_matrix = {'experimental data';'computation';...
        ['fit + ' cicell{1} '% confidence interval']; ...
        ['fit - ' cicell{1} '% confidence interval']};
      title (strcat(['Experimental data, computational data, and ' ...
      cicell{1}], '% confidence interval around fit'));

   else
       legend_matrix = {'experimental average';'computation';...
        ['fit + ' cicell{1} '% confidence interval']; ...
        ['fit - ' cicell{1} '% confidence interval']};   
       title (strcat(['Experimental mean, computational data, and ' ...
       cicell{1}], '% confidence interval around fit'));
   end
   plot(xe,ve_avg,'ok',xc,vc,'-b', xvalues,fupper,'- .g', ...
       xvalues,flower,'- .r');
   axis([xstart xend vstart2 vend2]);
   xlabel(ex_label1);
   ylabel(evar_label1);
   if (necols == 1)
      title (strcat(['Experimental data, computational data, and ' ...
      cicell{1}], '% confidence interval around fit'));
   else 
      title (strcat(['Experimental mean, computational data, and ' ...
      cicell{1}], '% confidence interval around fit'));
   end
% h = findobj(gca,'Type','Axes');
   grid on;
   legend_corner = legend_location(ve_left,ve_mid,ve_right);
   legend(legend_matrix,'Location',legend_corner);
   if appendtimestamp
      xtpos = xstart + 0.75*(xend-xstart);
      ytpos = vstart2 + timestamp_y_place*(vend2-vstart2);
      text(xtpos,ytpos,timestamp, 'BackgroundColor','w');
   end
   hold off
   saveas(f6,strcat('comp_and_exp_mean_with_',cicell{1},...
       'pct_ci_rform',num2str(regression_form),'.fig'));

%-----------------------------------------------------------------------
%% PLOT 3 OF 5:
   f7 = figure('visible','on');
   vmin = min(est_error_xval + ci_del_m);
   vmax = max(est_error_xval + ci_del_p);
   [vstart3,vend3,vtic] = roundbounds(vmin,vmax,0.175);
   legend_matrix = {'Estimated computational error';...
       ['+ ' cicell{1} '% confidence interval']; ...
       ['- ' cicell{1} '% confidence interval']};
   plot(xc,est_error,'-k', xvalues,ci_del_p,'- .g', xvalues,ci_del_m,'- .r');
   axis([xstart xend vstart3 vend3]);
   grid on;
   xlabel(ex_label1);
   ylabel(evar_label1);
   title (strcat(['Validation metric result and ', ...
          cicell{1},'% confidence interval']));
   third1 = fix((ncomp+2)/3);
   third2 = fix((2*ncomp+2)/3);
   avg_left = mean(est_error(1:third1));
   avg_mid = mean(est_error(third1:third2));
   avg_right = mean(est_error(third2:ncomp));
   legend_corner = legend_location(avg_left,avg_mid,avg_right);
   legend(legend_matrix,'Location',legend_corner);
   if appendtimestamp
      xtpos = xstart + 0.75*(xend-xstart);
      ytpos = vstart3 + timestamp_y_place*(vend3-vstart3);
      text(xtpos,ytpos,timestamp, 'BackgroundColor','w');
   end
   hold off
   saveas(f7,strcat('est_error_with_',cicell{1}, ...
   'plus_minus_ci_rform',num2str(regression_form),'.fig'));
%------------------------------------------------------------------------
% Open window f8 for plotting the estimated and true error.
%% PLOT 4 OF 5:
   f8 = figure('visible','on');
   vmin = min(est_error_xval + ci_del_m);
   vmax = max(est_error_xval + ci_del_p);
   [vstart4,vend4,vtic] = roundbounds(vmin,vmax,0.175);
   legend_matrix = {'Estimated computational error';...
     ['+',cicell{1},' confidence interval']; ...
     ['-',cicell{1},' confidence interval']};
   plot(xc,est_error,'-k',xvalues,est_error_xval+ci_del_p,'- .g',...
      xvalues,est_error_xval+ci_del_m,'- .r')
   axis([xstart xend vstart4 vend4]);
   xlabel(ex_label1);
   ylabel(['error in ' evar_label1]);
   title ({strcat(['Estimated error and true error in the model with ', ...
     cicell{1},'% confidence interval'])});
   legend_corner = legend_location(avg_left,avg_mid,avg_right);
   legend(legend_matrix,'Location',legend_corner);
   grid on;
   if appendtimestamp
      xtpos = xstart + 0.75*(xend-xstart);
      ytpos = vstart4 + timestamp_y_place*(vend4-vstart4);
      text(xtpos,ytpos,timestamp, 'BackgroundColor','w');
   end
   hold off
   saveas(f8,strcat('est_error_with_',cicell{1}, ...
   'pct_bounds_rform',num2str(regression_form),'.fig'));
     
%------------------------------------------------------------------------
% Open window f10 for plotting regression fit result with 
% confidence interval.
%% PLOT 5 OF 5:
   f10 = figure('visible','on');
   vmin = min([min(vc_fit)  min(flower)  min(min(ve))]);
   vmax = max([max(vc_fit)  max(fupper)  max(max(ve))]);
   [vstart5,vend5,vtic] = roundbounds(vmin,vmax,0.175);
   legend_matrix = {'regression fit';...
          ['fit + ' cicell{1} '% confidence interval']; ...        
          ['fit - ' cicell{1} '% confidence interval']; ...
          'experimental data'}; 
%   legend_matrix = {'regression fit';...
%          ['fit + ' cicell{1} '% CI, fit start']; ...        
%          ['fit + ' cicell{1} '% CI, previous start']; ... 
%          ['fit - ' cicell{1} '% CI, fit start']; ...        
%          ['fit - ' cicell{1} '% CI, previous start']; ... 
%          'experimental data'}; 
   plot(xc,vc_fit,'-k', xvalues,fupper,'-g', xvalues,flower,'-r', ...
       xe,ve(:,1),' ob');
%       plot(xc,vc_fit,'-k', xe,fupper1,'-g', xe,fupper2,'--b', ...
%            xe,flower1,'-r', xe,flower2,'--m', xe,ve(:,1),' ob');
       hold on;
   for i=2:necols
       plot(xe,ve(:,i),' ob');
   end 
   axis([xstart xend vstart5 vend5]);
   title (strcat(['Regression fit and bounds at ', ...
         cicell{1},'% confidence interval']));
   midpoint = (nex+1)/2;    
   avg_left = mean(vc_fit(1:third1));
   avg_mid  = mean(vc_fit(third1:third2));
   avg_right = mean(vc_fit(third2:ncomp));
   legend_corner = legend_location(avg_left,avg_mid,avg_right);
   legend(legend_matrix,'Location',legend_corner);
   h = findobj(gca,'Type','Axes');
   xminmax = get(h,'XLim');
   yminmax = get(h,'YLim');
   dx = xminmax(2) - xminmax(1);
   dy = yminmax(2) - yminmax(1);
   if strcmp(legend_corner,'NorthEast')
       xx = xstart + 0.02*dx;
       yytop = vstart5 + 0.3*dy;
       incr_y = 3;
   elseif strcmp(legend_corner,'NorthWest')
       xx = xstart + 0.6*dx;
       yytop = vstart5 + 0.3*dy;
       incr_y = 2;
   elseif strcmp(legend_corner,'SouthEast')
       xx = xstart + 0.02*dx;
       yytop = vend5;
       incr_y = 3;
   elseif strcmp(legend_corner,'SouthWest')
       xx = xstart + 0.6*dx;
       yytop = vend5;
       incr_y = 2;
   end

   fract = 0.065;
   yy = yytop - 0.05*dy;
   text(xx,yy,regression_eqn,'BackgroundColor','w');
   yy = yy - 0.02*dy;
   for i=1:p
      if p > 2 & i == fix((p+incr_y)/2);
         xx = xx + 0.20*dx;
         yy = yytop - 0.07*dy;
      end
      yy = yy - fract*dy;  
      text(xx,yy,strcat(['c_',num2str(i),'= ',num2str(coefs(i),6)]), ...
               'BackgroundColor','w');
   end
   xlabel(ex_label1);
   ylabel([evar_label1 ', regression fit and bounds']);
   grid('on');
   if appendtimestamp
      xtpos = xstart + 0.75*(xend-xstart);
      ytpos = vstart5 + timestamp_y_place*(vend5-vstart5);
      text(xtpos,ytpos,timestamp, 'BackgroundColor','w');
   end
   hold off;
   saveas(f10,strcat('regression_fit_with_',cicell{1}, ...
   'pct_bounds_rform',num2str(regression_form),'.fig'));
   end
%-----------------------------------------------------------------------
   repeat = figure('visible','on');
   q3='Do you want to process the same data again?';
   labels{1} = 'yes';
   labels{2} = 'no' ;
   answer = chooseonetextbutton(q3,labels, repeat, 0.0, 0.65);
   if (answer == 2)
      analyze_again = false;
   end
   close(repeat);
end
