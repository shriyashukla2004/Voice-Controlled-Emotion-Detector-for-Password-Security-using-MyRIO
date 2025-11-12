function result = verify_user(audioFile, claimedUser)
% VERIFY_USER  Verify if 'audioFile' belongs to 'claimedUser' using the
% SAME extractor you used for training (extractFeatureTable), whatever its
% signature is. Accepts if predicted label == claimedUser.
%
% Usage:
%   r = verify_user('C:\path\to\9_20_13.wav','13');

    %% 1) Load config + model
    load('config_paths.mat','PROJECT_ROOT');
    modelFile = fullfile(PROJECT_ROOT,'outputs','models','speaker_model.mat');
    assert(isfile(modelFile), "Model not found: %s", modelFile);

    M = load(modelFile);
    % classifier
    if isfield(M,'speakerMdl'), mdl = M.speakerMdl;
    elseif isfield(M,'bestModel'), mdl = M.bestModel;
    else, error('Model file has no classifier (speakerMdl/bestModel).'); end
    % scalers
    if isfield(M,'mu_s'), mu = M.mu_s; else, error('mu_s not found in model.'); end
    if isfield(M,'sig_s'), sg = M.sig_s; else, error('sig_s not found in model.'); end
    % feature schema
    assert(isfield(M,'featNames'),'featNames missing in model file.');
    featNames = string(M.featNames);

    % infer nMFCC from schema (counts of mfcc_*)
    n_mfcc = sum(startsWith(featNames,"mfcc_"));
    % IMPORTANT: match your training extractor’s sample rate
    targetFs = 48000;  % <-- change to 16000 if that’s what you used for CSVs

    %% 2) Extract one row of features using your extractor (robust caller)
    assert(isfile(audioFile),"Audio file not found: %s", audioFile);
    T1 = call_extractor_robust(audioFile, claimedUser, targetFs, n_mfcc);

    % align columns to model schema (add missing as zeros, order to featNames)
    avail = string(T1.Properties.VariableNames);
    % allow the table to include a 'label' column; remove it from features:
    availFeat = avail(~strcmpi(avail,'label'));
    % add missing columns if any
    missing = setdiff(featNames, availFeat);
    for k = 1:numel(missing), T1.(missing(k)) = 0; end
    % keep exactly the model’s features in order
    T1 = T1(:, featNames);

    %% 3) Normalize + predict
    X1 = T1{:,:};
    Z1 = (X1 - mu) ./ sg;
    yPred = string(predict(mdl, Z1));

    %% 4) Decision (classifier-only)
    claimedUser = string(claimedUser);
    accept = (yPred == claimedUser);

    result = struct('claimedUser',claimedUser, ...
                    'predictedUser',yPred, ...
                    'accept',accept);

    if accept
        fprintf("✅ ACCESS GRANTED for %s (pred=%s)\n", claimedUser, yPred);
    else
        fprintf("⛔ ACCESS DENIED for %s (pred=%s)\n", claimedUser, yPred);
    end
end

% ======================= helpers ===========================
function T1 = call_extractor_robust(fullpath, claimedUser, targetFs, n_mfcc)
% Try multiple common signatures of your project's extractFeatureTable

    claimedUser = string(claimedUser);
    [p, base, ext] = fileparts(fullpath);
    fname = [base, ext];

    tried = {};
    lastErr = [];

    % candidate calls to try, in this order
    calls = {
        @() extractFeatureTable(string(fullpath), claimedUser, targetFs, n_mfcc)
        @() extractFeatureTable(string(fullpath), claimedUser, targetFs)
        @() extractFeatureTable(string(fullpath), claimedUser)
        @() extractFeatureTable({string(fullpath)}, {claimedUser}, targetFs, n_mfcc)
        @() extractFeatureTable({string(fullpath)}, {claimedUser}, targetFs)
        @() extractFeatureTable({string(fullpath)}, {claimedUser})
        @() call_in_dir(p, @() extractFeatureTable(string(fname), claimedUser, targetFs, n_mfcc))
        @() call_in_dir(p, @() extractFeatureTable(string(fname), claimedUser, targetFs))
        @() call_in_dir(p, @() extractFeatureTable(string(fname), claimedUser))
        @() call_in_dir(p, @() extractFeatureTable({string(fname)}, {claimedUser}, targetFs, n_mfcc))
        @() call_in_dir(p, @() extractFeatureTable({string(fname)}, {claimedUser}, targetFs))
        @() call_in_dir(p, @() extractFeatureTable({string(fname)}, {claimedUser}))
    };

    for i = 1:numel(calls)
        try
            T1 = calls{i}();
            % basic sanity: must be a table with at least 1 variable
            if istable(T1) && width(T1) >= 1
                return;
            end
        catch ME
            tried{end+1} = func2str(calls{i}); %#ok<AGROW>
            lastErr = ME;
        end
    end

    % If we get here, all attempts failed
    msg = "Could not call extractFeatureTable with any known signature.\nTried calls:\n";
    for i=1:numel(tried), msg = msg + "  - " + tried{i} + "\n"; end
    if ~isempty(lastErr)
        msg = msg + "\nLast error:\n" + lastErr.message + "\n";
    end
    error(msg);
end

function out = call_in_dir(dirpath, fhandle)
% Run a function while temporarily cd-ing into dirpath (helps when
% extractor expects bare filenames or uses relative paths).
    oldpwd = pwd;
    cleanup = onCleanup(@() cd(oldpwd));
    cd(dirpath);
    out = fhandle();
end
