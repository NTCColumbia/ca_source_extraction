function [A,C,b,f] = HALS_initialization(Y,K,options)



init_hals_method = 'random';

if ~exist('K', 'var'),  %find K neurons
    K = 30;  
    warning(['number of neurons are not specified, set to be the default value', num2str(K)]);
end

dimY = ndims(Y) - 1;  % dimensionality of imaged data (2d or 3d)
sizY = size(Y);
T = sizY(end);        % # of timesteps
dx = sizY(1:dimY);    % # of voxels in each axis
d = prod(dx);         % total # of voxels  

med = median(Y,ndims(Y));
Y = bsxfun(@minus, Y, med);
if strcmpi(init_hals_method,'random');
    A = rand(d,K);
    Y = reshape(Y,d,T);
    C = max(A\Y,0);
elseif strcmpi(init_hals_method,'cor_im');
    sk = max(round(T/1000),1);
    Cn = correlation_image(Y(:,:,1:sk:T));
    Y = reshape(Y,d,T);
    Cnf = imgaussfilt(Cn,2.25);
    BW = imregionalmax(Cnf);
    C = Y(BW(:),:);
    A = max(Y*pinv(C),0);
    K = sum(BW(:));
end

max_iter_hals_in = 1;%50;
for iter = 1:max_iter_hals_in
    A = HALS_spatial(Y, A, C);
    C = HALS_temporal(Y, A, C);
end

ind_del = find(std(C,0,2)==0); 
A(:, ind_del) = []; 
C(ind_del, :) = []; 

Y = bsxfun(@plus,Y-A*C,med(:));
b = med(:);
for iter = 1:max_iter_hals_in
    f = max(b'*Y/norm(b)^2,0);
    b = max(Y*f'/norm(f)^2,0);
end