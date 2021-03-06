function [group] = preprocessing(signal, order, delay)
% Function:
%   - return the delayed samples (previous values) used in AR prediction
%
% InputArg(s):
%   - signal: signal to process
%   - order: order of ARMA model (i.e. duration of memory)
%   - delay: delay in samples
%
% OutputArg(s):
%   - group: previous samples to predict the current signal value
%
% Comments:
%   - zero-padding depends on lag and delay
%
% Author & Date: Yang (i@snowztail.com) - 26 Mar 19

nSamples = length(signal);
group = zeros(order, nSamples);

for iOrder = 1: order
    % grouped samples to approximate the value at certain instant
    group(iOrder, :) = [zeros(1, iOrder + delay - 1), signal(1: nSamples - (iOrder + delay - 1))];
end
end
