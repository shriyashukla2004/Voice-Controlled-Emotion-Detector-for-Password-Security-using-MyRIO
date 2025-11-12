function result = verify_user_minimal(audioFile, claimedUser)
% VERIFY_USER_MINIMAL  Predicts speaker using the SAME extractor as training.
% Decision: accept iff predictedUser == claimedUser.

    % --- Load paths & model ---
    load('config_paths.mat','PROJECT_ROOT');
    modelFile = fullfile(PROJECT_ROOT,'outputs','models','speaker_model.mat');
    assert(isfile(modelFile), "Model not found: %s", modelFile);

    M = load(modelFile);
    if isfield(M,'speakerMdl')
        mdl = M.speakerMdl;
    elseif isfield(M,'bestModel')
        mdl = M.bestModel;
    else
        error('No classifier found in model.');
    end

    if isfield(M,'mu_s'),  mu = M.mu_s;  else, error('mu_s missing');  end
    if isfield(M,'sig_s'), sg = M.sig_s; else, error('sig_s missing'); end
    assert(isfield(M,'featNames'),'featNames missing in model.');
    featNames = string(M.featNames);

    % infer nMFCC from model schema (mfcc_01..mfcc_n)
    nMFCC = sum(startsWith(featNames,"mfcc_"));
    if nMFCC==0
        % fallback to your common setting
        nMFCC = 20;
    end
    targetFs = 48000;  % <- this must match training (change to 16000 if you trained at 16 kHz)

    % --- Check inputs ---
    assert(isfile(audioFile), "Audio not found: %s", audioFile);
    claimedUser = string(claimedUser);

    % --- Call your training extractor (try signatures that need 4 args first) ---
    T1 = [];
    lastErr = [];
    try
        % Preferred: full path, 4 args
        T1 = extractFeatureTable(string(audioFile), claimedUser, targetFs, nMFCC);
    catch ME
        lastErr = ME;
    end
    if isempty(T1)
        try
            % 4 args with cell arrays
            T1 = extractFeatureTable({string(audioFile)}, {claimedUser}, targetFs, nMFCC);
        catch ME
            lastErr = ME;
        end
    end
    if isempty(T1)
        try
            % cd into folder + filename only, 4 args (handles extractors that use relative paths)
            [p,b,e] = fileparts(audioFile); fname = [b,e];
            oldpwd = pwd; cd(p);
            T1 = extractFeatureTable(string(fname), claimedUser, targetFs, nMFCC);
            cd(oldpwd);
        catch ME
            if exist('oldpwd','var'), cd(oldpwd); end
            lastErr = ME;
        end
    end
    if isempty(T1)
        % as a last resort, try 2-arg variants
        try
            T1 = extractFeatureTable(string(audioFile), claimedUser);
        catch
            try
                T1 = extractFeatureTable({string(audioFile)}, {claimedUser});
            catch
                if ~isempty(lastErr)
                    error("Could not call extractFeatureTable with 4 or 2 args. Last error: %s", lastErr.message);
                else
                    error("Could not call extractFeatureTable with 4 or 2 args.");
                end
            end
        end
    end
    if ~istable(T1)
        error('Extractor did not return a table.');
    end

    % --- Align columns to the model schema (critical) ---
    have = string(T1.Properties.VariableNames);
    haveFeat = have(~strcmpi(have,'label'));   % drop 'label' from features if present
    missing = setdiff(featNames, haveFeat);    % add any missing cols as zeros
    for k = 1:numel(missing)
        T1.(missing(k)) = 0;
    end
    % keep exactly model columns in order
    T1 = T1(:, featNames);

    % --- Normalize + predict ---
    X1 = T1{:,:};
    Z1 = (X1 - mu) ./ sg;
    yPred = string(predict(mdl, Z1));

    % --- Decision + print ---
    accept = strcmp(yPred, claimedUser);
    result = struct('claimedUser', claimedUser, ...
                    'predictedUser', yPred, ...
                    'accept', accept);

    if accept
        fprintf("✅ ACCESS GRANTED for %s (pred=%s)\n", claimedUser, yPred);
    else
        fprintf("⛔ ACCESS DENIED for %s (pred=%s)\n", claimedUser, yPred);
    end
end
