function out = verify_user_strict(audioFile, claimedUser)
% Accept only if (predicted == claimedUser) AND (cosine >= user threshold)

    % --- load config & artifacts ---
    load('config_paths.mat','PROJECT_ROOT');
    M  = load(fullfile(PROJECT_ROOT,'outputs','models','speaker_model.mat'));     % mdl, mu_s, sig_s, featNames
    ED = load(fullfile(PROJECT_ROOT,'outputs','models','enrollment_db.mat'));     % E.(U_id), ALLOWED_USERS, featNames, mu, sg
    TH = load(fullfile(PROJECT_ROOT,'outputs','models','verification_threshold.mat')); % threshold, users, FAR, FRR

    % model + scalers + schema
    if isfield(M,'speakerMdl'), mdl = M.speakerMdl; else, mdl = M.bestModel; end
    mu = M.mu_s; sg = M.sig_s; featNames = string(M.featNames);
    claimedUser = string(claimedUser);

    % --- extract features using your training extractor (same as CSVs) ---
    assert(isfile(audioFile), "Audio not found: %s", audioFile);
    % try the 4-arg signature first (adjust Fs/MFCC if needed)
    nMFCC = sum(startsWith(featNames,"mfcc_")); if nMFCC==0, nMFCC=20; end
    targetFs = 48000;
    try
        T = extractFeatureTable(string(audioFile), claimedUser, targetFs, nMFCC);
    catch
        T = extractFeatureTable(string(audioFile), claimedUser); % fallback
    end

    % align columns
    have = string(T.Properties.VariableNames);
    T = T(:, intersect(have, featNames));             % drop extras
    missing = setdiff(featNames, string(T.Properties.VariableNames));
    for k=1:numel(missing), T.(missing(k)) = 0; end   % add missing as zeros
    T = T(:, featNames);                              % reorder

    % --- normalize + predict ---
    X = T{:,:};
    Z = (X - mu) ./ sg;
    yPred = string(predict(mdl, Z));

    % --- cosine to enrolled template + threshold ---
    % enrollment centroids saved as E.U_<id>
    key = "U_" + claimedUser;
    assert(isfield(ED.E, key), "Claimed user %s not enrolled.", claimedUser);
    templ = ED.E.(key);                 % 1 x D
    cosScore = dot(Z, templ) / (norm(Z)*norm(templ) + 1e-12);

    % find user-specific threshold (from calibration)
    ui = find(string(TH.users)==claimedUser, 1);
    thr = TH.threshold;  % file may be global; if per-user not found, use global
    if ~isempty(ui) && isfield(TH,'thresholds')
        thr = TH.thresholds(ui);
    end

    accept = (yPred == claimedUser) && (cosScore >= thr);

    % --- report ---
    out = struct('claimedUser',claimedUser,'predictedUser',yPred,...
                 'cosine',double(cosScore),'threshold',double(thr),...
                 'accept',logical(accept));

    if accept
        fprintf("✅ ACCESS GRANTED for %s (pred=%s, cosine=%.3f ≥ thr=%.3f)\n", ...
            claimedUser, yPred, cosScore, thr);
    else
        fprintf("⛔ ACCESS DENIED for %s (pred=%s, cosine=%.3f < thr=%.3f)\n", ...
            claimedUser, yPred, cosScore, thr);
    end
end
