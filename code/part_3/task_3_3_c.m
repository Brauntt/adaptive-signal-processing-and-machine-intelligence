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
% learning step sizes
stepAr = 0.1; stepDft = 1;
% LMS leakage
leak = [0, 1e-2, 1e-1, 5e-1];
% number of leaks
nLeaks = length(leak);
% FM signal
fmSignal = exp(1i * 2 * pi / fSample * phaseSeq) + sqrt(variance / 2) * (randn(1, nSamples) + 1i * randn(1, nSamples));
% DFT matrix (row complex phasor as filter input)
dftMat = 1 / nSamples * exp(1i * (1: nSamples)' * 2 * pi / nSamples * (0: nSamples - 1));
%% AR-CLMS
psdArClms = cell(nLeaks, 1);
% delay and group the FM signal
[group] = preprocessing(fmSignal, orderFilter, 1);
for iLeak = 1: nLeaks
    % prediction by CLMS
    [hArClms, ~, ~] = clms(group, fmSignal, stepAr, leak(iLeak));
    for iSample = 1: nSamples
        % frequency spectrum at each instant
        [hFreqArClms, fArClms] = freqz(1, [1; -conj(hArClms(iSample))], nSamples, fSample);
        % store PSD
        psdArClms{iLeak}(:, iSample) = abs(hFreqArClms) .^ 2;
    end
    % remove outliers (50 times larger than median)
    medianPsdArClms = 50 * median(psdArClms{iLeak}, 'all');
    psdArClms{iLeak}(psdArClms{iLeak} > medianPsdArClms) = medianPsdArClms;
end
%% DFT-CLMS
psdDftClms = cell(nLeaks, 1);
for iLeak = 1: nLeaks
    % CLMS: complex phasor (DFT) -> FM signal
    [hFreqDftClms, ~, ~] = clms(dftMat, fmSignal, stepDft, leak(iLeak));
    % store PSD
    psdDftClms{iLeak} = abs(hFreqDftClms) .^ 2;
    % remove outliers (50 times larger than median)
    medianPsdDftClms = 50 * median(psdDftClms{iLeak}, 'all');
    psdDftClms{iLeak}(psdDftClms{iLeak} > medianPsdDftClms) = medianPsdDftClms;
end
%% Result plot
figure;
for iLeak = 1: nLeaks
    % DFT-CLMS
    subplot(nLeaks, 1, iLeak);
    mesh(psdDftClms{iLeak});
    view(2);
    cbar = colorbar;
    cbar.Label.String = 'PSD (dB)';
    grid on; grid minor;
    legend('DFT-CLMS');
    title([sprintf('Time-frequency diagram of FM signal by DFT-CLMS \\mu = '), num2str(stepDft), sprintf(' \\gamma = '), num2str(leak(iLeak))]);
    xlabel('Time (sample)');
    ylabel('Frequency (Hz)');
    ylim([0 1000]);
end
