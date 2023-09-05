function cval = date_and_time
%  Generate date and time string
   ymdhms = clock;
   cval = strcat([date '    ' num2str(ymdhms(4),'%2i') ':' ...
    num2str(ymdhms(5),'%2.2i')]);