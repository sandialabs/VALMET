function scalar = sumsqerr109(coefs,xx,yy)
%
%
fit = form109(coefs,xx);
errs = fit - yy;
scalar = errs'*errs;