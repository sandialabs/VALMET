% Read multiple data files, store results in cell arrays
%

%global h_rb;
clear all;

moredata = true;
filecount = 0;
while moredata
   filecount = filecount + 1;
%  Request the experimental data:  exp_data will be a numeric 2-d array.
   [xe nxecol ve e_column_nums exlabel evar_label quitflag ] = ...
              request_datafile('EXPERIMENTAL', filecount == 1);
   necols = length(e_column_nums);
   nex = length(xe);
   if filecount == 1
      ex_label1 = ex_label;
      evar_label1 = evar_label;
   end
   intro = figure('visible','on');
   xcell{filecount} = xe;
   vecell{filecount} = ve;
   ecolnumscell{filecount} = e_column_nums;


   q1='Do you want to read another data file?';
   labels{1} = 'yes';
   labels{2} = 'no' ;
   answer = chooseonetextbutton(q1,labels, intro, 0.0, 0.50);
   moredata = (answer == 1);
     
   if ~moredata && filecount > 1
      [xe_grid] =  exp_gridchoice(xcell,x_units);    
   end
   close (intro);
end

% Retrieve the independent-variable units if in parentheses
   x_units = ' ';
   [lpar0 lpar1] = regexp(exlabel,'(');
   [rpar0 rpar1] = regexp(exlabel,')');
   if (lpar1 > 0) & (rpar1 > 0)
      textchars = exlabel';
      x_units = textchars(lpar1:rpar1)';
   end
% Retrieve the dependent-variable units if in parentheses
   v_units = ' ';
   [lpar0 lpar1] = regexp(evar_label,'(');
   [rpar0 rpar1] = regexp(evar_label,')');
   if (lpar1 > 0) & (rpar1 > 0)
      textchars = evar_label';
      v_units = textchars(lpar1:rpar1)';
   end