function chval = legend_location(avg_left,avg_mid,avg_right)
%  Estimate the best plot corner to place the legend based on the (average)
%  value of the left side, mid, and right side of the line(s).

if avg_left < avg_right
   if avg_mid < 0.5*avg_right
      chval = 'NorthWest';
   else
      chval = 'SouthEast';
   end
else
   if avg_mid < 0.5*avg_right
      chval = 'NorthEast';
   else
      chval = 'SouthWest';
   end
end
