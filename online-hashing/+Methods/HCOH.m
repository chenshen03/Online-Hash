classdef HCOH
% Training routine for AdaptHash method
%
% INPUTS
% 	Xtrain - (float) n x d matrix where n is number of points 
%       	         and d is the dimensionality 
%
% 	Ytrain - (int)   n x l matrix containing labels, for unsupervised datasets
%
% NOTES
%       Adapted from original AdaptHash implementation
% 	W is d x b where d is the dimensionality 
%       b is the bit length
%
% 	Data arrives in pairs. If number_iterations is 1000, then 
% 	2000 points will be processed

properties
    stepsize
    hadamard
    batchSize
    lambda
    h
    hbit
    train_label
end

methods
    function [W, R, obj] = init(obj, R, X, Y, opts)

        obj.stepsize       = opts.stepsize;
        obj.hbit        = opts.hbit;
        obj.batchSize   = opts.batchSize;
        obj.lambda = opts.lambda;
        
        h = hadamard(obj.hbit);
        obj.h = h(randperm(obj.hbit), :);
        cnum = length(unique(Y));
        % disp(size(obj.h))
        
        % LSH init
        [n, d] = size(X);
        W = randn(d, opts.nbits);
        W = W ./ repmat(diag(sqrt(W'*W))',d,1);
        
        lshW = randn(obj.hbit, opts.nbits); 
        lshW = lshW ./ repmat(diag(sqrt(W'*W))', obj.hbit, 1);
        lshW = orth(obj.hbit) * lshW;
        if obj.hbit ~= opts.nbits
            obj.h = single(h * lshW > 0);
            obj.h(obj.h <= 0) = -1;
        end
        obj.train_label = obj.h(1:cnum,:);
        % lshW = lshW * orth(opts.nbits);
        
    end % init


    function [W, sampleIdx] = train1batch(obj, W, R, X, Y, I, t, opts)
        ind = (t-1)*opts.batchSize + (1:opts.batchSize);
        sampleIdx = I(ind);
        % sampleIdx = t:(t+obj.batchSize-1);
        Xsample = X(sampleIdx, :);
        Ysample = Y(sampleIdx);
        
        target = obj.train_label(Ysample, :);
        
        F = tanh(Xsample * W);
        derivative = obj.stepsize * Xsample' * [(F-target).*(1-F.*F)] + obj.lambda*W;
        W = W - derivative / obj.batchSize;

    end % train1batch


    function H = encode(obj, W, X, isTest)
        H = (X * W) > 0;
    end

    function P = get_params(obj)
        P = [];
    end

end % methods

end % classdef