function scalar = sumsqerr_square_pulse(coefs,xx,yy)
%
%
fit = form_square_pulse(coefs,xx);
errs = fit - yy;
scalar = errs'*errs;