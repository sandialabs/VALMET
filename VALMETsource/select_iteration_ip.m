function [nipl c0lower nipu c0upper xval_l xval_u coords_l coords_u] = ...
   select_iteration_ip(coefs,mult_lower,mult_upper,scaling, np,xvalues, ...
   regression_form, regression_eqn_txt)
%  Generate starting points for the iterations on the lower and upper 
%  confidence interval bounds.

ncoords = length(coefs);
iy = [0 0 0 1 1 1 2 2 2];

%  Generate 2 lower and upper iteration starting points.  When the second 
%  starting point is all zeros, the bounds routines use the answer from
%  the previous iteration.
nipl = 2;
c0lower(1,:) = mult_lower*coefs(1,:);
c0lower(2,:) = zeros(1,ncoords);
ip_lower = c0lower(1,:);
nipu = 2;
c0upper(1,:) = mult_upper*coefs(1,:);
c0upper(2,:) = zeros(1,ncoords);
ip_upper = c0upper(1,:);

% Ask the user if he wants to change the lower or upper starting point:
w1 = figure('visible','on');
uicontrol(w1,'units','normalized', 'style','text','string',...
    'Each lower and upper bound iteration has two starting points: ', ...
    'position',[0.0 0.90 0.80 0.05], 'fontsize',10, 'BackgroundColor','w');
uicontrol(w1,'units','normalized', 'style','text','string',...
    ['lower: ' num2str(mult_lower) ' times the regression coefficients and '], ...
    'position',[0.0 0.85 0.80 0.05], 'fontsize',10, 'BackgroundColor','w');
uicontrol(w1,'units','normalized', 'style','text','string',...
    '         the answer from the previous iteration,', ...
    'position',[0.0 0.80 0.80 0.05], 'fontsize',10, 'BackgroundColor','w');
 uicontrol(w1,'units','normalized', 'style','text','string',...
    ['upper: ' num2str(mult_upper) ' times the regression coefficients and '], ...
    'position',[0.0 0.75 0.80 0.05], 'fontsize',10, 'BackgroundColor','w');
uicontrol(w1,'units','normalized', 'style','text','string',...
    '         the answer from the previous iteration.', ...
    'position',[0.0 0.70 0.80 0.05], 'fontsize',10, 'BackgroundColor','w');   

nbuttons = 0;
while nbuttons < 1
   choice_question = 'Do you want to change the starting point(s)? ';
   button_names = {'change lower bound initial coordinates'; ...
                   'change upper bound initial coordinates'; ...
                   'no                                 '};
   [button_nums] = choosesometextbuttons(choice_question, button_names, ...
       w1, 0., 0.60);
   nbuttons = length(button_nums);
end
%pause(2);
close(w1);
for i=1:nbuttons
   if (button_nums(i) == 1)
       w2 = figure('visible','on');
%  Show regression equation and lower initial-point coordinates:
       uicontrol(w2,'units','normalized', 'style','text','string',...
          regression_eqn_txt, 'position',[0.0 0.90 0.80 0.05], ...
          'fontsize',10, 'BackgroundColor','w');
       uicontrol(w2,'units','normalized', 'style','text','string',...
          'Lower bound iteration initial values: ', 'position',...
          [0.0 0.85 0.40 0.05], 'fontsize',10, 'BackgroundColor','w');
       for j=1:ncoords
           x = mod(j-1,3)/3.;
           y = 0.8 - 0.06*iy(j);
           uicontrol(w2,'units','normalized', 'style','text','string',...
             [' c',num2str(j),' = ',num2str(c0lower(1,j).*scaling(j),7)], ...
             'position', [x y 0.30 0.04], 'fontsize',10, 'BackgroundColor','w');   
       end
       c0lower(1,:) = update_ip(ip_lower,scaling);
       close(w2);
   elseif (button_nums(i) == 2)
       w3 = figure('visible','on');
%  Show regression equation and lower initial-point coordinates:
       uicontrol(w3,'units','normalized', 'style','text','string',...
          regression_eqn_txt, 'position',[0.0 0.90 0.80 0.05], ...
          'fontsize',10, 'BackgroundColor','w');     
       uicontrol(w3,'units','normalized', 'style','text','string',...
          'Upper bound iteration initial values: ', 'position',...
          [0.0 0.85 0.40 0.05], 'fontsize',10, 'BackgroundColor','w');
       for j=1:ncoords
           x = mod(j-1,3)/3.;
           y = 0.8 - 0.06*iy(j);
           uicontrol(w3,'units','normalized', 'style','text','string',...
             [' c',num2str(j),' = ',num2str(c0upper(1,j).*scaling(j),7)], ...
             'position', [x y 0.30 0.04], 'fontsize',10, 'BackgroundColor','w');   
       end     
       c0upper(1,:) = update_ip(ip_upper,scaling);
       close(w3)
    end          
end
    
%  For debug printing purposes, generate arrays of x values and the 
%  iteration starting coordinates:
xval_l = [];
xval_u = [];
for i=1:np
   xval_l = [xval_l; repmat(xvalues(i),1,nipl)'];
   xval_u = [xval_u; repmat(xvalues(i),1,nipu)'];
end
coords_l = [];
coords_u = [];
for i=1:np
   coords_l = [coords_l; c0lower];
   coords_u = [coords_u; c0upper];
end
runtime_estimate(np,regression_form);          