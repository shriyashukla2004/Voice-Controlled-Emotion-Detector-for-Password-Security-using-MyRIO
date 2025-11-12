function T = extractFeatureTable(fileList, labelList, targetFs, nMFCC)
% Portable feature extractor: MFCC-like (custom), deltas, and spectral stats
% Requires only base MATLAB. Safe for very short clips.

N = numel(fileList);
featDim = 3*nMFCC + 7;                 % [mfcc, dmfcc, ddmfcc, 4 scalars + 3 spectral stats = 3*n + 7]
feat = zeros(N, featDim);

% analysis params
winDur = 0.025; hopDur = 0.010;
win  = max(256, round(winDur*targetFs));
hop  = max(128, round(hopDur*targetFs));
fftL = 2^nextpow2(win);
nMels = max(26, nMFCC+8);              % mel bands (>= nMFCC)

% precompute mel filterbank & DCT
[melFB, ~] = local_mel_filterbank(nMels, fftL, targetFs);     % size: nMels x (fftL/2+1)
D = dct(eye(nMels));                 % DCT matrix
D = D(2:nMFCC+1,:);                  % drop c0

for i = 1:N
    try
        [x, fs] = audioread(fileList(i));
        if isempty(x), error("empty audio"); end
        if size(x,2) > 1, x = mean(x,2); end
        if fs ~= targetFs, x = resample(x, targetFs, fs); end
        x = x ./ max(1e-9, max(abs(x)));

        % pad ultra short to get >= 2 frames
        minLen = max(win + hop, 3*hop + 1);
        if numel(x) < minLen
            x = [x; zeros(minLen-numel(x),1)];
        end

        % frame segmentation
        idx = 1:hop:(numel(x)-win+1);
        X = buffer(x(idx(1):idx(end)+win-1), win, win-hop, 'nodelay'); %#ok<*NBRAK>
        X = X .* hann(win,'periodic');

        % STFT Magnitude
        S = abs(fft(X, fftL, 1)).^2;                     % power spectrum (fftL x T)
        S = S(1:fftL/2+1, :);                            % keep positive freqs only

        % log-mel energies per frame
        E = log(max(1e-12, melFB * S));                  % (nMels x T)

        % MFCC-like via DCT
        C = D * E;                                       % (nMFCC x T)

        % deltas (simple first-order)
        dC  = [C(:,1),  C(:,2:end)  - C(:,1:end-1)];
        ddC = [dC(:,1), dC(:,2:end) - dC(:,1:end-1)];

        % time pooling (mean)
        mfcc_mu   = mean(C ,2).';
        dmfcc_mu  = mean(dC,2).';
        ddmfcc_mu = mean(ddC,2).';

        % scalar features
        r   = sqrt(mean(x.^2));
        z   = local_zcr(x);
        dur = numel(x)/targetFs;

        % spectral stats on avg spectrum
        Sp = mean(S,2); Sp = Sp / max(1e-12, sum(Sp));
        freqs = linspace(0, targetFs/2, numel(Sp)).';
        specCent   = sum(freqs .* Sp);
        specSpread = sqrt(sum(((freqs - specCent).^2) .* Sp));
        % flatness as exp(mean(log(Sp)))/mean(Sp)
        specFlat   = exp(mean(log(max(1e-12,Sp)))) / mean(Sp);
        % 85% rolloff
        cSp = cumsum(Sp); specRoll = freqs(find(cSp >= 0.85*cSp(end),1,'first'));

        vec = [mfcc_mu, dmfcc_mu, ddmfcc_mu, r, z, dur, specCent, specSpread, specFlat, specRoll];

        % ensure correct length
        if numel(vec) < featDim, vec(end+1:featDim) = 0; end
        if numel(vec) > featDim, vec = vec(1:featDim);  end

        feat(i,:) = vec;

    catch ME
        % Fill with small noise (not all-zeros) to avoid model collapse; keep label
        warning("Feature fail: %s | %s", fileList(i), ME.message);
        feat(i,:) = 1e-4*randn(1,featDim);
    end
end

% names + table
names = [compose("mfcc_%02d",1:nMFCC), compose("dmfcc_%02d",1:nMFCC), ...
         compose("ddmfcc_%02d",1:nMFCC), "rms","zcr","duration_s","spec_cent","spec_spread","spec_flat","spec_rolloff"];
T = array2table(feat, 'VariableNames', names);
T.label = string(labelList(:));
end

% --------------------- helpers (toolbox-free) ---------------------

function z = local_zcr(x)
% zero-crossing rate (~ crossings per sample), averaged
    xs = sign(x);
    z = mean(abs(diff(xs))>0)/2;
end

function [H, melHz] = local_mel_filterbank(nMels, NFFT, fs)
% triangular mel filter bank, returns H (nMels x (NFFT/2+1))
    fmin = 0; fmax = fs/2;
    % Hz->mel and mel->Hz
    hz2mel = @(f) 2595*log10(1+f/700);
    mel2hz = @(m) 700*(10.^(m/2595)-1);

    mels = linspace(hz2mel(fmin), hz2mel(fmax), nMels+2);
    melHz = mel2hz(mels);
    bins = floor((NFFT+1) * melHz / fs);

    H = zeros(nMels, NFFT/2+1);
    for m = 1:nMels
        b0 = bins(m); b1 = bins(m+1); b2 = bins(m+2);
        b0 = max(b0,1); b1 = max(b1,1); b2 = min(b2, NFFT/2+1);
        if b1<=b0 || b2<=b1, continue; end
        % rising slope
        H(m, b0:b1) = ( (b0:b1) - b0 ) / max(1, (b1 - b0));
        % falling slope
        H(m, b1:b2) = ( b2 - (b1:b2) ) / max(1, (b2 - b1));
    end
    % Normalize area so bands comparable
    H = H ./ max(1e-12, sum(H,2));
end
