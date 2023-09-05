function plot_exp_data(xmin,xmax,xe,ve,vc,e_column_nums,exlabel, ...
    evar_label, appendtimestamp,timestamp,timestamp_y_place)
%  Plot the experimental data

% Open window f_pl_exp for plotting experimental data.
   f_pl_exp = figure('visible','on');
   linestyle = ['o','s','d','.','x','*','p','h','^','v','<','>'];
%   xmin = xstart;
%   xmax = xend;
   [xstart,xend,xtic] = roundbounds(xmin,xmax,0.125);
   vmin = min(min(vc),min(min(ve)));
   vmax = max(max(vc),max(max(ve))); 
   [vstart1,vend1,vtic] = roundbounds(vmin,vmax,0.175);   
   box on;
   hold on;
   [nex  nevar_cols] = size(ve);
   for i=1:nevar_cols
      plot(xe,ve(:,i),linestyle(i));
      legend_matrix(i,:) = {strcat(['column ' num2str(e_column_nums(i))])};
   end
   axis([xstart xend vstart1 vend1]);   
   xlabel(exlabel)
   ylabel(evar_label)
   title ('Experimental measurements');
   grid on;
   midpoint = fix(nex/2);
   ve_left = mean(ve(1,:));
   ve_mid = mean(ve(midpoint,:));
   ve_right = mean(ve(nex,:));
   legend_corner = legend_location(ve_left,ve_mid,ve_right);
   legend(legend_matrix,'Location',legend_corner);
   if appendtimestamp
      xtpos = xstart + 0.75*(xend-xstart);
      ytpos = vstart1 + timestamp_y_place*(vend1-vstart1);
      text(xtpos,ytpos,timestamp, 'BackgroundColor','w');
   end
   hold off;
   saveas(f_pl_exp,'experimental_data.fig');
