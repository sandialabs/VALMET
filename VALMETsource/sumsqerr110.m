function scalar = sumsqerr110(coefs,xx,yy)
%
%
fit = form110(coefs,xx);
errs = fit - yy;
scalar = errs'*errs;