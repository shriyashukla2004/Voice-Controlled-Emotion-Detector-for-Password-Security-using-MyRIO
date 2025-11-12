clear; clc; load('config_paths.mat');

featDir = fullfile(PROJECT_ROOT,'outputs','features');
Tte = readtable(fullfile(featDir,'features_test_speaker.csv'));

S  = load(fullfile(PROJECT_ROOT,'outputs','models','speaker_model.mat'));
ED = load(fullfile(PROJECT_ROOT,'outputs','models','enrollment_db.mat'));

featNames = ED.featNames;
mu = ED.mu; sg = ED.sg;

Xte = Tte{:,featNames};
Yte = string(Tte.label);
Zte = (Xte - mu) ./ sg;

% Cosine to each enrolled template
enrolled = ED.ALLOWED_USERS;
K = numel(enrolled);
templates = zeros(K, numel(featNames));
for k = 1:K
    templates(k,:) = ED.E.(sprintf('U_%s', enrolled(k)));
end

cos = @(a,b) sum(a.*b,2) ./ (vecnorm(a,2,2).*vecnorm(b,2,2)+1e-12);

% Build scores: genuine vs impostor
gScores = []; iScores = [];
for k = 1:K
    maskG = Yte == enrolled(k);
    if any(maskG)
        gScores = [gScores; cos(Zte(maskG,:), templates(k,:))]; %#ok<AGROW>
    end
    maskI = Yte ~= enrolled(k);
    if any(maskI)
        % sample a manageable impostor set
        r = randperm(sum(maskI), min(2000, sum(maskI)));
        iScores = [iScores; cos(Zte(maskI,:), templates(k,:));]; %#ok<AGROW>
    end
end

% Sweep thresholds
th = linspace(min([gScores;iScores])-1e-6, max([gScores;iScores])+1e-6, 400);
FAR = zeros(size(th)); FRR = zeros(size(th));
for t = 1:numel(th)
    FAR(t) = mean(iScores >= th(t));  % impostor accepted
    FRR(t) = mean(gScores <  th(t));  % genuine rejected
end

% Choose threshold by target FAR (e.g., 1%)
targetFAR = 0.01;
[~,idx] = min(abs(FAR - targetFAR));
thr = th(idx);

figure('Color','w'); plot(FAR, FRR, '-'); grid on;
xlabel('FAR'); ylabel('FRR'); title('DET (FAR vs FRR)');
hold on; plot(FAR(idx), FRR(idx), 'o'); text(FAR(idx), FRR(idx), sprintf('  thr=%.3f', thr));

fprintf('Chosen threshold thr=%.3f | FAR≈%.3f | FRR≈%.3f (K=%d users)\n', thr, FAR(idx), FRR(idx), K);

% Save for runtime
cal = struct('threshold',thr,'FAR',FAR(idx),'FRR',FRR(idx),'users',enrolled);
save(fullfile(PROJECT_ROOT,'outputs','models','verification_threshold.mat'), '-struct','cal');
fprintf('✅ Saved threshold file.\n');
