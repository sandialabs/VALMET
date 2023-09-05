function magn = get_magnitude(value1,value2)
% Find the magnitude of the larger of abs(value1) and abs(value2)
         
if value1 == 0 && value2 == 0
    magn = 1;
else
   if abs(value1) < abs(value2)
      if abs(value2) >= 1
         magn = 10^(fix(log10(abs(value2)) + 0.22));
      else
         magn = 10^(fix(log10(abs(value2)) - 0.78));
      end
   else
      if abs(value1) >= 1
          magn = 10^(fix(log10(abs(value1)) + 0.22));
      else
          magn = 10^(fix(log10(abs(value1)) - 0.78));
      end
   end
end