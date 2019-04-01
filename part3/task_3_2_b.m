clear; close all; init;
%% Initialisation
% normalised sampling frequency
fSample = 1500;
% length of signal
nSamples = 1500;
% variance of white noise
variance = 0.05;
% number of segmentations
nSegs = 3;
% length of segmentations
lengthSeg = 500;
% function to determine FM frequency
freqFunc = @(n) ((1 <= n) & (n <= 500)) .* 100 + ((501 <= n) & (n <= 1000)) .* (100 + (n - 500) / 2) + ((1001 <= n) & (n <= 1500)) .* (100 + ((n - 1000) / 25) .^ 2);
% frequency sequence
freqSeq = freqFunc(1: nSamples);
% phase sequence
phaseSeq = cumsum(freqSeq);
% filter order (length)
orderFilter = 1;
% learning step size
step = [1e-1, 1e-2, 1e-3];
% number of step size
nSteps = length(step);
% LMS leakage
leak = 0;
% FM signal
fmSignal = exp(1i * 2 * pi / fSample * phaseSeq) + sqrt(variance / 2) * (randn(1, nSamples) + 1i * randn(1, nSamples));
% number of evaluation points
nPoints = 1024;
%% CLMS and frequency analysis
% psdClms = zeros(nSteps, nPoints, nSamples);
psdClms = cell(nSteps, 1);
% delay and group the FM signal
[group] = preprocessing(fmSignal, orderFilter, 1);
for iStep = 1: nSteps
    % prediction by CLMS
    [hClms, ~, ~] = clms(group, fmSignal, step(iStep), leak);
    for iSample = 1: nSamples
        % frequency spectrum at each instant
        [hFreqClms, fClms] = freqz(1, [1; -conj(hClms(iSample))], nPoints, fSample);
        % store PSD
        psdClms{iStep}(:, iSample) = abs(hFreqClms) .^ 2;
    end
    % remove outliers (50 times larger than median)
    medianPsdClms = 50 * median(psdClms{iStep}, 'all');
    psdClms{iStep}(psdClms{iStep} > medianPsdClms) = medianPsdClms;
end
%% Result plot
figure;
for iStep = 1: nSteps
    subplot(nSteps, 1, iStep);
    mesh(psdClms{iStep});
    view(2);
    cbar = colorbar;
    cbar.Label.String = 'PSD (dB)';
    grid on; grid minor;
    legend('AR (1)');
    title(['Time-frequency diagram of FM signal by CLMS of step ', num2str(step(iStep))]);
    xlabel('Time (sample)');
    ylabel('Frequency (Hz)');
end
