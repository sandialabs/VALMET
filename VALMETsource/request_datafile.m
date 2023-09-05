function [ xx nxcol vv e_column_nums xlabel vlabel  ...
            quitflag] = request_datafile(fileinfo,askforlabel)
%  Request and read a data file described by fileinfo.
%
%  Latest revision:  Feb 28, 2006
%  2/27/06  HJI  Added var_units to the argument list.
%  2/28/06  HJI  Changed inputdata array from cell to numeric.
%  8/03/06  HJI  Added argument askforlabel so that labels will not be 
%                requested after the first data file.
%  8/09/06  HJI  Moved units extraction to main program.  Removed argument
%                var_units from request_datafile.
%  5/03/07  HJI  Put some input requests inside while loops to avoid
%                accepting illegal data.
% 10/01/07  HJI  Commented out the QUIT button, since it is not coded
%                correctly.

quitflag = false;
%  Create a new figure window for the data file request
h_fig = figure('visible','on');

%  Create a QUIT button to allow the program to end early:
%pb_quit = uicontrol('units','normalized',...
%    'style','pushbutton','string','QUIT','fontsize',12, ...
%    'position',[0.88 0.92  0.1 0.06], 'callback',{@call_resume});
%set (pb_quit,'UserData',0);

%  Create a RETRY button to allow the user to try again to enter data.
%pb_retry = uicontrol('units','normalized',...
%    'style','pushbutton','string','RETRY','fontsize',12, ...
%    'position',[0.70 0.92  0.1 0.06], ...
 %   'callback','call_settrue([pb_retry]);');
%set (pb_retry,'UserData',0)

%  Request the name of the file:
rb_excel = 0;
rb_txt = 0;
rb_all = 0;
excel_file = false;
pushbutton = false;
filterindex = 0;
%done = get(pb_quit,'UserData');
done = 0;
fname = [];
pname = [];
% Don't end the file name request until a valid name has been chosen
% or until the QUIT button is selected.
while (filterindex == 0 || isempty(fname)) && (done == 0) 
  tx1 = uicontrol('units','normalized', 'style','text', 'string',...
    ['Are your ' fileinfo ' data in an Excel or a text file?'],...
    'position',[0.0 0.92 0.65 0.05], 'fontsize',10);

  rb_excel = uicontrol( 'units','normalized',...
    'style','radiobutton','string','Excel: .xls',...
    'position',[0.04 0.85  0.15 0.05], 'callback', {@call_resume});

  rb_txt = uicontrol( 'units','normalized',...
    'style','radiobutton','string','text: .txt or .dat',...
    'position',[0.20 0.85 0.20 0.05], 'callback', {@call_resume});

  rb_all = uicontrol( 'units','normalized',...
    'style','radiobutton','string','show all files',...
    'position',[0.40 0.85  0.15 0.05], 'callback', {@call_resume});

% Wait for an answer about the file suffix
   uiwait;
   
% Write a "PLEASE WAIT -- WORKING!" message that will be overwritten when
% the file browser window comes up.
%   uicontrol('units','normalized',...
%    'style','pushbutton','string','PLEASE WAIT -- WORKING!','fontsize',10, ...
%    'position',[0.30 0.65  0.4 0.06]);

   pushbutton = true;
% Bring up a browser window showing files with the chosen suffix:
   if get(rb_excel,'value')
       [fname,pname,filterindex] = uigetfile('*.xls');
       excel_file = true;
   elseif get(rb_txt,'value')
       [fname,pname,filterindex] = uigetfile('*.txt;*.dat');
   elseif get(rb_all,'value')
       [fname,pname,filterindex] = uigetfile('*.*');
   end

%  Clear the file type choices:
   set(rb_excel,'value',0);
   set(rb_txt,'value',0);
   set(rb_all,'value',0);
   
% Was a valid file name selected?  If not, the while loop will keep
% the file-type request active on the window.

% Was the QUIT button selected?
%  if get(pb_quit,'UserData')
%     quitflag = true;
%     return;
%  end
end
%pb_quit_value = get(pb_quit,'value')
%pb_retry_value = get(pb_retry,'value')
%pb_retry_userdata = get(pb_retry,'userdata')

%if done == 0
%  Write the file path and name to the window:
%  tx2 = uicontrol('units','normalized',...
%    'style','text','string',[pname fname],...
%    'position',[0.50 0.85 0.50 0.05],...
%    'fontsize',10);
%end

if pushbutton
%  Disable the selection buttons (ghost the choices):
  set(rb_excel,'enable','off');
  set(rb_txt,'enable','off');
  set(rb_all,'enable','off');
end

% Now request info needed to read the data file
if done == 0
   if excel_file
      [file_type work_sheets] = xlsfinfo([pname,fname]);  
      if strcmp(file_type,'Microsoft Excel Spreadsheet')
%  Excel is available to read the file
         ws_num = 1;
         if (length(work_sheets) > 1)
            question = 'Choose the worksheet that contains the data:';
            ws_num = chooseonetextbutton(question, work_sheets, h_fig,0.,0.8);
         end
         [inputdata textdata raw] = xlsread([pname,fname],ws_num);
         
         [nrows ncols] = size(inputdata);
         [headerlines nvars] = size(textdata);
         [rawrows rawcols] = size(raw);
 
         [textrows textcols] = size(textdata);
%  Display the first line of text data:
         tx4 = uicontrol('units','normalized',...
         'style','text','string',...
         ['Here are the first 8 lines of file ' pname fname ':'],...
         'position',[0.0 0.45 0.90 0.05],...
         'fontsize',10);
         if ~isempty(textdata)
            text_line = textdata{1};
            for k=2:textcols
               text_line = strcat([text_line '   ' textdata{k}]);
            end
            tx5 = uicontrol('units','normalized',...
              'style','text','string',text_line, ...
              'position',[0.0 0.40 0.1*textcols 0.05],...
              'fontsize',10);
         end
%  Display the first 8 rows of numbers 
         for j=1:8
            text_line = num2str(inputdata(j,1));
            for k=2:ncols
            text_line = strcat([text_line '   ' num2str(inputdata(j,k))]);
            end
            tx_n = uicontrol('units','normalized',...
            'style','text','string',text_line, ...
            'position',[0.0 0.40-0.05*j 0.11*ncols 0.05],...
            'fontsize',10);         
         end
      else
             
%  Excel is not available to read the data file
         uicontrol('units','normalized', 'style','text', 'string',...
         'Excel is not available, alternative is not yet coded.  Sorry!',...
         'position',[0.0 0.50 0.70 0.05], 'fontsize',10);
         pause(3);
      end     
   else
% Data is in a text file: 
%  Read the first 8 lines of the file as text and display them
     fid = fopen([pname fname],'r');
     inputlines = textscan(fid,'%s',8,'delimiter','\n');
     fclose(fid);
     tx6 = uicontrol('units','normalized',...
       'style','text','string',...
       ['Here are the first 8 lines of file ' pname fname ':'],...
       'position',[0.0 0.40 0.90 0.05],...
       'fontsize',10);
     tx7 = uicontrol('units','normalized',...
       'style','text','string',inputlines{1}, ...
       'position',[0.0 0.04 0.85 0.35],...
       'fontsize',10);

     headerlines = -1;
     while headerlines < 0
        hlcell = inputdlg('How many header lines precede the data?');
        headerlines = str2num(hlcell{1});
     end
     
     delimcell = inputdlg('What delimiter character separates the numeric data?');
     delim = delimcell{1};
  
     ncols = 0;
     while ncols <= 0
        ncolcell = inputdlg('How many columns (total) are there in the file?');
        ncols = str2num(ncolcell{1});
     end
     format = repmat((' %n')',ncols,1)';
  
%  Read the data file:
     fid = fopen([pname fname],'r');
     if delim == ' '
       cellnumdata = textscan(fid,format,'headerlines',headerlines);
     else
       cellnumdata = textscan(fid,format,'headerlines',headerlines, ...
          'delimiter',delim);
     end
     n_columns = length(cellnumdata);
     n_rows = length(cellnumdata{:,1});
     inputdata = zeros(n_rows,n_columns);
     for i=1:n_columns
        inputdata(:,i) = cellnumdata{:,i};
     end
     fclose(fid);
   end 

% When two dimensional data is available:  Ask for the number of
% independent variables.  Until then, assume 1 dimensional data 
%   ndim = 0;
%   while ndim <= 0
%     ndimcell = inputdlg('How many independent variables (dimensions) are there?');
%     ndim = str2num(ndimcell{1});
%   end
   ndim = 1;
   nxcol = zeros(ndim,1); 
%  Ask for the column number(s) for the independent variable(s):
   if (ndim == 1)
     while nxcol <= 0
       nxcolcell = inputdlg('Which column is the independent variable?');
       nxcol = str2num(nxcolcell{1});
     end   
   else 
     while nxcol(1) <= 0
       nxcolcell = inputdlg('Which column is the first independent variable (x)?');
       nxcol(1) = str2num(nxcolcell{1});
     end
   end
   if (ndim > 1)
      while nxcol(2) <= 0
        nxcolcell = inputdlg('Which column is the second independent variable (y)?');
        nxcol(2) = str2num(nxcolcell{1});
      end
   end
   if (ndim > 2)
      while nxcol(3) <= 0
        nxcolcell = inputdlg('Which column is the third independent variable (z)?');
        nxcol(3) = str2num(nxcolcell{1});
      end
   end
     
%  Request the variable name and units only for the experimental data.
%  They should be the same for the computational data.
%   askforlabel = strcmp(fileinfo,'EXPERIMENTAL');
%  Get the scale factors and variable names for the independent and 
%  dependent variables:
   [xfactor xlabel] = get_scale_factor(0.70,'independent', askforlabel);
   if askforlabel
      [vfactor vlabel] = get_scale_factor(0.60,'measured',askforlabel);
   else
      [vfactor vlabel] = get_scale_factor(0.60,'computed',askforlabel);
   end
end

%  Close the current window
close(h_fig);

sorted_data = sortrows(inputdata,nxcol);
ndims = length(nxcol);
if ndims == 1
   xx = sorted_data(:,nxcol);
else
   xx = sorted_data(:,nxcol(1));
end
nx = length(xx);

%  Request the numbers of the columns of the dependent data:
nevar_cols = 0;
while nevar_cols < 1
   h_choose_cols = figure('visible','on');
   choice_question = ['Mark the column number(s) of ',fileinfo, ...
       ' data (averaged if two or more):'];
   k = 0;
   e_map_buttons = [];
   for i=1:ncols 
     if (i ~= nxcol)
        k = k+1;
        e_d_cells(k) = cellstr(num2str(i,'%3i'));
        e_map_buttons(k) = i;
     end
   end
   [e_button_nums] = choosesometextbuttons(choice_question, e_d_cells, ...
       h_choose_cols, 0., 0.90);
   nevar_cols = length(e_button_nums);
end
%  Save only the columns that contain experimental data:
vv = zeros(nx,nevar_cols);
e_column_nums = e_map_buttons(e_button_nums);
j=0;
for i = e_column_nums
   j=j+1;
   for k=1:nx
      vv(k,j) = sorted_data(k,i);
   end
end
close(h_choose_cols);

% Apply any requested (multiplicative) scale factor:
if xfactor ~= 0
   xx = xfactor*xx;
else
    xfactor = 1.;
end
if vfactor ~= 0
   vv = vfactor*vv;
else
    vfactor = 1.;
end
%  end request_datafile
