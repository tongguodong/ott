function [newa,newb] = make_beam_vector(olda,oldb,n,m,Nmax)
% make_beam_vector.m
%
% Convert the n,m,a,b as output by the bsc_* functions to sparse vector
% a and b with standard packing
%
% Usage:
% [a2,b2] = make_beam_vector(a1,b1,n,m);
% [a2,b2] = make_beam_vector(a1,b1,n,m,Nmax);
%
% This file is part of the package Optical tweezers toolbox 1.0
% Copyright 2006 The University of Queensland.
% See README.txt or README.m for license and details.
%
% http://www.physics.uq.edu.au/people/nieminen/software.html

if nargin < 5
    Nmax = max(n);
end

total_orders = combined_index(Nmax,Nmax);
ci = combined_index(n,m);

newa = sparse(ci,1,olda,total_orders,1);
newb = sparse(ci,1,oldb,total_orders,1);

return
